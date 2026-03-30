"""
Send pushes via Firebase Cloud Messaging.

- Preferred: Firebase Admin SDK [messaging.send] (HTTP v1) using [FIREBASE_CREDENTIALS_PATH].
- Optional: legacy HTTP API if [FCM_SERVER_KEY] is set.

Celery workers call [ensure_firebase_initialized] on process start (see tasks/celery_app.py).
"""
from __future__ import annotations

import asyncio
import logging
from typing import Any

import httpx
from firebase_admin import messaging

from app.core.config import settings
from app.core.firebase import ensure_firebase_initialized, firebase_credentials_resolvable

logger = logging.getLogger(__name__)

FCM_LEGACY_URL = "https://fcm.googleapis.com/fcm/send"


def _legacy_fcm_server_key_usable() -> bool:
    """
    Legacy FCM expects a single-line server key, not a PEM private key.
    Putting service-account private key in FCM_SERVER_KEY breaks HTTP headers
    (Illegal header value b'key=-----BEGIN PRIVATE...').
    """
    key = settings.FCM_SERVER_KEY.strip()
    if not key:
        return False
    if "BEGIN" in key or "\n" in key or "\r" in key:
        logger.warning(
            "[FCM] FCM_SERVER_KEY looks like a PEM/private key, not a legacy server key; "
            "use serviceAccountKey.json (Admin SDK) or the real Cloud Messaging server key",
        )
        return False
    return True


def _stringify_data(data: dict[str, Any]) -> dict[str, str]:
    """FCM `data` payload values must be strings."""
    return {str(k): str(v) for k, v in data.items() if v is not None}


def fcm_delivery_configured() -> bool:
    if firebase_credentials_resolvable():
        return True
    return _legacy_fcm_server_key_usable()


def send_fcm_admin_sdk_sync(
    *,
    to_token: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> tuple[bool, str]:
    token_hint = f"{to_token[:12]}…" if len(to_token) > 12 else to_token
    logger.info(
        "[FCM] admin SDK send token_hint=%s title=%r data_keys=%s",
        token_hint,
        title,
        list((data or {}).keys()),
    )
    try:
        ensure_firebase_initialized()
    except Exception as e:
        logger.error("[FCM] Firebase init failed: %s", e)
        return False, f"Firebase init failed: {e}"

    data_map = _stringify_data(data or {})
    if data_map:
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data_map,
            token=to_token,
        )
    else:
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=to_token,
        )
    try:
        message_id = messaging.send(msg)
        logger.info("[FCM] admin SDK ok token_hint=%s message_id=%s", token_hint, message_id)
        return True, str(message_id)
    except Exception as e:
        logger.warning("[FCM] admin SDK send failed token_hint=%s: %s", token_hint, e)
        return False, str(e)


def send_fcm_single_sync(
    *,
    to_token: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> tuple[bool, str]:
    # Prefer Admin SDK when JSON exists so a mistaken PEM in FCM_SERVER_KEY does not win.
    if firebase_credentials_resolvable():
        return send_fcm_admin_sdk_sync(
            to_token=to_token, title=title, body=body, data=data,
        )
    if _legacy_fcm_server_key_usable():
        return send_fcm_legacy_sync(
            to_token=to_token, title=title, body=body, data=data,
        )
    logger.error(
        "[FCM] not configured: add service account JSON (FIREBASE_CREDENTIALS_PATH) "
        "or set FCM_SERVER_KEY to the legacy server key (not the private_key from JSON)",
    )
    return False, "FCM not configured"


async def send_fcm_single_async(
    *,
    to_token: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> tuple[bool, str]:
    if firebase_credentials_resolvable():
        return await asyncio.to_thread(
            send_fcm_admin_sdk_sync,
            to_token=to_token,
            title=title,
            body=body,
            data=data,
        )
    if _legacy_fcm_server_key_usable():
        return await send_fcm_legacy_async(
            to_token=to_token, title=title, body=body, data=data,
        )
    return False, "FCM not configured"


async def send_fcm_legacy(
    *,
    to_token: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> tuple[bool, str]:
    """Send via legacy server key or Admin SDK depending on configuration."""
    return await send_fcm_single_async(
        to_token=to_token, title=title, body=body, data=data,
    )


async def send_fcm_legacy_async(
    *,
    to_token: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> tuple[bool, str]:
    key = settings.FCM_SERVER_KEY.strip()
    if not key:
        return False, "FCM_SERVER_KEY is not configured"

    payload: dict[str, Any] = {
        "to": to_token,
        "notification": {"title": title, "body": body},
        "data": _stringify_data(data or {}),
    }
    headers = {
        "Authorization": f"key={key}",
        "Content-Type": "application/json",
    }
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(FCM_LEGACY_URL, json=payload, headers=headers)
    except httpx.HTTPError as e:
        logger.warning("FCM HTTP error: %s", e)
        return False, str(e)

    if resp.status_code >= 400:
        logger.warning("FCM error %s: %s", resp.status_code, resp.text[:500])
        return False, resp.text or f"HTTP {resp.status_code}"

    try:
        j = resp.json()
    except Exception:
        return True, "sent"
    if j.get("failure", 0) and j.get("results"):
        err = j["results"][0].get("error", "unknown")
        return False, str(err)
    return True, "sent"


def send_fcm_legacy_sync(
    *,
    to_token: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> tuple[bool, str]:
    """Legacy HTTP API only (caller must ensure FCM_SERVER_KEY is set)."""
    token_hint = f"{to_token[:12]}…" if len(to_token) > 12 else to_token
    logger.info(
        "[FCM http] legacy send start token_hint=%s title=%r data_keys=%s",
        token_hint,
        title,
        list((data or {}).keys()),
    )
    key = settings.FCM_SERVER_KEY.strip()
    if not key:
        logger.error("[FCM http] abort: FCM_SERVER_KEY is empty")
        return False, "FCM_SERVER_KEY is not configured"

    payload: dict[str, Any] = {
        "to": to_token,
        "notification": {"title": title, "body": body},
        "data": _stringify_data(data or {}),
    }
    headers = {
        "Authorization": f"key={key}",
        "Content-Type": "application/json",
    }
    try:
        with httpx.Client(timeout=30.0) as client:
            resp = client.post(FCM_LEGACY_URL, json=payload, headers=headers)
    except httpx.HTTPError as e:
        logger.warning("[FCM http] request exception token_hint=%s err=%s", token_hint, e)
        return False, str(e)

    body_snip = (resp.text or "")[:400].replace("\n", " ")
    logger.info(
        "[FCM http] response token_hint=%s status=%s body_snip=%s",
        token_hint,
        resp.status_code,
        body_snip,
    )

    if resp.status_code >= 400:
        logger.warning("FCM error %s: %s", resp.status_code, resp.text[:500])
        return False, resp.text or f"HTTP {resp.status_code}"

    try:
        j = resp.json()
    except Exception:
        logger.info("[FCM http] non-JSON success body token_hint=%s", token_hint)
        return True, "sent"
    failure_n = j.get("failure", 0)
    success_n = j.get("success", 0)
    logger.info(
        "[FCM http] parsed JSON token_hint=%s success=%s failure=%s multicast_id=%s",
        token_hint,
        success_n,
        failure_n,
        j.get("multicast_id"),
    )
    if failure_n and j.get("results"):
        err = j["results"][0].get("error", "unknown")
        logger.warning("[FCM http] FCM reported failure token_hint=%s error=%s", token_hint, err)
        return False, str(err)
    return True, "sent"


def send_fcm_to_tokens_sync(
    tokens: list[str],
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> list[tuple[str, bool, str]]:
    """Blocking send per token (Admin SDK or legacy)."""
    out: list[tuple[str, bool, str]] = []
    for t in tokens:
        ok, msg = send_fcm_single_sync(
            to_token=t, title=title, body=body, data=data,
        )
        prefix = t[:16] + "…" if len(t) > 16 else t
        out.append((prefix, ok, msg))
    return out


async def send_fcm_to_user_devices(
    tokens: list[str],
    *,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> list[tuple[str, bool, str]]:
    """Send the same message to each device token; returns per-token outcomes."""
    out: list[tuple[str, bool, str]] = []
    for t in tokens:
        ok, msg = await send_fcm_single_async(
            to_token=t, title=title, body=body, data=data,
        )
        out.append((t[:16] + "…", ok, msg))
    return out
