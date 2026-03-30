"""
Admin: listings with moderation context (reports).
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.repositories.report_repository import ReportRepository
from app.schemas.report import AdminReportedListingRow, AdminReportedListingsResponse

router = APIRouter()


@router.get(
    "/with-reports",
    response_model=AdminReportedListingsResponse,
    summary="Listings that have user reports (with counts)",
)
async def admin_listings_with_reports(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    repo = ReportRepository()
    rows, total = await repo.list_listings_with_report_stats(db, skip=skip, limit=limit)
    items = [
        AdminReportedListingRow(
            listing_id=lid,
            title=title,
            owner_id=owner_id,
            city=city,
            status=status,
            price=price,
            currency=currency,
            report_count=rc,
            pending_report_count=pc,
            last_report_at=last_at,
        )
        for lid, title, owner_id, city, status, price, currency, rc, pc, last_at in rows
    ]
    return AdminReportedListingsResponse(items=items, total=total)
