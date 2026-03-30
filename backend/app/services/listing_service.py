import logging
from datetime import datetime, timezone
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.elasticsearch_client import get_async_elasticsearch
from app.core.exceptions import AppException
from app.models import Listing
from app.models.enums import ListingStatus
from app.repositories.listing_repository import ListingRepository
from app.schemas.listing import ListingCreate, ListingUpdate
from app.services.listing_search_service import (
    safe_index_listing_async,
    search_public_listing_ids,
)

logger = logging.getLogger(__name__)


class ListingService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._listings = ListingRepository()

    def _validate_coordinates(
        self,
        lat: float | None,
        lng: float | None,
    ) -> None:
        if (lat is None) != (lng is None):
            raise AppException(
                400,
                "latitude and longitude must both be set or both omitted",
            )

    @staticmethod
    def _uses_search_or_filters(
        *,
        q: str | None,
        brands: list[str] | None,
        city: str | None,
        year_min: int | None,
        year_max: int | None,
        price_min: float | None,
        price_max: float | None,
        mileage_min: int | None,
        mileage_max: int | None,
        fuel_types: list[str] | None,
        body_types: list[str] | None,
        transmissions: list[str] | None,
        colors: list[str] | None,
        require_no_accident: bool,
    ) -> bool:
        return bool(
            (q and q.strip())
            or brands
            or (city and city.strip())
            or year_min is not None
            or year_max is not None
            or price_min is not None
            or price_max is not None
            or mileage_min is not None
            or mileage_max is not None
            or fuel_types
            or body_types
            or transmissions
            or colors
            or require_no_accident
        )

    async def create(self, owner_id: int, body: ListingCreate) -> Listing:
        self._validate_coordinates(body.latitude, body.longitude)

        row = Listing(
            owner_id=owner_id,
            title=body.title.strip(),
            description=body.description.strip(),
            price=body.price,
            currency=body.currency.strip() or "KGS",
            city=body.city.strip(),
            latitude=body.latitude,
            longitude=body.longitude,
            location_display_name=(
                body.location_display_name.strip()
                if body.location_display_name
                else None
            ),
            brand=body.brand.strip(),
            model=body.model.strip(),
            year=body.year,
            mileage=body.mileage,
            fuel_type=body.fuel_type,
            transmission=body.transmission,
            body_type=body.body_type,
            color=body.color.strip() if body.color else None,
            engine_volume=body.engine_volume,
            horsepower=body.horsepower,
            doors=body.doors,
            is_crashed=body.is_crashed,
            has_warranty=body.has_warranty,
            status=ListingStatus.approved.value,
            moderation_status="approved",
            published_at=datetime.now(timezone.utc),
            expires_at=body.expires_at,
            additional_attributes=body.additional_attributes,
        )
        await self._listings.create(self._session, row)
        await self._session.commit()
        full = await self._listings.get_by_id(self._session, row.id)
        if full is None:
            raise AppException(500, "Listing was not persisted")
        await self._try_index_listing(full)
        return full

    async def get_by_id(self, listing_id: int) -> Listing:
        row = await self._listings.get_by_id(self._session, listing_id)
        if row is None:
            raise AppException(404, "Listing not found")
        return row

    async def list_mine(self, owner_id: int) -> list[Listing]:
        return await self._listings.list_for_owner(self._session, owner_id)

    async def _try_index_listing(self, listing: Listing) -> None:
        es = get_async_elasticsearch()
        await safe_index_listing_async(es, listing)

    async def list_public(
        self,
        *,
        skip: int,
        limit: int,
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
    ) -> tuple[list[Listing], int]:
        use_filters = self._uses_search_or_filters(
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
        if not use_filters:
            total = await self._listings.count_public(self._session)
            rows = await self._listings.list_public(
                self._session,
                offset=skip,
                limit=limit,
            )
            return rows, total

        kw: dict[str, Any] = dict(
            skip=skip,
            limit=limit,
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
        es = get_async_elasticsearch()
        try:
            ids, total = await search_public_listing_ids(es, **kw)
        except Exception as e:
            logger.warning("Elasticsearch search failed, using SQL fallback: %s", e)
            total = await self._listings.count_public_filtered(
                self._session,
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
            rows = await self._listings.list_public_filtered(
                self._session,
                offset=skip,
                limit=limit,
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
            return rows, total

        rows = await self._listings.list_by_ids_ordered(self._session, ids)
        return rows, total

    async def update(
        self,
        owner_id: int,
        listing_id: int,
        body: ListingUpdate,
    ) -> Listing:
        row = await self._listings.get_owned(self._session, listing_id, owner_id)
        if row is None:
            raise AppException(404, "Listing not found or access denied")

        data = body.model_dump(exclude_unset=True)
        if "latitude" in data or "longitude" in data:
            lat = data.get("latitude", row.latitude)
            lng = data.get("longitude", row.longitude)
            self._validate_coordinates(lat, lng)

        for key, value in data.items():
            setattr(row, key, value)

        await self._session.commit()
        await self._session.refresh(row)
        full = await self._listings.get_by_id(self._session, listing_id)
        if full is None:
            raise AppException(500, "Listing not found after update")
        await self._try_index_listing(full)
        return full
