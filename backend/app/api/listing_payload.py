"""Serialize Listing ORM → API models (shared by listings and favorites routes)."""
from datetime import datetime
from typing import Any, cast

from app.models import Listing
from app.schemas.listing import ListingResponse
from app.schemas.media import ListingMediaResponse
from app.schemas.user import UserPublic


def _listing_response(
    row: Listing,
    *,
    include_owner: bool = False,
    favorite_count: int = 0,
) -> ListingResponse:
    media_sorted = sorted(row.media, key=lambda m: m.order_index)
    owner_public: UserPublic | None = None
    if include_owner and row.owner is not None:
        owner_public = UserPublic.model_validate(row.owner)
    return ListingResponse(
        id=cast(int, row.id),
        owner_id=cast(int, row.owner_id),
        title=cast(str, row.title),
        description=cast(str, row.description),
        price=cast(float, row.price),
        currency=cast(str, row.currency),
        city=cast(str, row.city),
        latitude=cast(float | None, row.latitude),
        longitude=cast(float | None, row.longitude),
        location_display_name=cast(str | None, row.location_display_name),
        brand=cast(str, row.brand),
        model=cast(str, row.model),
        year=cast(int, row.year),
        mileage=cast(int, row.mileage),
        fuel_type=cast(str | None, row.fuel_type),
        transmission=cast(str | None, row.transmission),
        body_type=cast(str | None, row.body_type),
        color=cast(str | None, row.color),
        engine_volume=cast(float | None, row.engine_volume),
        horsepower=cast(int | None, row.horsepower),
        doors=cast(int | None, row.doors),
        is_crashed=cast(bool, row.is_crashed),
        has_warranty=cast(bool, row.has_warranty),
        status=cast(str, row.status),
        moderation_status=cast(str, row.moderation_status),
        view_count=cast(int, row.view_count or 0),
        favorite_count=favorite_count,
        published_at=cast(datetime | None, row.published_at),
        expires_at=cast(datetime | None, row.expires_at),
        additional_attributes=cast(dict[str, Any] | list[Any] | None, row.additional_attributes),
        media=[ListingMediaResponse.model_validate(m) for m in media_sorted],
        owner=owner_public,
    )


def listing_response_from_orm(row: Listing, *, favorite_count: int = 0) -> ListingResponse:
    return _listing_response(row, include_owner=False, favorite_count=favorite_count)


def listing_detail_response_from_orm(
    row: Listing,
    *,
    favorite_count: int = 0,
) -> ListingResponse:
    return _listing_response(row, include_owner=True, favorite_count=favorite_count)
