"""In-memory WebSocket rooms keyed by conversation_id (single-process)."""

from __future__ import annotations

import asyncio
import logging
from collections import defaultdict
from typing import Any

from fastapi import WebSocket

logger = logging.getLogger(__name__)

_lock = asyncio.Lock()
_room_sockets: dict[int, list[WebSocket]] = defaultdict(list)


async def subscribe(conversation_id: int, websocket: WebSocket) -> None:
    async with _lock:
        _room_sockets[conversation_id].append(websocket)


async def unsubscribe(conversation_id: int, websocket: WebSocket) -> None:
    async with _lock:
        room = _room_sockets.get(conversation_id)
        if not room:
            return
        if websocket in room:
            room.remove(websocket)
        if not room:
            del _room_sockets[conversation_id]


async def deliver_to_local_websockets(
    conversation_id: int, payload: dict[str, Any],
) -> None:
    """Send JSON to all WebSockets for this room in *this* worker process only."""
    async with _lock:
        sockets = list(_room_sockets.get(conversation_id, []))
    stale: list[WebSocket] = []
    for ws in sockets:
        try:
            await ws.send_json(payload)
        except Exception as e:
            logger.debug("WS send failed, dropping socket: %s", e)
            stale.append(ws)
    if stale:
        async with _lock:
            room = _room_sockets.get(conversation_id)
            if not room:
                return
            for ws in stale:
                if ws in room:
                    room.remove(ws)
            if not room:
                del _room_sockets[conversation_id]


async def broadcast_to_conversation(conversation_id: int, payload: dict[str, Any]) -> None:
    """
    Notify every client in the conversation. With Gunicorn + multiple Uvicorn workers,
    in-memory rooms are per process; we publish via Redis so each worker fans out locally.
    """
    try:
        from app.realtime.redis_chat_bridge import publish_chat_broadcast

        await publish_chat_broadcast(conversation_id, payload)
    except Exception as e:
        logger.warning(
            "Redis chat broadcast failed (%s); delivering only on this worker",
            e,
        )
        await deliver_to_local_websockets(conversation_id, payload)
