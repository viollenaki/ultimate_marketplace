"""
FastAPI application entry point.
"""
import logging

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1 import api_router
from app.core.config import settings
from app.core.elasticsearch_client import close_async_elasticsearch, get_async_elasticsearch
from app.db.database import init_db

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
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
    
    # Include API router
    application.include_router(api_router, prefix=settings.API_V1_STR)

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
        await init_db()
        es = get_async_elasticsearch()
        if not await es.ping():
            logger.warning("Elasticsearch ping failed; check ELASTICSEARCH_URL")
        else:
            logger.info("Elasticsearch connection OK")
    
    @application.on_event("shutdown")
    async def shutdown_event():
        """Clean up resources on shutdown."""
        logger.info("Shutting down application...")
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
