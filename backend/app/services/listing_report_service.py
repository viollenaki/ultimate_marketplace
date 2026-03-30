from typing import cast

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.repositories.listing_repository import ListingRepository
from app.repositories.report_repository import ReportRepository
from app.schemas.report import LISTING_REPORT_REASON_CODES, ListingReportCreate


class ListingReportService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._reports = ReportRepository()
        self._listings = ListingRepository()

    async def submit_listing_report(
        self,
        reporter_id: int,
        listing_id: int,
        body: ListingReportCreate,
    ):
        if body.reason_code not in LISTING_REPORT_REASON_CODES:
            raise AppException(400, "Invalid reason_code")

        listing = await self._listings.get_by_id(self._session, listing_id)
        if listing is None:
            raise AppException(404, "Listing not found")

        if cast(int, listing.owner_id) == reporter_id:
            raise AppException(400, "You cannot report your own listing")

        if await self._reports.has_active_listing_report(
            self._session, reporter_id, listing_id
        ):
            raise AppException(409, "You have already reported this listing")

        details = body.reason_details.strip() if body.reason_details else None
        row = await self._reports.create_listing_report(
            self._session,
            reporter_user_id=reporter_id,
            listing_id=listing_id,
            reason_code=body.reason_code.strip(),
            reason_text=details,
        )
        await self._session.commit()
        await self._session.refresh(row)
        return row
