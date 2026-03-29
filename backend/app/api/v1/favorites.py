from typing import cast

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_user
from app.api.listing_payload import listing_response_from_orm
from app.db.database import get_db
from app.models import User
from app.repositories.favorite_repository import FavoriteRepository
from app.repositories.listing_repository import ListingRepository
from app.schemas.listing import FavoriteListingIdsResponse, ListingResponse

router = APIRouter()


@router.get(
    "/ids",
    response_model=FavoriteListingIdsResponse,
    summary="Listing ids the current user has favorited",
)
async def list_favorite_ids(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FavoriteListingIdsResponse:
    repo = FavoriteRepository()
    ids = await repo.listing_ids_for_user(db, cast(int, current_user.id))
    return FavoriteListingIdsResponse(listing_ids=ids)


@router.get(
    "",
    response_model=list[ListingResponse],
    summary="Current user's favorited listings",
)
async def list_favorites(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[ListingResponse]:
    repo = FavoriteRepository()
    rows = await repo.list_listings(db, cast(int, current_user.id))
    return [listing_response_from_orm(r) for r in rows]


@router.post(
    "/{listing_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Add listing to favorites",
)
async def add_favorite(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    listings = ListingRepository()
    row = await listings.get_by_id(db, listing_id)
    if row is None:
        raise HTTPException(
            status_code=404,
            detail={"success": False, "error": "Listing not found"},
        )
    fav = FavoriteRepository()
    await fav.add(db, cast(int, current_user.id), listing_id)
    await db.commit()


@router.delete(
    "/{listing_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove listing from favorites",
)
async def remove_favorite(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    fav = FavoriteRepository()
    await fav.remove(db, cast(int, current_user.id), listing_id)
    await db.commit()
