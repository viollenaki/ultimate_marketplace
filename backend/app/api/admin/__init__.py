"""Admin API (read-only analytics & moderation; secure at network layer if needed)."""
from fastapi import APIRouter

from app.api.admin.analytics import router as analytics_router
from app.api.admin.listings_admin import router as listings_admin_router
from app.api.admin.reports import router as reports_router

api_router = APIRouter()
api_router.include_router(analytics_router, prefix="/analytics", tags=["admin-analytics"])
api_router.include_router(reports_router, prefix="/reports", tags=["admin-reports"])
api_router.include_router(listings_admin_router, prefix="/listings", tags=["admin-listings"])
