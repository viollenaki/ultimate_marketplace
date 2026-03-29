"""
Database connection and session management.
"""
import asyncio
import logging
import os
from pathlib import Path
from typing import AsyncGenerator

from alembic import command
from alembic.config import Config
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

logger = logging.getLogger(__name__)


def _alembic_config() -> Config:
    backend_root = Path(__file__).resolve().parents[2]
    return Config(str(backend_root / "alembic.ini"))


def run_alembic_upgrade() -> None:
    """Apply migrations to head (sync driver). For local/CI use; Docker app uses entrypoint."""
    command.upgrade(_alembic_config(), "head")

_engine_kwargs: dict = {
    "echo": False,
    "future": True,
    "pool_pre_ping": True,
}
_connect_args: dict = {}
if "mysql" in settings.DATABASE_URL:
    _engine_kwargs["pool_recycle"] = 3600
    # Google names / URLs often need full Unicode; avoid "Incorrect string value" on insert.
    _connect_args["charset"] = "utf8mb4"

# Create async engine
engine = create_async_engine(
    settings.DATABASE_URL,
    connect_args=_connect_args,
    **_engine_kwargs,
)

# Create async session factory
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Get database session.
    
    Yields:
        AsyncSession: Database session
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db() -> None:
    """Verify async DB connectivity.

    Migrations are not run here: Gunicorn runs multiple workers, and parallel Alembic
    upgrades race on MySQL DDL. Docker runs `alembic upgrade head` once in
    docker-entrypoint.sh before workers start. For local `uvicorn`, run:
    `alembic upgrade head` from the backend directory.
    """
    if os.environ.get("RUN_ALEMBIC_ON_STARTUP") == "1":
        await asyncio.to_thread(run_alembic_upgrade)
        logger.info("Database migrations applied (Alembic upgrade head)")
    try:
        async with engine.begin() as conn:
            await conn.run_sync(lambda _: None)
        logger.info("Database connection established")
    except Exception as e:
        logger.error("Database initialization failed: %s", e)
        raise
