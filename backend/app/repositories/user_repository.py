from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User


class UserRepository:
    @staticmethod
    async def get_by_firebase_uid(session: AsyncSession, firebase_uid: str) -> User | None:
        result = await session.execute(select(User).where(User.firebase_uid == firebase_uid))
        return result.scalar_one_or_none()

    @staticmethod
    async def get_by_email(session: AsyncSession, email: str) -> User | None:
        result = await session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    @staticmethod
    async def get_by_id(session: AsyncSession, user_id: int) -> User | None:
        result = await session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    @staticmethod
    async def create(
        session: AsyncSession,
        *,
        email: str,
        full_name: str,
        firebase_uid: str,
        hashed_password: str,
        profile_image_url: str | None = None,
    ) -> User:
        user = User(
            email=email,
            full_name=full_name,
            firebase_uid=firebase_uid,
            hashed_password=hashed_password,
            profile_image_url=profile_image_url,
        )
        session.add(user)
        await session.flush()
        await session.refresh(user)
        return user
