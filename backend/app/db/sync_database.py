"""
Synchronous SQLAlchemy engine/session for Celery workers and other blocking contexts.

FastAPI uses [app.db.database] (async). Workers use this module.
"""
from __future__ import annotations

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings


def get_sync_database_url() -> str:
    """Match Alembic: aiomysql URL → pymysql for sync drivers."""
    url = settings.DATABASE_URL
    if url.startswith("mysql+aiomysql://"):
        url = "mysql+pymysql://" + url.removeprefix("mysql+aiomysql://")
    if url.startswith("mysql+pymysql://") and "charset=" not in url:
        url = f"{url}{'&' if '?' in url else '?'}charset=utf8mb4"
    return url


_connect_args: dict = {}
_engine_kwargs: dict = {
    "echo": False,
    "future": True,
    "pool_pre_ping": True,
}
if "mysql" in settings.DATABASE_URL:
    _engine_kwargs["pool_recycle"] = 3600
    _connect_args["charset"] = "utf8mb4"

sync_engine = create_engine(
    get_sync_database_url(),
    connect_args=_connect_args,
    **_engine_kwargs,
)

SyncSessionLocal = sessionmaker(
    bind=sync_engine,
    autoflush=False,
    expire_on_commit=False,
)
