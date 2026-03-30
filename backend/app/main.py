"""
FastAPI application entry point.
"""
import asyncio
import logging

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.admin import api_router as admin_api_router
from app.api.v1 import api_router
from app.core.config import settings
from app.core.elasticsearch_client import close_async_elasticsearch, get_async_elasticsearch
from app.services.listing_search_service import ensure_listings_index_async
from app.core.request_log_middleware import RequestLogMiddleware
from app.db.database import init_db
from app.realtime.redis_chat_bridge import (
    start_chat_redis_listener,
    stop_chat_redis_listener,
    wait_chat_redis_subscribed,
)

# Configure logging (stdout → visible in `docker compose logs -f app`)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logging.getLogger("uvicorn.access").setLevel(logging.INFO)
logging.getLogger("uvicorn.error").setLevel(logging.INFO)
logger = logging.getLogger(__name__)


def create_application() -> FastAPI:
    """Create and configure the FastAPI application."""
    application = FastAPI(
        title=settings.PROJECT_NAME,
        description=settings.PROJECT_DESCRIPTION,
        version=settings.VERSION,
        docs_url=f"{settings.API_V1_STR}/docs",
        redoc_url=f"{settings.API_V1_STR}/redoc",
        openapi_url=f"{settings.API_V1_STR}/openapi.json",
    )
    
    # Set up CORS
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    # Last added = outermost: logs every request after routing/CORS with status + timing
    application.add_middleware(RequestLogMiddleware)

    # Include API router
    application.include_router(api_router, prefix=settings.API_V1_STR)
    application.include_router(admin_api_router, prefix="/admin")

    fav_paths = [
        getattr(r, "path", "")
        for r in application.routes
        if "favorite" in getattr(r, "path", "")
    ]
    logger.info("Routes under %s containing 'favorite': %s", settings.API_V1_STR, fav_paths)

    @application.exception_handler(HTTPException)
    async def http_exception_handler(_request, exc: HTTPException):
        detail = exc.detail
        if isinstance(detail, dict) and detail.get("success") is False:
            return JSONResponse(status_code=exc.status_code, content=detail)
        if isinstance(detail, dict):
            return JSONResponse(
                status_code=exc.status_code,
                content={"success": False, "error": detail.get("message", str(detail))},
            )
        return JSONResponse(
            status_code=exc.status_code,
            content={"success": False, "error": str(detail)},
        )
    
    @application.on_event("startup")
    async def startup_event():
        """Initialize resources on startup."""
        logger.info("Starting up application...")
        logger.info("REST routes mounted under prefix %r", settings.API_V1_STR)
        fav_count = sum(
            1
            for r in application.routes
            if getattr(r, "path", "").startswith(f"{settings.API_V1_STR}/favorites")
        )
        if fav_count == 0:
            logger.error(
                "Startup check: expected /favorites routes under %s — got 0. "
                "Clients will see 404 on /favorites/*. Rebuild/restart the app container.",
                settings.API_V1_STR,
            )
        else:
            logger.info("Startup check: %d route(s) under %s/favorites", fav_count, settings.API_V1_STR)
        await init_db()
        es = get_async_elasticsearch()
        if not await es.ping():
            logger.warning("Elasticsearch ping failed; check ELASTICSEARCH_URL")
        else:
            logger.info("Elasticsearch connection OK")
            try:
                await ensure_listings_index_async(es)
            except Exception as e:
                logger.warning("Could not ensure listings index: %s", e)
        start_chat_redis_listener()

        async def _log_chat_redis_readiness() -> None:
            if await wait_chat_redis_subscribed(timeout=15.0):
                logger.info("Chat Redis fan-out subscriber is ready")
            else:
                logger.warning(
                    "Chat Redis subscriber not ready in 15s (is Redis up?). "
                    "Multi-worker realtime chat may miss events until it connects."
                )

        asyncio.create_task(_log_chat_redis_readiness())
    
    @application.on_event("shutdown")
    async def shutdown_event():
        """Clean up resources on shutdown."""
        logger.info("Shutting down application...")
        await stop_chat_redis_listener()
        await close_async_elasticsearch()
    
    return application


app = create_application()


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
