"""
Celery application configuration.
"""
import logging
import os

from celery import Celery
from celery.signals import worker_process_init

# Load environment variables from .env file
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

# Use environment variables with defaults
broker_url = os.getenv("CELERY_BROKER_URL", "redis://redis:6379/0")
result_backend = os.getenv("CELERY_RESULT_BACKEND", "redis://redis:6379/0")

# Create Celery app
celery_app = Celery(
    "tasks",
    broker=broker_url,
    backend=result_backend,
    include=["tasks.sample_tasks", "tasks.notification_tasks"],
)

# Optional configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=50,
)


@worker_process_init.connect
def _celery_worker_init_firebase(**_kwargs: object) -> None:
    """Initialize Firebase Admin once per forked worker process (FCM uses messaging API)."""
    try:
        from app.core.firebase import ensure_firebase_initialized

        ensure_firebase_initialized()
    except Exception as e:
        logger.warning(
            "Celery worker: Firebase Admin init skipped (%s); "
            "FCM via SDK needs FIREBASE_CREDENTIALS_PATH / serviceAccountKey.json",
            e,
        )


if __name__ == "__main__":
    celery_app.start()
