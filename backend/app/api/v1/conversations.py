"""
Conversations & messages: REST + WebSocket realtime (JWT via `token` query param).
"""

from __future__ import annotations

import asyncio
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_user, resolve_access_token_user
from app.core.exceptions import AppException
from app.db.database import AsyncSessionLocal, get_db
from app.models import User
from app.realtime.chat_presence import clear_chat_presence, refresh_chat_presence
from app.realtime.connection_manager import subscribe, unsubscribe
from app.schemas.conversation import (
    ConversationCreateRequest,
    ConversationListResponse,
    ConversationResponse,
)
from app.schemas.message import MessageCreateRequest, MessageListResponse, MessageResponse
from app.services.chat_service import ChatService

logger = logging.getLogger(__name__)

router = APIRouter()


def _http_from_app_exc(e: AppException) -> HTTPException:
    return HTTPException(
        status_code=e.status_code,
        detail={"success": False, "error": e.error},
    )


@router.get(
    "",
    response_model=ConversationListResponse,
    summary="List my conversations",
)
async def list_conversations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ConversationListResponse:
    service = ChatService(db)
    items = await service.list_conversations(current_user)
    return ConversationListResponse(conversations=items)


@router.post(
    "",
    response_model=ConversationResponse,
    summary="Create or return existing 1:1 conversation",
)
async def create_conversation(
    body: ConversationCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ConversationResponse:
    service = ChatService(db)
    try:
        return await service.create_or_get_conversation(
            current_user=current_user,
            other_user_id=body.other_user_id,
            listing_id=body.listing_id,
        )
    except AppException as e:
        raise _http_from_app_exc(e) from None


@router.get(
    "/{conversation_id}/messages",
    response_model=MessageListResponse,
    summary="List messages (newest page; use before_id for older)",
)
async def get_messages(
    conversation_id: int,
    limit: int = Query(50, ge=1, le=100),
    before_id: int | None = Query(None, ge=1),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageListResponse:
    service = ChatService(db)
    try:
        return await service.list_messages(
            conversation_id=conversation_id,
            current_user=current_user,
            limit=limit,
            before_id=before_id,
        )
    except AppException as e:
        raise _http_from_app_exc(e) from None


@router.post(
    "/{conversation_id}/messages",
    response_model=MessageResponse,
    summary="Send a message (also broadcast to WebSocket room)",
)
async def post_message(
    conversation_id: int,
    body: MessageCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    service = ChatService(db)
    try:
        return await service.send_message(
            conversation_id=conversation_id,
            current_user=current_user,
            text_body=body.text_body,
        )
    except AppException as e:
        raise _http_from_app_exc(e) from None


@router.websocket("/{conversation_id}/ws")
async def conversation_websocket(
    websocket: WebSocket,
    conversation_id: int,
    token: str | None = Query(None, description="Same JWT as Authorization Bearer"),
) -> None:
    await websocket.accept()

    try:
        async with AsyncSessionLocal() as session:
            if not token:
                await websocket.send_json(
                    {"event": "error", "detail": "token query parameter required"},
                )
                await websocket.close(code=4401)
                return
            try:
                user = await resolve_access_token_user(session, token)
            except HTTPException:
                await websocket.send_json(
                    {"event": "error", "detail": "Invalid or expired token"},
                )
                await websocket.close(code=4401)
                return

            service = ChatService(session)
            try:
                await service.get_conversation_if_member(conversation_id, user)
            except AppException as e:
                await websocket.send_json({"event": "error", "detail": e.error})
                await websocket.close(code=4403)
                return
    except Exception as e:
        logger.exception("WebSocket handshake failed: %s", e)
        try:
            await websocket.send_json({"event": "error", "detail": "Server error"})
        finally:
            await websocket.close(code=1011)
        return

    await subscribe(conversation_id, websocket)
    uid = int(user.id)

    async def _presence_refresh_loop() -> None:
        try:
            while True:
                await asyncio.sleep(30)
                await refresh_chat_presence(conversation_id, uid)
        except asyncio.CancelledError:
            raise

    await refresh_chat_presence(conversation_id, uid)
    presence_task = asyncio.create_task(_presence_refresh_loop())

    try:
        await websocket.send_json(
            {
                "event": "connected",
                "conversation_id": conversation_id,
                "user_id": uid,
            },
        )
    except Exception:
        presence_task.cancel()
        try:
            await presence_task
        except asyncio.CancelledError:
            pass
        await clear_chat_presence(conversation_id, uid)
        await unsubscribe(conversation_id, websocket)
        return

    try:
        while True:
            data = await websocket.receive_json()
            if not isinstance(data, dict):
                await websocket.send_json(
                    {"event": "error", "detail": "JSON object expected"},
                )
                continue

            action = data.get("action")
            if action == "ping":
                await websocket.send_json({"event": "pong"})
                continue

            if action == "fetch_messages":
                limit = data.get("limit", 50)
                before_id = data.get("before_id")
                try:
                    limit = int(limit)
                except (TypeError, ValueError):
                    limit = 50
                if before_id is not None:
                    try:
                        before_id = int(before_id)
                    except (TypeError, ValueError):
                        before_id = None
                async with AsyncSessionLocal() as session:
                    svc = ChatService(session)
                    try:
                        page = await svc.list_messages(
                            conversation_id=conversation_id,
                            current_user=user,
                            limit=limit,
                            before_id=before_id,
                        )
                    except AppException as e:
                        await websocket.send_json(
                            {"event": "error", "detail": e.error},
                        )
                        continue
                await websocket.send_json(
                    {
                        "event": "messages_page",
                        "data": page.model_dump(mode="json"),
                    },
                )
                continue

            if action == "send_message":
                text_body = data.get("text_body")
                if not isinstance(text_body, str):
                    await websocket.send_json(
                        {"event": "error", "detail": "text_body must be a string"},
                    )
                    continue
                async with AsyncSessionLocal() as session:
                    svc = ChatService(session)
                    try:
                        await svc.send_message(
                            conversation_id=conversation_id,
                            current_user=user,
                            text_body=text_body,
                        )
                    except AppException as e:
                        await websocket.send_json(
                            {"event": "error", "detail": e.error},
                        )
                        continue
                continue

            await websocket.send_json(
                {"event": "error", "detail": f"Unknown action: {action!r}"},
            )
    except WebSocketDisconnect:
        pass
    finally:
        presence_task.cancel()
        try:
            await presence_task
        except asyncio.CancelledError:
            pass
        await clear_chat_presence(conversation_id, uid)
        await unsubscribe(conversation_id, websocket)
