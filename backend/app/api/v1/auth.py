"""
Authentication: Firebase ID token exchange and session routes.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.db.database import get_db
from app.api.deps.auth import get_current_user
from app.models import User
from app.schemas.auth import CurrentUserResponse, FirebaseLoginRequest, TokenResponse
from app.services.auth_service import AuthService

router = APIRouter()


@router.post(
    "/login/firebase",
    response_model=TokenResponse,
    summary="Exchange Firebase ID token for API JWT",
)
async def login_with_firebase(
    body: FirebaseLoginRequest,
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


@router.get(
    "/me",
    response_model=CurrentUserResponse,
    summary="Current user (requires Bearer API JWT)",
)
async def read_me(current_user: User = Depends(get_current_user)) -> CurrentUserResponse:
    return CurrentUserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        firebase_uid=current_user.firebase_uid,
        account_status=current_user.account_status,
    )
