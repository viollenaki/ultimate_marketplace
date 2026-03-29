"""
Listings: CRUD, map coordinates (WGS-84), media upload to Firebase Storage.
"""
from typing import cast

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_user
from app.core.exceptions import AppException
from app.db.database import get_db
from app.models import Listing, User
from app.schemas.listing import (
    CategoryBrief,
    ListingCreate,
    ListingResponse,
    ListingUpdate,
)
from app.schemas.media import ListingMediaResponse
from app.services.listing_media_service import ListingMediaService
from app.services.listing_service import ListingService

router = APIRouter()


def _listing_response(row: Listing) -> ListingResponse:
    media_sorted = sorted(row.media, key=lambda m: m.order_index)
    return ListingResponse(
        id=cast(int, row.id),
        owner_id=cast(int, row.owner_id),
        category_id=cast(int, row.category_id),
        category=CategoryBrief.model_validate(row.category),
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
        media=[ListingMediaResponse.model_validate(m) for m in media_sorted],
    )


@router.get(
    "/me",
    response_model=list[ListingResponse],
    summary="Current user's listings",
)
async def list_my_listings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[ListingResponse]:
    service = ListingService(db)
    rows = await service.list_mine(cast(int, current_user.id))
    return [_listing_response(r) for r in rows]


@router.post(
    "",
    response_model=ListingResponse,
    status_code=201,
    summary="Create listing (draft); send latitude/longitude from map picker",
)
async def create_listing(
    body: ListingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ListingResponse:
    service = ListingService(db)
    try:
        row = await service.create(cast(int, current_user.id), body)
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None
    return _listing_response(row)


@router.get(
    "/{listing_id}",
    response_model=ListingResponse,
    summary="Listing detail",
)
async def get_listing(
    listing_id: int,
    db: AsyncSession = Depends(get_db),
) -> ListingResponse:
    service = ListingService(db)
    try:
        row = await service.get_by_id(listing_id)
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None
    return _listing_response(row)


@router.patch(
    "/{listing_id}",
    response_model=ListingResponse,
    summary="Update own listing (including map coordinates)",
)
async def update_listing(
    listing_id: int,
    body: ListingUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ListingResponse:
    service = ListingService(db)
    try:
        row = await service.update(
            cast(int, current_user.id),
            listing_id,
            body,
        )
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None
    return _listing_response(row)


@router.post(
    "/{listing_id}/media",
    response_model=ListingMediaResponse,
    summary="Upload listing image to Firebase Storage",
)
async def upload_listing_media(
    listing_id: int,
    file: UploadFile = File(..., description="Image file (JPEG, PNG, WebP, GIF, HEIC)"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ListingMediaResponse:
    service = ListingMediaService(db)
    try:
        media = await service.upload_listing_image(
            owner_id=cast(int, current_user.id),
            listing_id=listing_id,
            file=file,
        )
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None
    return ListingMediaResponse.model_validate(media)
