from typing import cast

from sqlalchemy import and_, case, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Listing
from app.models.enums import ListingStatus


def _public_feed_order_by():
    """Newest listings first (created_at); NULL created_at last (MySQL has no NULLS LAST)."""
    return (
        case((Listing.created_at.is_(None), 1), else_=0).asc(),
        Listing.created_at.desc(),
        Listing.id.desc(),
    )


def _public_feed_where():
    """Listings visible on the public home feed (not draft/rejected/deleted)."""
    return and_(
        Listing.is_deleted.is_(False),
        Listing.status.notin_(
            [ListingStatus.draft.value, ListingStatus.rejected.value]
        ),
    )


class ListingRepository:
    @staticmethod
    async def increment_view_count(
        session: AsyncSession,
        listing_id: int,
    ) -> int:
        res = await session.execute(
            update(Listing)
            .where(Listing.id == listing_id, Listing.is_deleted.is_(False))
            .values(view_count=Listing.view_count + 1)
        )
        if res.rowcount == 0:
            return 0
        await session.flush()
        vc = await session.execute(
            select(Listing.view_count).where(Listing.id == listing_id)
        )
        return int(vc.scalar_one() or 0)

    @staticmethod
    async def get_by_id(session: AsyncSession, listing_id: int) -> Listing | None:
        result = await session.execute(
            select(Listing)
            .options(
                selectinload(Listing.media),
                selectinload(Listing.owner),
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
            .options(selectinload(Listing.media))
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
            .options(selectinload(Listing.media))
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

    @staticmethod
    async def count_public(session: AsyncSession) -> int:
        result = await session.execute(
            select(func.count()).select_from(Listing).where(_public_feed_where())
        )
        return int(result.scalar_one() or 0)

    @staticmethod
    async def list_public(
        session: AsyncSession,
        *,
        offset: int = 0,
        limit: int = 20,
    ) -> list[Listing]:
        result = await session.execute(
            select(Listing)
            .options(selectinload(Listing.media))
            .where(_public_feed_where())
            .order_by(*_public_feed_order_by())
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().unique().all())

    @staticmethod
    async def list_by_ids_ordered(
        session: AsyncSession,
        ids: list[int],
    ) -> list[Listing]:
        """Hydrate listings in the same order as [ids] (skips missing ids)."""
        if not ids:
            return []
        result = await session.execute(
            select(Listing)
            .options(selectinload(Listing.media))
            .where(and_(Listing.id.in_(ids), _public_feed_where())),
        )
        by_id = {cast(int, row.id): row for row in result.scalars().unique().all()}
        return [by_id[i] for i in ids if i in by_id]

    @staticmethod
    def _apply_listing_filters(
        stmt,
        *,
        q: str | None = None,
        brands: list[str] | None = None,
        city: str | None = None,
        year_min: int | None = None,
        year_max: int | None = None,
        price_min: float | None = None,
        price_max: float | None = None,
        mileage_min: int | None = None,
        mileage_max: int | None = None,
        fuel_types: list[str] | None = None,
        body_types: list[str] | None = None,
        transmissions: list[str] | None = None,
        colors: list[str] | None = None,
        require_no_accident: bool = False,
    ):
        if q and q.strip():
            pat = f"%{q.strip()}%"
            stmt = stmt.where(
                or_(
                    Listing.title.ilike(pat),
                    Listing.brand.ilike(pat),
                    Listing.model.ilike(pat),
                    Listing.description.ilike(pat),
                )
            )
        if brands:
            cleaned = [b.strip() for b in brands if b.strip()]
            if cleaned:
                stmt = stmt.where(Listing.brand.in_(cleaned))
        if city and city.strip():
            stmt = stmt.where(Listing.city == city.strip())
        if year_min is not None:
            stmt = stmt.where(Listing.year >= year_min)
        if year_max is not None:
            stmt = stmt.where(Listing.year <= year_max)
        if price_min is not None:
            stmt = stmt.where(Listing.price >= price_min)
        if price_max is not None:
            stmt = stmt.where(Listing.price <= price_max)
        if mileage_min is not None:
            stmt = stmt.where(Listing.mileage >= mileage_min)
        if mileage_max is not None:
            stmt = stmt.where(Listing.mileage <= mileage_max)
        if fuel_types:
            ft = [f.strip() for f in fuel_types if f.strip()]
            if ft:
                stmt = stmt.where(Listing.fuel_type.in_(ft))
        if body_types:
            bt = [b.strip() for b in body_types if b.strip()]
            if bt:
                stmt = stmt.where(Listing.body_type.in_(bt))
        if transmissions:
            tr = [t.strip() for t in transmissions if t.strip()]
            if tr:
                stmt = stmt.where(Listing.transmission.in_(tr))
        if colors:
            cc = [c.strip() for c in colors if c.strip()]
            if cc:
                stmt = stmt.where(Listing.color.in_(cc))
        if require_no_accident:
            stmt = stmt.where(Listing.is_crashed.is_(False))
        return stmt

    @staticmethod
    async def count_public_filtered(
        session: AsyncSession,
        *,
        q: str | None = None,
        brands: list[str] | None = None,
        city: str | None = None,
        year_min: int | None = None,
        year_max: int | None = None,
        price_min: float | None = None,
        price_max: float | None = None,
        mileage_min: int | None = None,
        mileage_max: int | None = None,
        fuel_types: list[str] | None = None,
        body_types: list[str] | None = None,
        transmissions: list[str] | None = None,
        colors: list[str] | None = None,
        require_no_accident: bool = False,
    ) -> int:
        stmt = select(func.count()).select_from(Listing).where(_public_feed_where())
        stmt = ListingRepository._apply_listing_filters(
            stmt,
            q=q,
            brands=brands,
            city=city,
            year_min=year_min,
            year_max=year_max,
            price_min=price_min,
            price_max=price_max,
            mileage_min=mileage_min,
            mileage_max=mileage_max,
            fuel_types=fuel_types,
            body_types=body_types,
            transmissions=transmissions,
            colors=colors,
            require_no_accident=require_no_accident,
        )
        result = await session.execute(stmt)
        return int(result.scalar_one() or 0)

    @staticmethod
    async def list_public_filtered(
        session: AsyncSession,
        *,
        offset: int = 0,
        limit: int = 20,
        q: str | None = None,
        brands: list[str] | None = None,
        city: str | None = None,
        year_min: int | None = None,
        year_max: int | None = None,
        price_min: float | None = None,
        price_max: float | None = None,
        mileage_min: int | None = None,
        mileage_max: int | None = None,
        fuel_types: list[str] | None = None,
        body_types: list[str] | None = None,
        transmissions: list[str] | None = None,
        colors: list[str] | None = None,
        require_no_accident: bool = False,
    ) -> list[Listing]:
        stmt = select(Listing).options(selectinload(Listing.media))
        stmt = stmt.where(_public_feed_where())
        stmt = ListingRepository._apply_listing_filters(
            stmt,
            q=q,
            brands=brands,
            city=city,
            year_min=year_min,
            year_max=year_max,
            price_min=price_min,
            price_max=price_max,
            mileage_min=mileage_min,
            mileage_max=mileage_max,
            fuel_types=fuel_types,
            body_types=body_types,
            transmissions=transmissions,
            colors=colors,
            require_no_accident=require_no_accident,
        )
        stmt = stmt.order_by(*_public_feed_order_by()).offset(offset).limit(limit)
        result = await session.execute(stmt)
        return list(result.scalars().unique().all())
