"""
Application configuration settings.
"""
import json
import os
import secrets
from typing import List

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)

    # API settings
    API_V1_STR: str = "/api/v1"
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


# Create settings instance
settings = Settings()
