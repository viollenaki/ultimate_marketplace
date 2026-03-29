"""Firebase ID token verification, registration, and user provisioning."""
import asyncio
import logging
import secrets
from typing import Any

import bcrypt
from firebase_admin import auth as firebase_auth
from firebase_admin.exceptions import FirebaseError
from sqlalchemy.exc import (
    DataError,
    IntegrityError,
    OperationalError,
    ProgrammingError,
    SQLAlchemyError,
)
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.core.firebase import ensure_firebase_initialized
from app.models import User, UserStatus
from app.repositories.user_repository import UserRepository
from app.schemas.auth import TokenResponse
from app.services import jwt_service

logger = logging.getLogger(__name__)


def hash_password(plain: str) -> str:
    """Bcrypt hash for storing the user's password (email registration)."""
    raw = plain.encode("utf-8")
    if len(raw) > 72:
        raw = raw[:72]
    return bcrypt.hashpw(raw, bcrypt.gensalt()).decode("utf-8")


def _firebase_only_password_hash() -> str:
    """Placeholder when the user signs in only via OAuth / existing Firebase account."""
    raw = f"firebase:{secrets.token_urlsafe(32)}".encode("utf-8")
    return bcrypt.hashpw(raw, bcrypt.gensalt()).decode("utf-8")


def _verify_firebase_token_sync(id_token: str) -> dict[str, Any]:
    try:
        ensure_firebase_initialized()
    except FileNotFoundError as e:
        logger.error("Firebase Admin credentials missing: %s", e)
        raise AppException(
            503,
            "Server configuration error: Firebase credentials file not found",
        ) from e
    except ValueError as e:
        logger.error("Invalid Firebase credentials file: %s", e)
        raise AppException(
            503,
            "Server configuration error: invalid Firebase credentials file",
        ) from e
    return firebase_auth.verify_id_token(id_token)


def _create_firebase_user_sync(
    email: str,
    password: str,
    display_name: str,
) -> str:
    ensure_firebase_initialized()
    user_record = firebase_auth.create_user(
        email=email,
        password=password,
        display_name=display_name,
    )
    return user_record.uid


def _delete_firebase_user_sync(uid: str) -> None:
    ensure_firebase_initialized()
    firebase_auth.delete_user(uid)


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


def _sync_profile_from_oidc(
    user: User,
    *,
    full_name: str,
    profile_image_url: str | None,
) -> bool:
    """Update display fields from Firebase/Google token. Returns True if ORM object was changed."""
    changed = False
    if user.full_name != full_name:
        user.full_name = full_name
        changed = True
    if profile_image_url is not None and user.profile_image_url != profile_image_url:
        user.profile_image_url = profile_image_url
        changed = True
    return changed


class AuthService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._users = UserRepository()

    async def register_with_email_password(
        self,
        email: str,
        password: str,
        full_name: str,
    ) -> TokenResponse:
        email = _truncate(email.strip().lower(), 255)
        full_name = _truncate(full_name.strip(), 255)

        existing = await self._users.get_by_email(self._session, email)
        if existing is not None:
            raise AppException(409, "An account with this email already exists")

        firebase_uid: str | None = None
        try:
            firebase_uid = await asyncio.to_thread(
                _create_firebase_user_sync,
                email,
                password,
                full_name,
            )
            hashed = hash_password(password)
            user = await self._users.create(
                self._session,
                email=email,
                full_name=full_name,
                firebase_uid=firebase_uid,
                hashed_password=hashed,
                profile_image_url=None,
            )
            await self._session.commit()
            token, expires_in = jwt_service.create_access_token(
                user_id=user.id,
                firebase_uid=firebase_uid,
            )
            return TokenResponse(access_token=token, expires_in=expires_in)
        except firebase_auth.EmailAlreadyExistsError:
            await self._session.rollback()
            raise AppException(
                409,
                "This email is already registered in Firebase",
            ) from None
        except FirebaseError as e:
            await self._session.rollback()
            logger.warning("Firebase registration failed: %s", e)
            raise AppException(
                400,
                "Registration failed; check email and password requirements",
            ) from e
        except IntegrityError:
            await self._session.rollback()
            if firebase_uid:
                try:
                    await asyncio.to_thread(_delete_firebase_user_sync, firebase_uid)
                except FirebaseError:
                    logger.exception(
                        "Could not roll back Firebase user %s after IntegrityError",
                        firebase_uid,
                    )
            raise AppException(
                409,
                "Could not create account; email may already be in use",
            ) from None
        except (DataError, ProgrammingError, OperationalError, SQLAlchemyError) as e:
            await self._session.rollback()
            if firebase_uid:
                try:
                    await asyncio.to_thread(_delete_firebase_user_sync, firebase_uid)
                except FirebaseError:
                    logger.exception(
                        "Could not roll back Firebase user %s after DB error",
                        firebase_uid,
                    )
            orig = getattr(e, "orig", None)
            if isinstance(e, ProgrammingError):
                logger.exception(
                    "Database schema error during registration: %s", orig or e
                )
                raise AppException(
                    503,
                    "Database schema is not ready; run migrations on the server",
                ) from e
            if isinstance(e, OperationalError):
                logger.exception(
                    "Database connection error during registration: %s", orig or e
                )
                raise AppException(
                    503,
                    "Database is temporarily unavailable",
                ) from e
            if isinstance(e, DataError):
                logger.exception(
                    "Database rejected registration data: %s", orig or e
                )
                raise AppException(400, "Invalid registration data") from e
            logger.exception("Database error during registration: %s", orig or e)
            raise AppException(503, "Database error during registration") from e

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
                if _sync_profile_from_oidc(
                    user,
                    full_name=full_name,
                    profile_image_url=profile_image_url,
                ):
                    await self._session.commit()
                token, expires_in = jwt_service.create_access_token(
                    user_id=user.id,
                    firebase_uid=user.firebase_uid or firebase_uid_str,
                )
                return TokenResponse(access_token=token, expires_in=expires_in)

            existing = await self._users.get_by_email(self._session, email)
            if existing is not None:
                if existing.firebase_uid is None:
                    existing.firebase_uid = firebase_uid_str
                    _sync_profile_from_oidc(
                        existing,
                        full_name=full_name,
                        profile_image_url=profile_image_url,
                    )
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
                if _sync_profile_from_oidc(
                    existing,
                    full_name=full_name,
                    profile_image_url=profile_image_url,
                ):
                    await self._session.commit()
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
        except DataError as e:
            await self._session.rollback()
            orig = getattr(e, "orig", None)
            logger.exception(
                "Database rejected profile data during login (encoding/length): %s",
                orig or e,
            )
            raise AppException(
                400,
                "Could not save profile from your Google account; try again or contact support",
            ) from e
        except ProgrammingError as e:
            await self._session.rollback()
            orig = getattr(e, "orig", None)
            logger.exception(
                "Database schema error during login (run Alembic migrations): %s",
                orig or e,
            )
            raise AppException(
                503,
                "Database schema is not ready; run migrations on the server (alembic upgrade head)",
            ) from e
        except OperationalError as e:
            await self._session.rollback()
            orig = getattr(e, "orig", None)
            logger.exception("Database connection error during login: %s", orig or e)
            raise AppException(
                503,
                "Database is temporarily unavailable; check server logs and MySQL connectivity",
            ) from e
        except SQLAlchemyError as e:
            await self._session.rollback()
            orig = getattr(e, "orig", None)
            logger.exception("Database error during Firebase login: %s", orig or e)
            raise AppException(503, "Database error during login") from e
