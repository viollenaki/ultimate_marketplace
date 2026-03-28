"""Encode and decode custom API JWTs (issued after Firebase login)."""
from datetime import datetime, timedelta, timezone

import jwt

from app.core.config import settings


def create_access_token(*, user_id: int, firebase_uid: str) -> tuple[str, int]:
    """
    Returns (token, expires_in_seconds).
    """
    expire_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    now = datetime.now(timezone.utc)
    expire = now + expire_delta
    expires_in = int(expire_delta.total_seconds())
    payload = {
        "sub": str(user_id),
        "firebase_uid": firebase_uid,
        "iat": int(now.timestamp()),
        "exp": expire,
        "typ": "access",
    }
    token = jwt.encode(
        payload,
        settings.SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token, expires_in


def decode_access_token(token: str) -> dict:
    """Return payload dict or raise jwt exceptions."""
    return jwt.decode(
        token,
        settings.SECRET_KEY,
        algorithms=[settings.JWT_ALGORITHM],
    )


__all__ = ["create_access_token", "decode_access_token"]
