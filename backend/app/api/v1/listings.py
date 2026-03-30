"""
Listings: CRUD, map coordinates (WGS-84), media upload to Firebase Storage.
"""
from typing import cast

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_user, get_optional_user
from app.api.listing_payload import (
    listing_detail_response_from_orm,
    listing_response_from_orm,
)
from app.core.exceptions import AppException
from app.db.database import get_db
from app.models import User
from app.repositories.favorite_repository import FavoriteRepository
from app.repositories.listing_repository import ListingRepository
from app.schemas.listing import (
    ListingCreate,
    ListingListResponse,
    ListingResponse,
    ListingUpdate,
)
from app.schemas.media import ListingMediaResponse
from app.schemas.report import ListingReportCreate, ListingReportCreatedResponse
from app.services.listing_media_service import ListingMediaService
from app.services.listing_report_service import ListingReportService
from app.services.listing_service import ListingService

router = APIRouter()


def _csv_list(value: str | None) -> list[str] | None:
    if value is None or not value.strip():
        return None
    parts = [p.strip() for p in value.split(",") if p.strip()]
    return parts or None


@router.get(
    "",
    response_model=ListingListResponse,
    summary="Public feed (paginated)",
)
async def list_public_listings(
    skip: int = Query(0, ge=0, description="Offset for pagination"),
    limit: int = Query(20, ge=1, le=50, description="Page size"),
    q: str | None = Query(None, description="Full-text search (title, brand, model, description)"),
    brands: str | None = Query(
        None,
        description="Comma-separated brand names (exact match)",
    ),
    city: str | None = Query(None),
    year_min: int | None = Query(None, ge=1900, le=2100),
    year_max: int | None = Query(None, ge=1900, le=2100),
    price_min: float | None = Query(None, ge=0),
    price_max: float | None = Query(None, ge=0),
    mileage_min: int | None = Query(None, ge=0),
    mileage_max: int | None = Query(None, ge=0),
    fuel_types: str | None = Query(None, description="Comma-separated: petrol,diesel,..."),
    body_types: str | None = Query(None, description="Comma-separated: sedan,suv,..."),
    transmissions: str | None = Query(None, description="Comma-separated: manual,automatic,..."),
    colors: str | None = Query(None, description="Comma-separated exterior colors"),
    require_no_accident: bool = Query(False),
    db: AsyncSession = Depends(get_db),
) -> ListingListResponse:
    service = ListingService(db)
    rows, total = await service.list_public(
        skip=skip,
        limit=limit,
        q=q,
        brands=_csv_list(brands),
        city=city,
        year_min=year_min,
        year_max=year_max,
        price_min=price_min,
        price_max=price_max,
        mileage_min=mileage_min,
        mileage_max=mileage_max,
        fuel_types=_csv_list(fuel_types),
        body_types=_csv_list(body_types),
        transmissions=_csv_list(transmissions),
        colors=_csv_list(colors),
        require_no_accident=require_no_accident,
    )
    fav = FavoriteRepository()
    ids_list = [cast(int, r.id) for r in rows]
    fav_counts = await fav.counts_for_listings(db, ids_list)
    return ListingListResponse(
        items=[
            listing_response_from_orm(
                r,
                favorite_count=fav_counts.get(cast(int, r.id), 0),
            )
            for r in rows
        ],
        total=total,
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
    fav = FavoriteRepository()
    ids_list = [cast(int, r.id) for r in rows]
    fav_counts = await fav.counts_for_listings(db, ids_list)
    return [
        listing_response_from_orm(
            r,
            favorite_count=fav_counts.get(cast(int, r.id), 0),
        )
        for r in rows
    ]


@router.post(
    "",
    response_model=ListingResponse,
    status_code=201,
    summary="Create listing (published to public feed); send latitude/longitude from map picker",
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
    return listing_response_from_orm(row, favorite_count=0)


@router.post(
    "/{listing_id}/report",
    response_model=ListingReportCreatedResponse,
    status_code=201,
    summary="Report a listing (requires login; one active report per user per listing)",
)
async def report_listing(
    listing_id: int,
    body: ListingReportCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ListingReportCreatedResponse:
    service = ListingReportService(db)
    try:
        row = await service.submit_listing_report(
            cast(int, current_user.id),
            listing_id,
            body,
        )
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None
    return ListingReportCreatedResponse(
        id=cast(int, row.id),
        listing_id=listing_id,
    )


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


@router.get(
    "/{listing_id}",
    response_model=ListingResponse,
    summary="Listing detail",
)
async def get_listing(
    listing_id: int,
    db: AsyncSession = Depends(get_db),
    viewer: User | None = Depends(get_optional_user),
) -> ListingResponse:
    service = ListingService(db)
    try:
        row = await service.get_by_id(listing_id)
    except AppException as e:
        raise HTTPException(
            status_code=e.status_code,
            detail={"success": False, "error": e.error},
        ) from None
    owner_id = cast(int, row.owner_id)
    watcher_id = cast(int, viewer.id) if viewer else None
    if watcher_id is None or watcher_id != owner_id:
        row.view_count = await ListingRepository.increment_view_count(db, listing_id)
        await db.commit()
    fav = FavoriteRepository()
    fc = await fav.count_for_listing(db, listing_id)
    return listing_detail_response_from_orm(row, favorite_count=fc)


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
    fav = FavoriteRepository()
    fc = await fav.count_for_listing(db, listing_id)
    return listing_response_from_orm(row, favorite_count=fc)
