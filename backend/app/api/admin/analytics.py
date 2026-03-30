"""
Admin analytics: focused endpoints + combined dashboard.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.services.admin_analytics_service import AdminAnalyticsService

router = APIRouter()


@router.get(
    "/dashboard",
    summary="All-in-one dashboard (overview, timeseries, breakdowns)",
)
async def analytics_dashboard(
    days: int = Query(30, ge=7, le=366, description="Days for timeseries windows"),
    db: AsyncSession = Depends(get_db),
):
    service = AdminAnalyticsService(db)
    return await service.dashboard(days=days)


@router.get(
    "/overview",
    summary="KPI counts only (users, listings, messages, payments, reports)",
)
async def analytics_overview(
    db: AsyncSession = Depends(get_db),
):
    service = AdminAnalyticsService(db)
    return await service.overview_only()


@router.get(
    "/timeseries",
    summary="Daily series: listings, users, messages, payment volume",
)
async def analytics_timeseries(
    days: int = Query(30, ge=7, le=366),
    db: AsyncSession = Depends(get_db),
):
    service = AdminAnalyticsService(db)
    return await service.timeseries_only(days=days)


@router.get(
    "/listings",
    summary="Listings breakdown: by status, city, brand",
)
async def analytics_listings_breakdown(
    db: AsyncSession = Depends(get_db),
):
    service = AdminAnalyticsService(db)
    return await service.listings_breakdown()


@router.get(
    "/payments",
    summary="Payments: by status, successful totals, daily successful volume",
)
async def analytics_payments(
    days: int = Query(30, ge=7, le=366),
    db: AsyncSession = Depends(get_db),
):
    service = AdminAnalyticsService(db)
    return await service.payments_analytics(days=days)


@router.get(
    "/reports",
    summary="Reports: totals, pending count, by status",
)
async def analytics_reports(
    db: AsyncSession = Depends(get_db),
):
    service = AdminAnalyticsService(db)
    return await service.reports_summary()


@router.get(
    "/engagement",
    summary="Engagement totals: messages, conversations, favorites",
)
async def analytics_engagement(
    db: AsyncSession = Depends(get_db),
):
    service = AdminAnalyticsService(db)
    return await service.engagement_summary()
