"""
API v1 routes.
"""
from fastapi import APIRouter

from app.api.v1.health import router as health_router

# Create API v1 router
api_router = APIRouter()

# Include health router
api_router.include_router(health_router, tags=["health"])
