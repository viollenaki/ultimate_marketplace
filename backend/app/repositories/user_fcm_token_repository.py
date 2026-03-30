from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session

from app.models import UserFcmToken


class UserFcmTokenRepository:
    @staticmethod
    async def upsert_token(
        session: AsyncSession,
        *,
        user_id: int,
        token: str,
        platform: str | None,
    ) -> UserFcmToken:
        """One row per token; re-assign to user if token moves (reinstall / login switch)."""
        result = await session.execute(
            select(UserFcmToken).where(UserFcmToken.token == token)
        )
        row = result.scalar_one_or_none()
        if row is None:
            row = UserFcmToken(user_id=user_id, token=token, platform=platform)
            session.add(row)
        else:
            row.user_id = user_id
            row.platform = platform
        await session.flush()
        await session.refresh(row)
        return row

    @staticmethod
    async def list_tokens_for_user(session: AsyncSession, user_id: int) -> list[str]:
        result = await session.execute(
            select(UserFcmToken.token).where(
                UserFcmToken.user_id == user_id,
                UserFcmToken.is_deleted.is_(False),
            )
        )
        return [r[0] for r in result.all()]

    @staticmethod
    def list_tokens_for_user_sync(session: Session, user_id: int) -> list[str]:
        result = session.execute(
            select(UserFcmToken.token).where(
                UserFcmToken.user_id == user_id,
                UserFcmToken.is_deleted.is_(False),
            )
        )
        return [r[0] for r in result.all()]
