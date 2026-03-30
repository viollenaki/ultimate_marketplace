from typing import cast

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_user
from app.db.database import get_db
from app.models import User
from app.repositories.user_fcm_token_repository import UserFcmTokenRepository
from app.schemas.device import FcmTestPushBody, FcmTokenRegister
from app.services.push_notification_queue import enqueue_fcm_to_user

router = APIRouter()


@router.post(
    "/fcm-token",
    summary="Register or refresh FCM device token for the current user",
)
async def register_fcm_token(
    body: FcmTokenRegister,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    repo = UserFcmTokenRepository()
    await repo.upsert_token(
        db,
        user_id=cast(int, current_user.id),
        token=body.token.strip(),
        platform=body.platform.strip().lower() if body.platform else None,
    )
    await db.commit()
    return {"success": True}


@router.post(
    "/fcm-test",
    summary="Queue a test notification to all FCM tokens for the current user (Celery worker sends)",
)
async def test_fcm_to_self(
    body: FcmTestPushBody,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    repo = UserFcmTokenRepository()
    tokens = await repo.list_tokens_for_user(db, cast(int, current_user.id))
    if not tokens:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"success": False, "error": "No FCM tokens registered for this user"},
        )
    data = {"type": body.data_type, "id": body.data_id}
    task_id = enqueue_fcm_to_user(
        cast(int, current_user.id),
        title=body.title,
        body=body.body,
        data=data,
    )
    return {
        "success": True,
        "queued": True,
        "task_id": task_id,
        "device_count": len(tokens),
    }
