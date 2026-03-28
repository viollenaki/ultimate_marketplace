from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.exceptions import ExpiredSignatureError, InvalidTokenError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.models import User, UserStatus
from app.repositories.user_repository import UserRepository
from app.services import jwt_service

security = HTTPBearer(auto_error=False)


def _unauthorized(message: str) -> HTTPException:
    return HTTPException(
        status_code=401,
        detail={"success": False, "error": message},
    )


def _forbidden(message: str) -> HTTPException:
    return HTTPException(
        status_code=403,
        detail={"success": False, "error": message},
    )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized("Not authenticated")

    token = credentials.credentials
    try:
        payload = jwt_service.decode_access_token(token)
    except ExpiredSignatureError:
        raise _unauthorized("Token has expired") from None
    except InvalidTokenError:
        raise _unauthorized("Invalid token") from None

    sub = payload.get("sub")
    if sub is None:
        raise _unauthorized("Invalid token payload")

    try:
        user_id = int(sub)
    except (TypeError, ValueError):
        raise _unauthorized("Invalid token payload") from None

    firebase_uid = payload.get("firebase_uid")
    if not firebase_uid or not isinstance(firebase_uid, str):
        raise _unauthorized("Invalid token payload")

    user = await UserRepository.get_by_id(db, user_id)
    if user is None:
        raise _unauthorized("User not found")

    if user.firebase_uid != firebase_uid:
        raise _unauthorized("Token no longer valid for this account")

    if user.account_status == UserStatus.suspended.value:
        raise _forbidden("Account is suspended")

    if user.account_status == UserStatus.deleted.value:
        raise _forbidden("Account is no longer available")

    return user
