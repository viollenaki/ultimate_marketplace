"""
Auth: API session (JWT) created from Firebase sign-in.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.db.database import get_db
from app.schemas.auth import SessionCreateRequest, TokenResponse
from app.services.auth_service import AuthService

router = APIRouter()


@router.post(
    "/sessions",
    response_model=TokenResponse,
    summary="Create API session (exchange Firebase ID token for JWT)",
)
async def create_session(
    body: SessionCreateRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    service = AuthService(db)
    try:
        return await service.login_with_firebase_id_token(body.id_token)
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None


@router.post(
    "/login/firebase",
    response_model=TokenResponse,
    summary="[Deprecated] Same as POST /auth/sessions",
    deprecated=True,
)
async def login_with_firebase_legacy(
    body: SessionCreateRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    return await create_session(body, db)
