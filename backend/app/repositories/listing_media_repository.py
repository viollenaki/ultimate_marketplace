from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import ListingMedia


class ListingMediaRepository:
    @staticmethod
    async def count_for_listing(session: AsyncSession, listing_id: int) -> int:
        result = await session.execute(
            select(func.count())
            .select_from(ListingMedia)
            .where(ListingMedia.listing_id == listing_id)
        )
        return int(result.scalar_one() or 0)

    @staticmethod
    async def next_order_index(session: AsyncSession, listing_id: int) -> int:
        result = await session.execute(
            select(func.coalesce(func.max(ListingMedia.order_index), -1)).where(
                ListingMedia.listing_id == listing_id
            )
        )
        return int(result.scalar_one()) + 1

    @staticmethod
    async def create(
        session: AsyncSession,
        *,
        listing_id: int,
        file_url: str,
        storage_bucket: str,
        storage_path: str,
        content_type: str | None,
        file_size: int | None,
        order_index: int,
        is_primary: bool,
    ) -> ListingMedia:
        row = ListingMedia(
            listing_id=listing_id,
            file_url=file_url,
            storage_bucket=storage_bucket,
            storage_path=storage_path,
            content_type=content_type,
            file_size=file_size,
            order_index=order_index,
            is_primary=is_primary,
        )
        session.add(row)
        await session.flush()
        await session.refresh(row)
        return row
