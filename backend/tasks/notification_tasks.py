"""
FCM push delivery in the Celery worker (blocking I/O to Firebase).

API routes should enqueue tasks via [app.services.push_notification_queue]; do not call
FCM HTTP from request handlers for bulk or slow sends.
"""
from __future__ import annotations

from typing import Any

from celery.utils.log import get_task_logger

from app.db.sync_database import SyncSessionLocal
from app.repositories.user_fcm_token_repository import UserFcmTokenRepository
from app.services.fcm_send_service import (
    fcm_delivery_configured,
    send_fcm_to_tokens_sync,
)

from tasks.celery_app import celery_app

logger = get_task_logger(__name__)


@celery_app.task(name="tasks.send_fcm_to_user")
def send_fcm_to_user_task(
    user_id: int,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """
    Load all FCM tokens for [user_id] and send the same notification to each device.

    [data] is merged into the FCM `data` map (values stringified by fcm_send_service).
    """
    payload = data or {}
    logger.info(
        "[FCM worker] send_fcm_to_user_task START user_id=%s title=%r body_len=%s data=%s",
        user_id,
        title,
        len(body or ""),
        payload,
    )
    delivery_ok = fcm_delivery_configured()
    logger.info(
        "[FCM worker] delivery_configured=%s (Admin JSON and/or usable legacy FCM_SERVER_KEY)",
        delivery_ok,
    )
    if not delivery_ok:
        logger.warning(
            "[FCM worker] FCM not configured: set FCM_SERVER_KEY or add "
            "service account JSON (FIREBASE_CREDENTIALS_PATH / serviceAccountKey.json)",
        )

    with SyncSessionLocal() as session:
        tokens = UserFcmTokenRepository.list_tokens_for_user_sync(session, user_id)

    logger.info(
        "[FCM worker] DB tokens for user_id=%s count=%s",
        user_id,
        len(tokens),
    )
    for i, tok in enumerate(tokens):
        logger.info(
            "[FCM worker]   token[%s] prefix=%s… len=%s",
            i,
            tok[:12] if len(tok) > 12 else tok,
            len(tok),
        )

    if not tokens:
        logger.warning(
            "[FCM worker] send_fcm_to_user_task SKIP no tokens for user_id=%s",
            user_id,
        )
        return {
            "user_id": user_id,
            "ok": True,
            "skipped": True,
            "reason": "no_tokens",
            "results": [],
        }

    results = send_fcm_to_tokens_sync(
        tokens,
        title=title,
        body=body,
        data=payload,
    )
    sent = sum(1 for _, ok, _ in results if ok)
    for prefix, ok, detail in results:
        if ok:
            logger.info(
                "[FCM worker] send OK token_prefix=%s detail=%s",
                prefix,
                detail,
            )
        else:
            logger.warning(
                "[FCM worker] send FAIL token_prefix=%s detail=%s",
                prefix,
                detail,
            )
    logger.info(
        "[FCM worker] send_fcm_to_user_task DONE user_id=%s devices=%s sent_ok=%s failed=%s",
        user_id,
        len(tokens),
        sent,
        len(tokens) - sent,
    )
    return {
        "user_id": user_id,
        "ok": True,
        "skipped": False,
        "devices": len(tokens),
        "sent_ok": sent,
        "results": [{"token_prefix": a, "ok": b, "detail": c} for a, b, c in results],
    }


@celery_app.task(name="tasks.send_fcm_to_tokens")
def send_fcm_to_tokens_task(
    tokens: list[str],
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """
    Send to an explicit token list (e.g. after resolving recipients in the API).
    Keep payloads small; prefer [send_fcm_to_user_task] when possible.
    """
    if not tokens:
        logger.warning("[FCM worker] send_fcm_to_tokens_task SKIP empty token list")
        return {"ok": True, "skipped": True, "reason": "empty_tokens", "results": []}
    logger.info(
        "[FCM worker] send_fcm_to_tokens_task START count=%s title=%r delivery_configured=%s",
        len(tokens),
        title,
        fcm_delivery_configured(),
    )
    results = send_fcm_to_tokens_sync(
        tokens,
        title=title,
        body=body,
        data=data or {},
    )
    sent = sum(1 for _, ok, _ in results if ok)
    for prefix, ok, detail in results:
        log_fn = logger.info if ok else logger.warning
        log_fn(
            "[FCM worker] token_prefix=%s ok=%s detail=%s",
            prefix,
            ok,
            detail,
        )
    logger.info(
        "[FCM worker] send_fcm_to_tokens_task DONE sent_ok=%s failed=%s",
        sent,
        len(tokens) - sent,
    )
    return {
        "ok": True,
        "devices": len(tokens),
        "sent_ok": sent,
        "results": [{"token_prefix": a, "ok": b, "detail": c} for a, b, c in results],
    }
