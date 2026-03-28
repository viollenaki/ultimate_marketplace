"""
Health check endpoints.
"""
import logging

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.db.database import get_db

logger = logging.getLogger(__name__)
router = APIRouter()


class HealthResponse(BaseModel):
    """Health check response model."""
    
    status: str
    version: str


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint.
    
    Returns:
        HealthResponse: Health check response
    """
    logger.info("GET /health — liveness check")
    return {
        "status": "ok",
        "version": "0.1.0",
    }


@router.get("/health/db", response_model=HealthResponse)
async def db_health_check(db=Depends(get_db)):
    """
    Database health check endpoint.
    
    Args:
        db: Database session
    
    Returns:
        HealthResponse: Health check response
    """
    logger.info("GET /health/db — database session acquired, returning ok")
    return {
        "status": "ok",
        "version": "0.1.0",
    }
