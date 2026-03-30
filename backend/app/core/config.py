"""
Application configuration settings.
"""
import json
import os
import secrets
from typing import List, Set

from pydantic import Field, computed_field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore",
    )

    # API settings (include_router prefix). Empty .env value would mount routes at /listings/...
    # while clients call /api/v1/listings/... → 404.
    API_V1_STR: str = "/api/v1"

    @field_validator("API_V1_STR", mode="before")
    @classmethod
    def _normalize_api_v1_str(cls, v: object) -> str:
        if v is None:
            return "/api/v1"
        s = str(v).strip()
        if not s:
            return "/api/v1"
        if not s.startswith("/"):
            s = f"/{s}"
        return s.rstrip("/") or "/api/v1"
    SECRET_KEY: str = os.getenv("SECRET_KEY", secrets.token_urlsafe(32))

    # CORS: load as string from .env (comma-separated or JSON array), expose as list
    cors_origins_raw: str = Field(
        default="http://localhost:8000,http://localhost:3000",
        validation_alias="CORS_ORIGINS",
    )

    @computed_field
    @property
    def CORS_ORIGINS(self) -> List[str]:
        s = self.cors_origins_raw.strip()
        if s.startswith("["):
            return json.loads(s)
        return [i.strip() for i in s.split(",") if i.strip()]

    # Project metadata
    PROJECT_NAME: str = "FastAPI App"
    PROJECT_DESCRIPTION: str = "FastAPI application with MySQL and redis"
    VERSION: str = "0.1.0"

    # Database settings (async MySQL: mysql+aiomysql://user:pass@host:port/dbname)
    # In Docker Compose use host `db`; on the host machine use 127.0.0.1
    DATABASE_URL: str = Field(
        default="mysql+aiomysql://root:1234@db:3306/ultimate_marketplace",
    )

    # Celery settings
    CELERY_BROKER_URL: str = os.getenv("CELERY_BROKER_URL", "redis://redis:6379/0")
    CELERY_RESULT_BACKEND: str = os.getenv("CELERY_RESULT_BACKEND", "redis://redis:6379/0")

    # Elasticsearch (Docker: http://elasticsearch:9200; host machine: http://127.0.0.1:9200)
    ELASTICSEARCH_URL: str = Field(
        default="http://elasticsearch:9200",
    )
    ELASTICSEARCH_LISTINGS_INDEX: str = Field(
        default="marketplace_listings",
        description="Index name for listing search / filters",
    )

    # Firebase Admin (service account JSON path, relative to cwd or absolute)
    FIREBASE_CREDENTIALS_PATH: str = Field(default="serviceAccountKey.json")
    # Default bucket id (no gs://). Console: Storage → bucket name, often *.firebasestorage.app
    FIREBASE_STORAGE_BUCKET: str = Field(
        default="ultimate-marketplace-f16c9.firebasestorage.app",
    )
    # Max listing image upload size (bytes)
    LISTING_MEDIA_MAX_BYTES: int = Field(default=10 * 1024 * 1024)

    # Custom JWT (API access after Firebase login)
    JWT_ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24)

    # Legacy FCM HTTP API server key (optional; token registration still works without it)
    FCM_SERVER_KEY: str = Field(default="")
    # FCM HTTP v1 via service account (when FCM_SERVER_KEY unset). Use JSON file and/or:
    FCM_PROJECT_ID: str = Field(default="")
    FCM_CLIENT_EMAIL: str = Field(default="")
    # PEM; in .env use \n for newlines
    FCM_PRIVATE_KEY: str = Field(default="")

    # Admin API (`/admin/...`) is unauthenticated in app code; restrict at the edge if needed.
    # Retained for compatibility; not read by `require_admin_access`.
    ADMIN_ACCESS_KEY: str = Field(default="")
    ADMIN_EMAILS: str = Field(
        default="",
        description="Unused for `/admin` in current code (legacy allowlist helper).",
    )

    @computed_field
    @property
    def admin_email_allowlist(self) -> Set[str]:
        return {
            e.strip().lower()
            for e in self.ADMIN_EMAILS.split(",")
            if e.strip()
        }

# Create settings instance
settings = Settings()
