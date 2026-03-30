"""
Redis-backed presence: user has an open WebSocket for a given conversation.

Used to skip FCM when the recipient is already in the chat (see ChatService.send_message).
TTL refreshes while the socket stays connected.
"""
from __future__ import annotations

import logging

import redis.asyncio as redis

from app.core.config import settings

logger = logging.getLogger(__name__)

PRESENCE_KEY_PREFIX = "um:chat:presence:"
DEFAULT_TTL_SECONDS = 90


def _key(conversation_id: int, user_id: int) -> str:
    return f"{PRESENCE_KEY_PREFIX}{conversation_id}:{user_id}"


async def refresh_chat_presence(
    conversation_id: int,
    user_id: int,
    *,
    ttl_seconds: int = DEFAULT_TTL_SECONDS,
) -> None:
    client = redis.from_url(settings.CELERY_BROKER_URL, decode_responses=True)
    try:
        await client.set(_key(conversation_id, user_id), "1", ex=ttl_seconds)
    except Exception as e:
        logger.debug("refresh_chat_presence failed: %s", e)
    finally:
        await client.aclose()


async def clear_chat_presence(conversation_id: int, user_id: int) -> None:
    client = redis.from_url(settings.CELERY_BROKER_URL, decode_responses=True)
    try:
        await client.delete(_key(conversation_id, user_id))
    except Exception as e:
        logger.debug("clear_chat_presence failed: %s", e)
    finally:
        await client.aclose()


async def is_user_active_in_conversation(conversation_id: int, user_id: int) -> bool:
    """
    True if this user recently refreshed presence for this conversation
    (open chat WebSocket with heartbeat).
    """
    client = redis.from_url(settings.CELERY_BROKER_URL, decode_responses=True)
    try:
        v = await client.get(_key(conversation_id, user_id))
        return v is not None
    except Exception as e:
        logger.warning(
            "is_user_active_in_conversation Redis error (treating as active, skip FCM): %s",
            e,
        )
        return True
    finally:
        await client.aclose()
