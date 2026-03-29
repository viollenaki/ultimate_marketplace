"""
Users resource: registration and current profile (REST).
"""
from typing import cast

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.db.database import get_db
from app.api.deps.auth import get_current_user
from app.models import User
from app.schemas.auth import CurrentUserResponse, TokenResponse
from app.schemas.user import UserRegisterRequest
from app.services.auth_service import AuthService

router = APIRouter()


@router.post(
    "",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary=(
        "Server-side registration: create Firebase user (Admin SDK) + DB row. "
        "Mobile apps typically use the Firebase client SDK first, then "
        "POST /api/v1/auth/sessions to sync the DB."
    ),
)
async def register_user(
    body: UserRegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    service = AuthService(db)
    try:
        return await service.register_with_email_password(
            email=body.email,
            password=body.password,
            full_name=body.full_name,
        )
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None


@router.get(
    "/me",
    response_model=CurrentUserResponse,
    summary="Current authenticated user",
)
async def read_current_user(
    current_user: User = Depends(get_current_user),
) -> CurrentUserResponse:
    return CurrentUserResponse(
        id=cast(int, current_user.id),
        email=cast(str, current_user.email),
        full_name=cast(str, current_user.full_name),
        firebase_uid=cast(str | None, current_user.firebase_uid),
        account_status=cast(str, current_user.account_status),
        profile_image_url=cast(str | None, current_user.profile_image_url),
    )
