from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.models import Listing
from app.models.enums import ListingStatus
from app.repositories.category_repository import CategoryRepository
from app.repositories.listing_repository import ListingRepository
from app.schemas.listing import ListingCreate, ListingUpdate


class ListingService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._listings = ListingRepository()
        self._categories = CategoryRepository()

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

    async def create(self, owner_id: int, body: ListingCreate) -> Listing:
        self._validate_coordinates(body.latitude, body.longitude)
        cat = await self._categories.get_by_id(self._session, body.category_id)
        if cat is None:
            raise AppException(400, "Invalid or inactive category")

        row = Listing(
            owner_id=owner_id,
            category_id=body.category_id,
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
            status=ListingStatus.draft.value,
        )
        await self._listings.create(self._session, row)
        await self._session.commit()
        full = await self._listings.get_by_id(self._session, row.id)
        if full is None:
            raise AppException(500, "Listing was not persisted")
        return full

    async def get_by_id(self, listing_id: int) -> Listing:
        row = await self._listings.get_by_id(self._session, listing_id)
        if row is None:
            raise AppException(404, "Listing not found")
        return row

    async def list_mine(self, owner_id: int) -> list[Listing]:
        return await self._listings.list_for_owner(self._session, owner_id)

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

        if "category_id" in data and data["category_id"] is not None:
            cat = await self._categories.get_by_id(
                self._session, data["category_id"]
            )
            if cat is None:
                raise AppException(400, "Invalid or inactive category")

        for key, value in data.items():
            setattr(row, key, value)

        await self._session.commit()
        await self._session.refresh(row)
        full = await self._listings.get_by_id(self._session, listing_id)
        if full is None:
            raise AppException(500, "Listing not found after update")
        return full
