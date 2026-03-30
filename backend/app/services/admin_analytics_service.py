"""Aggregations for admin analytics dashboard."""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Conversation,
    Favorite,
    Listing,
    Message,
    Payment,
    Report,
    User,
)
from app.models.enums import ListingStatus, PaymentStatus, ReportStatus, UserStatus


def _utc_today() -> date:
    return datetime.now(timezone.utc).date()


def _day_range(days: int) -> tuple[date, date]:
    end = _utc_today()
    start = end - timedelta(days=max(1, min(days, 366)) - 1)
    return start, end


def _fill_daily_counts(
    start: date,
    end: date,
    rows: list[tuple[Any, int]],
) -> list[dict[str, Any]]:
    m: dict[str, int] = {}
    for d, c in rows:
        if d is None:
            continue
        if hasattr(d, "isoformat"):
            key = d.isoformat()
        else:
            key = str(d)
        m[key] = int(c)
    out: list[dict[str, Any]] = []
    cur = start
    while cur <= end:
        k = cur.isoformat()
        out.append({"date": k, "count": m.get(k, 0)})
        cur += timedelta(days=1)
    return out


def _fill_daily_amounts(
    start: date,
    end: date,
    rows: list[tuple[Any, float, int]],
) -> list[dict[str, Any]]:
    amounts: dict[str, float] = {}
    counts: dict[str, int] = {}
    for d, amt, cnt in rows:
        if d is None:
            continue
        key = d.isoformat() if hasattr(d, "isoformat") else str(d)
        amounts[key] = float(amt or 0)
        counts[key] = int(cnt or 0)
    out: list[dict[str, Any]] = []
    cur = start
    while cur <= end:
        k = cur.isoformat()
        out.append({"date": k, "amount": amounts.get(k, 0.0), "count": counts.get(k, 0)})
        cur += timedelta(days=1)
    return out


class AdminAnalyticsService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def dashboard(self, days: int = 30) -> dict[str, Any]:
        start_d, end_d = _day_range(days)
        start_dt = datetime(start_d.year, start_d.month, start_d.day, tzinfo=timezone.utc)

        overview = await self._overview()
        listings_ts = await self._listings_per_day(start_dt)
        users_ts = await self._users_per_day(start_dt)
        messages_ts = await self._messages_per_day(start_dt)
        payments_ts = await self._payment_volume_per_day(start_dt)

        return {
            "overview": overview,
            "timeseries": {
                "listings_per_day": _fill_daily_counts(start_d, end_d, listings_ts),
                "users_per_day": _fill_daily_counts(start_d, end_d, users_ts),
                "messages_per_day": _fill_daily_counts(start_d, end_d, messages_ts),
                "payment_volume_per_day": _fill_daily_amounts(start_d, end_d, payments_ts),
            },
            "breakdowns": {
                "listings_by_status": await self._listings_by_status(),
                "listings_by_city": await self._listings_by_city(12),
                "listings_by_brand": await self._listings_by_brand(12),
                "payments_by_status": await self._payments_by_status(),
                "reports_by_status": await self._reports_by_status(),
            },
        }

    async def overview_only(self) -> dict[str, Any]:
        return await self._overview()

    async def timeseries_only(self, days: int) -> dict[str, Any]:
        start_d, end_d = _day_range(days)
        start_dt = datetime(start_d.year, start_d.month, start_d.day, tzinfo=timezone.utc)
        listings_ts = await self._listings_per_day(start_dt)
        users_ts = await self._users_per_day(start_dt)
        messages_ts = await self._messages_per_day(start_dt)
        payments_ts = await self._payment_volume_per_day(start_dt)
        return {
            "days": days,
            "date_start": start_d.isoformat(),
            "date_end": end_d.isoformat(),
            "listings_per_day": _fill_daily_counts(start_d, end_d, listings_ts),
            "users_per_day": _fill_daily_counts(start_d, end_d, users_ts),
            "messages_per_day": _fill_daily_counts(start_d, end_d, messages_ts),
            "payment_volume_per_day": _fill_daily_amounts(start_d, end_d, payments_ts),
        }

    async def listings_breakdown(self) -> dict[str, Any]:
        return {
            "by_status": await self._listings_by_status(),
            "by_city": await self._listings_by_city(20),
            "by_brand": await self._listings_by_brand(20),
        }

    async def payments_analytics(self, days: int) -> dict[str, Any]:
        start_d, end_d = _day_range(days)
        start_dt = datetime(start_d.year, start_d.month, start_d.day, tzinfo=timezone.utc)
        payments_ts = await self._payment_volume_per_day(start_dt)
        return {
            "days": days,
            "by_status": await self._payments_by_status(),
            "successful_totals": {
                "count": await self._db.scalar(
                    select(func.count())
                    .select_from(Payment)
                    .where(Payment.is_deleted.is_(False))
                    .where(Payment.status == PaymentStatus.successful.value)
                )
                or 0,
                "amount_sum": float(
                    await self._db.scalar(
                        select(func.coalesce(func.sum(Payment.amount), 0))
                        .select_from(Payment)
                        .where(Payment.is_deleted.is_(False))
                        .where(Payment.status == PaymentStatus.successful.value)
                    )
                    or 0
                ),
            },
            "payment_volume_per_day": _fill_daily_amounts(start_d, end_d, payments_ts),
        }

    async def reports_summary(self) -> dict[str, Any]:
        pending = await self._db.scalar(
            select(func.count())
            .select_from(Report)
            .where(Report.is_deleted.is_(False))
            .where(Report.status == ReportStatus.pending.value)
        )
        total = await self._db.scalar(
            select(func.count()).select_from(Report).where(Report.is_deleted.is_(False))
        )
        return {
            "reports_total": int(total or 0),
            "reports_pending": int(pending or 0),
            "by_status": await self._reports_by_status(),
        }

    async def engagement_summary(self) -> dict[str, Any]:
        """Messages, conversations, favorites (no timeseries)."""
        return {
            "messages_total": int(
                await self._db.scalar(
                    select(func.count()).select_from(Message).where(Message.is_deleted.is_(False))
                )
                or 0
            ),
            "conversations_total": int(
                await self._db.scalar(
                    select(func.count())
                    .select_from(Conversation)
                    .where(Conversation.is_deleted.is_(False))
                )
                or 0
            ),
            "favorites_total": int(
                await self._db.scalar(
                    select(func.count()).select_from(Favorite).where(Favorite.is_deleted.is_(False))
                )
                or 0
            ),
        }

    async def _overview(self) -> dict[str, Any]:
        db = self._db

        users_total = await db.scalar(
            select(func.count()).select_from(User).where(User.is_deleted.is_(False))
        )
        users_active = await db.scalar(
            select(func.count())
            .select_from(User)
            .where(User.is_deleted.is_(False))
            .where(User.account_status == UserStatus.active.value)
        )

        listings_total = await db.scalar(
            select(func.count()).select_from(Listing).where(Listing.is_deleted.is_(False))
        )
        listings_approved = await db.scalar(
            select(func.count())
            .select_from(Listing)
            .where(Listing.is_deleted.is_(False))
            .where(Listing.status == ListingStatus.approved.value)
        )

        messages_total = await db.scalar(
            select(func.count()).select_from(Message).where(Message.is_deleted.is_(False))
        )
        conversations_total = await db.scalar(
            select(func.count())
            .select_from(Conversation)
            .where(Conversation.is_deleted.is_(False))
        )
        favorites_total = await db.scalar(
            select(func.count()).select_from(Favorite).where(Favorite.is_deleted.is_(False))
        )

        pay_ok_count = await db.scalar(
            select(func.count())
            .select_from(Payment)
            .where(Payment.is_deleted.is_(False))
            .where(Payment.status == PaymentStatus.successful.value)
        )
        pay_ok_amount = await db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0))
            .select_from(Payment)
            .where(Payment.is_deleted.is_(False))
            .where(Payment.status == PaymentStatus.successful.value)
        )

        reports_open = await db.scalar(
            select(func.count())
            .select_from(Report)
            .where(Report.is_deleted.is_(False))
            .where(Report.status == ReportStatus.pending.value)
        )

        return {
            "users_total": int(users_total or 0),
            "users_active": int(users_active or 0),
            "listings_total": int(listings_total or 0),
            "listings_approved": int(listings_approved or 0),
            "messages_total": int(messages_total or 0),
            "conversations_total": int(conversations_total or 0),
            "favorites_total": int(favorites_total or 0),
            "payments_successful_count": int(pay_ok_count or 0),
            "payments_successful_amount": float(pay_ok_amount or 0),
            "reports_pending": int(reports_open or 0),
        }

    async def _listings_per_day(self, start_dt: datetime) -> list[tuple[Any, int]]:
        day = func.date(Listing.created_at)
        q = (
            select(day, func.count())
            .where(Listing.is_deleted.is_(False))
            .where(Listing.created_at >= start_dt)
            .group_by(day)
            .order_by(day)
        )
        r = await self._db.execute(q)
        return list(r.all())

    async def _users_per_day(self, start_dt: datetime) -> list[tuple[Any, int]]:
        day = func.date(User.created_at)
        q = (
            select(day, func.count())
            .where(User.is_deleted.is_(False))
            .where(User.created_at >= start_dt)
            .group_by(day)
            .order_by(day)
        )
        r = await self._db.execute(q)
        return list(r.all())

    async def _messages_per_day(self, start_dt: datetime) -> list[tuple[Any, int]]:
        day_col = func.coalesce(func.date(Message.sent_at), func.date(Message.created_at))
        q = (
            select(day_col, func.count())
            .where(Message.is_deleted.is_(False))
            .where(
                func.coalesce(Message.sent_at, Message.created_at) >= start_dt,
            )
            .group_by(day_col)
            .order_by(day_col)
        )
        r = await self._db.execute(q)
        return list(r.all())

    async def _payment_volume_per_day(self, start_dt: datetime) -> list[tuple[Any, float, int]]:
        day_col = func.coalesce(func.date(Payment.paid_at), func.date(Payment.created_at))
        q = (
            select(day_col, func.coalesce(func.sum(Payment.amount), 0), func.count())
            .where(Payment.is_deleted.is_(False))
            .where(Payment.status == PaymentStatus.successful.value)
            .where(
                func.coalesce(Payment.paid_at, Payment.created_at) >= start_dt,
            )
            .group_by(day_col)
            .order_by(day_col)
        )
        r = await self._db.execute(q)
        return [(row[0], float(row[1] or 0), int(row[2] or 0)) for row in r.all()]

    async def _listings_by_status(self) -> list[dict[str, Any]]:
        q = (
            select(Listing.status, func.count())
            .where(Listing.is_deleted.is_(False))
            .group_by(Listing.status)
            .order_by(func.count().desc())
        )
        r = await self._db.execute(q)
        return [{"status": s or "unknown", "count": int(c)} for s, c in r.all()]

    async def _listings_by_city(self, limit: int) -> list[dict[str, Any]]:
        q = (
            select(Listing.city, func.count())
            .where(Listing.is_deleted.is_(False))
            .where(Listing.city != "")
            .group_by(Listing.city)
            .order_by(func.count().desc())
            .limit(limit)
        )
        r = await self._db.execute(q)
        return [{"city": c, "count": int(n)} for c, n in r.all()]

    async def _listings_by_brand(self, limit: int) -> list[dict[str, Any]]:
        q = (
            select(Listing.brand, func.count())
            .where(Listing.is_deleted.is_(False))
            .where(Listing.brand != "")
            .group_by(Listing.brand)
            .order_by(func.count().desc())
            .limit(limit)
        )
        r = await self._db.execute(q)
        return [{"brand": b, "count": int(n)} for b, n in r.all()]

    async def _payments_by_status(self) -> list[dict[str, Any]]:
        q = (
            select(Payment.status, func.count())
            .where(Payment.is_deleted.is_(False))
            .group_by(Payment.status)
            .order_by(func.count().desc())
        )
        r = await self._db.execute(q)
        return [{"status": s or "unknown", "count": int(c)} for s, c in r.all()]

    async def _reports_by_status(self) -> list[dict[str, Any]]:
        q = (
            select(Report.status, func.count())
            .where(Report.is_deleted.is_(False))
            .group_by(Report.status)
            .order_by(func.count().desc())
        )
        r = await self._db.execute(q)
        return [{"status": s or "unknown", "count": int(c)} for s, c in r.all()]
