"""
Cross-worker chat fan-out via Redis pub/sub.

Each Gunicorn worker keeps WebSockets only in its own process. [broadcast_to_conversation]
publishes one event to Redis; every worker (including the publisher) receives it and calls
[deliver_to_local_websockets] for that conversation_id.
"""
from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

import redis.asyncio as redis

from app.core.config import settings
from app.realtime.connection_manager import deliver_to_local_websockets

logger = logging.getLogger(__name__)

CHAT_BROADCAST_CHANNEL = "um:chat:broadcast"

_listener_task: asyncio.Task[None] | None = None
_subscribed: asyncio.Event | None = None


def _ready_event() -> asyncio.Event:
    global _subscribed
    if _subscribed is None:
        _subscribed = asyncio.Event()
    return _subscribed


async def wait_chat_redis_subscribed(*, timeout: float = 15.0) -> bool:
    """Block until this worker's listener has subscribed (avoids lost first messages)."""
    try:
        await asyncio.wait_for(_ready_event().wait(), timeout=timeout)
        return True
    except (asyncio.TimeoutError, asyncio.CancelledError):
        return False


async def publish_chat_broadcast(conversation_id: int, payload: dict[str, Any]) -> None:
    body = json.dumps(
        {"conversation_id": conversation_id, "payload": payload},
        default=str,
    )
    client = redis.from_url(settings.CELERY_BROKER_URL, decode_responses=True)
    try:
        n = await client.publish(CHAT_BROADCAST_CHANNEL, body)
        if n == 0:
            logger.debug(
                "chat publish: no Redis subscribers (yet) for %s",
                CHAT_BROADCAST_CHANNEL,
            )
    finally:
        await client.aclose()


async def _listener_loop() -> None:
    client = redis.from_url(settings.CELERY_BROKER_URL, decode_responses=True)
    pubsub = client.pubsub()
    try:
        await pubsub.subscribe(CHAT_BROADCAST_CHANNEL)
        _ready_event().set()
        logger.info("Subscribed to Redis channel %r for chat fan-out", CHAT_BROADCAST_CHANNEL)
        async for message in pubsub.listen():
            if message["type"] != "message":
                continue
            raw = message.get("data")
            if not isinstance(raw, str):
                continue
            try:
                data = json.loads(raw)
                cid = int(data["conversation_id"])
                payload = data["payload"]
                if not isinstance(payload, dict):
                    continue
                await deliver_to_local_websockets(cid, payload)
            except Exception as e:
                logger.warning("Chat broadcast message dropped: %s", e)
    except asyncio.CancelledError:
        raise
    except Exception:
        logger.exception("Redis chat listener stopped with error")
        raise
    finally:
        try:
            await pubsub.unsubscribe(CHAT_BROADCAST_CHANNEL)
        except Exception:
            pass
        try:
            await pubsub.aclose()
        except Exception:
            pass
        await client.aclose()


async def _listener_supervisor() -> None:
    backoff = 2.0
    while True:
        try:
            await _listener_loop()
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.warning("Chat Redis listener will restart in %.0fs: %s", backoff, e)
            await asyncio.sleep(backoff)
            backoff = min(backoff * 1.5, 30.0)


def start_chat_redis_listener() -> None:
    global _listener_task, _subscribed
    if _listener_task is not None and not _listener_task.done():
        return
    _subscribed = asyncio.Event()
    _listener_task = asyncio.create_task(_listener_supervisor())


async def stop_chat_redis_listener() -> None:
    global _listener_task, _subscribed
    if _listener_task is None:
        return
    _listener_task.cancel()
    try:
        await _listener_task
    except asyncio.CancelledError:
        pass
    _listener_task = None
    _subscribed = None
