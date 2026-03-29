from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Favorite, Listing


class FavoriteRepository:
    @staticmethod
    async def exists(
        session: AsyncSession,
        user_id: int,
        listing_id: int,
    ) -> bool:
        result = await session.execute(
            select(Favorite.id).where(
                Favorite.user_id == user_id,
                Favorite.listing_id == listing_id,
            )
        )
        return result.scalar_one_or_none() is not None

    @staticmethod
    async def add(
        session: AsyncSession,
        user_id: int,
        listing_id: int,
    ) -> None:
        if await FavoriteRepository.exists(session, user_id, listing_id):
            return
        session.add(Favorite(user_id=user_id, listing_id=listing_id))
        await session.flush()

    @staticmethod
    async def remove(
        session: AsyncSession,
        user_id: int,
        listing_id: int,
    ) -> None:
        await session.execute(
            delete(Favorite).where(
                Favorite.user_id == user_id,
                Favorite.listing_id == listing_id,
            )
        )

    @staticmethod
    async def listing_ids_for_user(
        session: AsyncSession,
        user_id: int,
    ) -> list[int]:
        result = await session.execute(
            select(Favorite.listing_id)
            .where(Favorite.user_id == user_id)
            .order_by(Favorite.created_at.desc())
        )
        return [int(x) for x in result.scalars().all()]

    @staticmethod
    async def list_listings(
        session: AsyncSession,
        user_id: int,
    ) -> list[Listing]:
        result = await session.execute(
            select(Listing)
            .join(Favorite, Favorite.listing_id == Listing.id)
            .where(
                Favorite.user_id == user_id,
                Listing.is_deleted.is_(False),
            )
            .options(selectinload(Listing.media))
            .order_by(Favorite.created_at.desc())
        )
        return list(result.scalars().unique().all())
