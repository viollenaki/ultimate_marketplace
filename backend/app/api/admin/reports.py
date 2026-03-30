"""
Admin: listing reports (audit trail + aggregates for moderation).
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.repositories.report_repository import ReportRepository
from app.schemas.report import (
    AdminListingReportAggregate,
    AdminListingReportAggregatesResponse,
    AdminListingReportRow,
    AdminListingReportsListResponse,
)

router = APIRouter()


@router.get(
    "/listings",
    response_model=AdminListingReportsListResponse,
    summary="Paginated listing reports (newest first)",
)
async def admin_list_listing_reports(
    listing_id: int | None = Query(None, description="Filter by listing id"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    repo = ReportRepository()
    rows, total = await repo.list_admin_listing_reports(
        db,
        listing_id=listing_id,
        skip=skip,
        limit=limit,
    )
    items = [
        AdminListingReportRow(
            id=int(r.id),
            listing_id=int(r.target_id),
            reporter_user_id=int(r.reporter_user_id),
            reporter_email=email,
            reason_code=str(r.reason_code),
            reason_text=r.reason_text,
            status=str(r.status),
            created_at=r.created_at,
        )
        for r, email in rows
    ]
    return AdminListingReportsListResponse(items=items, total=total)


@router.get(
    "/listings/aggregates",
    response_model=AdminListingReportAggregatesResponse,
    summary="Listings ranked by report count (moderation queue)",
)
async def admin_listing_report_aggregates(
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    repo = ReportRepository()
    raw = await repo.aggregates_for_listings(db, limit=limit)
    items = [
        AdminListingReportAggregate(
            listing_id=lid,
            report_count=cnt,
            last_reported_at=last_at,
            listing_title=title,
            listing_owner_id=owner_id,
        )
        for lid, cnt, last_at, title, owner_id in raw
    ]
    return AdminListingReportAggregatesResponse(items=items)
