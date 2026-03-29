from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Listing


class ListingRepository:
    @staticmethod
    async def get_by_id(session: AsyncSession, listing_id: int) -> Listing | None:
        result = await session.execute(
            select(Listing)
            .options(
                selectinload(Listing.media),
                selectinload(Listing.category),
            )
            .where(Listing.id == listing_id, Listing.is_deleted.is_(False))
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def get_owned(
        session: AsyncSession,
        listing_id: int,
        owner_id: int,
    ) -> Listing | None:
        result = await session.execute(
            select(Listing)
            .options(
                selectinload(Listing.media),
                selectinload(Listing.category),
            )
            .where(
                Listing.id == listing_id,
                Listing.owner_id == owner_id,
                Listing.is_deleted.is_(False),
            )
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def list_for_owner(
        session: AsyncSession,
        owner_id: int,
        *,
        limit: int = 100,
        offset: int = 0,
    ) -> list[Listing]:
        result = await session.execute(
            select(Listing)
            .options(
                selectinload(Listing.media),
                selectinload(Listing.category),
            )
            .where(Listing.owner_id == owner_id, Listing.is_deleted.is_(False))
            .order_by(Listing.id.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().unique().all())

    @staticmethod
    async def create(session: AsyncSession, listing: Listing) -> Listing:
        session.add(listing)
        await session.flush()
        await session.refresh(listing)
        return listing
