"""
API v1 routes — REST-style resources under /api/v1.
"""
from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.conversations import router as conversations_router
from app.api.v1.devices import router as devices_router
from app.api.v1.favorites import router as favorites_router
from app.api.v1.health import router as health_router
from app.api.v1.listings import router as listings_router
from app.api.v1.users import router as users_router

api_router = APIRouter()

api_router.include_router(health_router, tags=["health"])
api_router.include_router(users_router, prefix="/users", tags=["users"])
api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(devices_router, prefix="/devices", tags=["devices"])
api_router.include_router(listings_router, prefix="/listings", tags=["listings"])
api_router.include_router(favorites_router, prefix="/favorites", tags=["favorites"])
api_router.include_router(
    conversations_router,
    prefix="/conversations",
    tags=["conversations"],
)
