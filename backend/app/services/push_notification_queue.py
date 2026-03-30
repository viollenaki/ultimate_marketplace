"""
Queue FCM work to Celery. Import this from FastAPI code; workers run [tasks.notification_tasks].
"""
from __future__ import annotations

import logging
from typing import Any

logger = logging.getLogger(__name__)


def enqueue_fcm_to_user(
    user_id: int,
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> str:
    """Schedule push to all devices registered for the user. Returns Celery task id."""
    from tasks.notification_tasks import send_fcm_to_user_task

    async_result = send_fcm_to_user_task.delay(user_id, title, body, data)
    logger.info(
        "[FCM enqueue] send_fcm_to_user queued user_id=%s celery_task_id=%s title=%r body_len=%s data_keys=%s",
        user_id,
        async_result.id,
        title,
        len(body or ""),
        list((data or {}).keys()),
    )
    return async_result.id


def enqueue_fcm_to_tokens(
    tokens: list[str],
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> str:
    """Schedule push to specific FCM registration tokens. Returns Celery task id."""
    from tasks.notification_tasks import send_fcm_to_tokens_task

    async_result = send_fcm_to_tokens_task.delay(tokens, title, body, data)
    logger.info(
        "[FCM enqueue] send_fcm_to_tokens queued token_count=%s celery_task_id=%s title=%r",
        len(tokens),
        async_result.id,
        title,
    )
    return async_result.id
