"""Firebase ID token verification and user provisioning."""
import asyncio
import logging
import secrets
from typing import Any

import bcrypt
from firebase_admin import auth as firebase_auth
from firebase_admin.exceptions import FirebaseError
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.core.firebase import ensure_firebase_initialized
from app.models import UserStatus
from app.repositories.user_repository import UserRepository
from app.schemas.auth import TokenResponse
from app.services import jwt_service

logger = logging.getLogger(__name__)


def _firebase_only_password_hash() -> str:
    """Unused for login; satisfies NOT NULL hashed_password for Firebase users."""
    raw = f"firebase:{secrets.token_urlsafe(32)}".encode("utf-8")
    return bcrypt.hashpw(raw, bcrypt.gensalt()).decode("utf-8")


def _verify_firebase_token_sync(id_token: str) -> dict[str, Any]:
    try:
        ensure_firebase_initialized()
    except FileNotFoundError as e:
        logger.error(
            "Firebase Admin credentials missing at %s",
            settings.FIREBASE_CREDENTIALS_PATH,
        )
        raise AppException(
            503,
            "Server configuration error: Firebase credentials file not found",
        ) from e
    return firebase_auth.verify_id_token(id_token)


def _ensure_login_allowed(account_status: str | None) -> None:
    if account_status == UserStatus.suspended.value:
        raise AppException(403, "Account is suspended")
    if account_status == UserStatus.deleted.value:
        raise AppException(403, "Account is no longer available")


def _display_name_from_token(decoded: dict[str, Any], email: str) -> str:
    name = decoded.get("name")
    if isinstance(name, str) and name.strip():
        return name.strip()
    if email and "@" in email:
        return email.split("@")[0]
    return "User"


def _truncate(value: str, max_len: int) -> str:
    if len(value) <= max_len:
        return value
    return value[:max_len]


class AuthService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._users = UserRepository()

    async def login_with_firebase_id_token(self, id_token: str) -> TokenResponse:
        try:
            decoded = await asyncio.to_thread(_verify_firebase_token_sync, id_token)
        except AppException:
            raise
        except ValueError as e:
            logger.info("Invalid Firebase ID token: %s", e)
            raise AppException(401, "Invalid or malformed token") from e
        except FirebaseError as e:
            logger.info("Firebase token verification failed: %s", e)
            raise AppException(401, "Invalid or expired Firebase token") from e

        firebase_uid = decoded.get("uid") or decoded.get("sub")
        if not firebase_uid:
            raise AppException(401, "Invalid token: missing subject")

        email = decoded.get("email")
        if not email or not isinstance(email, str):
            raise AppException(400, "Email is required from Firebase token")

        email = _truncate(email.strip().lower(), 255)
        picture = decoded.get("picture")
        profile_image_url = picture if isinstance(picture, str) else None
        if profile_image_url:
            profile_image_url = _truncate(profile_image_url, 500)
        full_name = _truncate(_display_name_from_token(decoded, email), 255)
        firebase_uid_str = _truncate(str(firebase_uid), 255)

        try:
            user = await self._users.get_by_firebase_uid(
                self._session, firebase_uid_str
            )
            if user is not None:
                _ensure_login_allowed(user.account_status)
                token, expires_in = jwt_service.create_access_token(
                    user_id=user.id,
                    firebase_uid=user.firebase_uid or firebase_uid_str,
                )
                return TokenResponse(access_token=token, expires_in=expires_in)

            existing = await self._users.get_by_email(self._session, email)
            if existing is not None:
                if existing.firebase_uid is None:
                    existing.firebase_uid = firebase_uid_str
                    if profile_image_url and not existing.profile_image_url:
                        existing.profile_image_url = profile_image_url
                    _ensure_login_allowed(existing.account_status)
                    token, expires_in = jwt_service.create_access_token(
                        user_id=existing.id,
                        firebase_uid=firebase_uid_str,
                    )
                    await self._session.commit()
                    return TokenResponse(access_token=token, expires_in=expires_in)
                if existing.firebase_uid != firebase_uid_str:
                    raise AppException(
                        409,
                        "An account with this email already exists under a different login",
                    )
                _ensure_login_allowed(existing.account_status)
                token, expires_in = jwt_service.create_access_token(
                    user_id=existing.id,
                    firebase_uid=firebase_uid_str,
                )
                return TokenResponse(access_token=token, expires_in=expires_in)

            user = await self._users.create(
                self._session,
                email=email,
                full_name=full_name,
                firebase_uid=firebase_uid_str,
                hashed_password=_firebase_only_password_hash(),
                profile_image_url=profile_image_url,
            )
            _ensure_login_allowed(user.account_status)
            token, expires_in = jwt_service.create_access_token(
                user_id=user.id,
                firebase_uid=firebase_uid_str,
            )
            await self._session.commit()
            return TokenResponse(access_token=token, expires_in=expires_in)
        except IntegrityError:
            await self._session.rollback()
            raise AppException(
                409,
                "Could not create account; email may already be in use",
            ) from None
        except SQLAlchemyError as e:
            await self._session.rollback()
            logger.exception("Database error during Firebase login")
            raise AppException(503, "Database error during login") from e
