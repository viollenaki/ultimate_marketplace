from typing import cast

from sqlalchemy import and_, case, desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Listing, Report, User
from app.models.enums import ReportStatus
from app.models.report import REPORT_TARGET_LISTING


class ReportRepository:
    @staticmethod
    async def has_active_listing_report(
        session: AsyncSession,
        reporter_user_id: int,
        listing_id: int,
    ) -> bool:
        result = await session.execute(
            select(Report.id).where(
                Report.reporter_user_id == reporter_user_id,
                Report.target_type == REPORT_TARGET_LISTING,
                Report.target_id == listing_id,
                Report.is_deleted.is_(False),
            )
        )
        return result.scalar_one_or_none() is not None

    @staticmethod
    async def create_listing_report(
        session: AsyncSession,
        *,
        reporter_user_id: int,
        listing_id: int,
        reason_code: str,
        reason_text: str | None,
    ) -> Report:
        row = Report(
            reporter_user_id=reporter_user_id,
            target_type=REPORT_TARGET_LISTING,
            target_id=listing_id,
            reason_code=reason_code,
            reason_text=reason_text,
            status=ReportStatus.pending.value,
        )
        session.add(row)
        await session.flush()
        await session.refresh(row)
        return row

    @staticmethod
    async def count_admin_listing_reports(session: AsyncSession) -> int:
        result = await session.execute(
            select(func.count())
            .select_from(Report)
            .where(
                Report.target_type == REPORT_TARGET_LISTING,
                Report.is_deleted.is_(False),
            )
        )
        return int(result.scalar_one() or 0)

    @staticmethod
    async def list_admin_listing_reports(
        session: AsyncSession,
        *,
        listing_id: int | None,
        skip: int,
        limit: int,
    ) -> tuple[list[tuple[Report, str | None]], int]:
        filters = [
            Report.target_type == REPORT_TARGET_LISTING,
            Report.is_deleted.is_(False),
        ]
        if listing_id is not None:
            filters.append(Report.target_id == listing_id)
        where_clause = and_(*filters)
        total = int(
            (
                await session.execute(
                    select(func.count()).select_from(Report).where(where_clause)
                )
            ).scalar_one()
            or 0
        )
        result = await session.execute(
            select(Report, User.email)
            .outerjoin(User, User.id == Report.reporter_user_id)
            .where(where_clause)
            .order_by(desc(Report.created_at))
            .offset(skip)
            .limit(limit)
        )
        rows = [(cast(Report, r[0]), cast(str | None, r[1])) for r in result.all()]
        return rows, total

    @staticmethod
    async def aggregates_for_listings(
        session: AsyncSession,
        *,
        limit: int,
    ) -> list[tuple[int, int, object | None, str | None, int | None]]:
        """Returns (listing_id, report_count, last_reported_at, title, owner_id)."""
        subq = (
            select(
                Report.target_id.label("lid"),
                func.count(Report.id).label("cnt"),
                func.max(Report.created_at).label("last_at"),
            )
            .where(
                Report.target_type == REPORT_TARGET_LISTING,
                Report.is_deleted.is_(False),
            )
            .group_by(Report.target_id)
            .subquery()
        )
        stmt = (
            select(
                subq.c.lid,
                subq.c.cnt,
                subq.c.last_at,
                Listing.title,
                Listing.owner_id,
            )
            .join(Listing, Listing.id == subq.c.lid)
            .where(Listing.is_deleted.is_(False))
            .order_by(desc(subq.c.cnt))
            .limit(limit)
        )
        result = await session.execute(stmt)
        return [
            (
                int(r[0]),
                int(r[1]),
                r[2],
                cast(str | None, r[3]),
                cast(int | None, r[4]),
            )
            for r in result.all()
        ]

    @staticmethod
    async def list_listings_with_report_stats(
        session: AsyncSession,
        *,
        skip: int,
        limit: int,
    ) -> tuple[
        list[
            tuple[
                int,
                str,
                int,
                str,
                str,
                float,
                str,
                int,
                int,
                object | None,
            ]
        ],
        int,
    ]:
        """
        Listings that have at least one listing report.
        Returns rows:
        (listing_id, title, owner_id, city, status, price, currency,
         report_count, pending_report_count, last_report_at).
        """
        agg = (
            select(
                Report.target_id.label("lid"),
                func.count(Report.id).label("rc"),
                func.sum(
                    case(
                        (Report.status == ReportStatus.pending.value, 1),
                        else_=0,
                    )
                ).label("pc"),
                func.max(Report.created_at).label("last_at"),
            )
            .where(
                Report.target_type == REPORT_TARGET_LISTING,
                Report.is_deleted.is_(False),
            )
            .group_by(Report.target_id)
        ).subquery()

        total = int(
            (
                await session.execute(select(func.count()).select_from(agg))
            ).scalar_one()
            or 0
        )

        stmt = (
            select(
                Listing.id,
                Listing.title,
                Listing.owner_id,
                Listing.city,
                Listing.status,
                Listing.price,
                Listing.currency,
                agg.c.rc,
                agg.c.pc,
                agg.c.last_at,
            )
            .join(agg, Listing.id == agg.c.lid)
            .where(Listing.is_deleted.is_(False))
            .order_by(desc(agg.c.rc), desc(agg.c.last_at))
            .offset(skip)
            .limit(limit)
        )
        result = await session.execute(stmt)
        rows = [
            (
                int(r[0]),
                str(r[1]),
                int(r[2]),
                str(r[3] or ""),
                str(r[4] or ""),
                float(r[5] or 0),
                str(r[6] or "KGS"),
                int(r[7] or 0),
                int(r[8] or 0),
                r[9],
            )
            for r in result.all()
        ]
        return rows, total
