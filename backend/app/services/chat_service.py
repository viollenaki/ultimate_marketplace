"""Conversations, messages, and realtime broadcast hooks."""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppException
from app.models import Conversation, Message, Notification, User
from app.realtime.chat_presence import is_user_active_in_conversation
from app.realtime.connection_manager import broadcast_to_conversation
from app.services.push_notification_queue import enqueue_fcm_to_user
from app.repositories.conversation_repository import ConversationRepository
from app.repositories.listing_repository import ListingRepository
from app.repositories.message_repository import MessageRepository
from app.repositories.user_repository import UserRepository
from app.schemas.conversation import ConversationResponse
from app.schemas.message import MessageListResponse, MessageResponse
from app.schemas.user import UserPublic


def _ordered_participants(user_id: int, other_user_id: int) -> tuple[int, int]:
    if user_id < other_user_id:
        return user_id, other_user_id
    return other_user_id, user_id


def _other_user_id(conv: Conversation, current_user_id: int) -> int:
    if conv.participant_a_id == current_user_id:
        return conv.participant_b_id
    return conv.participant_a_id


class ChatService:
    def __init__(self, session: AsyncSession) -> None:
        self._db = session

    def _user_public(self, user: User) -> UserPublic:
        return UserPublic.model_validate(user)

    async def _conversation_to_response(
        self,
        conv: Conversation,
        current_user_id: int,
    ) -> ConversationResponse:
        other_id = _other_user_id(conv, current_user_id)
        other = await UserRepository.get_by_id(self._db, other_id)
        if other is None:
            raise AppException(500, "Conversation participant missing")
        last = await MessageRepository.get_last_for_conversation(self._db, conv.id)
        preview = (last.text_body or "")[:160] if last else None
        return ConversationResponse(
            id=conv.id,
            listing_id=conv.listing_id,
            participant_a_id=conv.participant_a_id,
            participant_b_id=conv.participant_b_id,
            other_user=self._user_public(other),
            last_message_at=conv.last_message_at,
            last_message_preview=preview,
            created_at=conv.created_at,
        )

    async def create_or_get_conversation(
        self,
        *,
        current_user: User,
        other_user_id: int,
        listing_id: int | None,
    ) -> ConversationResponse:
        uid = int(current_user.id)
        if other_user_id == uid:
            raise AppException(400, "Cannot start a conversation with yourself")

        other = await UserRepository.get_by_id(self._db, other_user_id)
        if other is None:
            raise AppException(404, "User not found")

        if listing_id is not None:
            listing = await ListingRepository.get_by_id(self._db, listing_id)
            if listing is None:
                raise AppException(404, "Listing not found")
            owner_id = int(listing.owner_id)
            if owner_id not in (uid, other_user_id):
                raise AppException(
                    403,
                    "Listing must involve the listing owner as a participant",
                )

        low, high = _ordered_participants(uid, other_user_id)
        existing = await ConversationRepository.find_between_users(
            self._db, low, high, listing_id
        )
        if existing:
            return await self._conversation_to_response(existing, uid)

        conv = await ConversationRepository.create(
            self._db,
            participant_a_id=low,
            participant_b_id=high,
            listing_id=listing_id,
        )
        await self._db.commit()
        await self._db.refresh(conv)
        return await self._conversation_to_response(conv, uid)

    async def list_conversations(self, current_user: User) -> list[ConversationResponse]:
        uid = int(current_user.id)
        rows = await ConversationRepository.list_for_user(self._db, uid)
        out: list[ConversationResponse] = []
        for conv in rows:
            out.append(await self._conversation_to_response(conv, uid))
        return out

    async def get_conversation_if_member(
        self,
        conversation_id: int,
        current_user: User,
    ) -> Conversation:
        conv = await ConversationRepository.get_by_id(self._db, conversation_id)
        if conv is None:
            raise AppException(404, "Conversation not found")
        if not ConversationRepository.user_is_participant(conv, int(current_user.id)):
            raise AppException(403, "Not a participant in this conversation")
        return conv

    async def list_messages(
        self,
        *,
        conversation_id: int,
        current_user: User,
        limit: int = 50,
        before_id: int | None = None,
    ) -> MessageListResponse:
        await self.get_conversation_if_member(conversation_id, current_user)
        limit = min(max(limit, 1), 100)
        rows = await MessageRepository.list_for_conversation(
            self._db,
            conversation_id,
            limit=limit,
            before_id=before_id,
        )
        next_before_id = rows[0].id if len(rows) == limit else None
        messages = [self._message_to_response(m) for m in rows]
        return MessageListResponse(messages=messages, next_before_id=next_before_id)

    def _message_to_response(self, msg: Message) -> MessageResponse:
        if msg.sender is None:
            raise AppException(500, "Message sender not loaded")
        return MessageResponse(
            id=int(msg.id),
            conversation_id=int(msg.conversation_id),
            sender_id=int(msg.sender_id),
            sender=self._user_public(msg.sender),
            text_body=msg.text_body,
            is_read=bool(msg.is_read),
            sent_at=msg.sent_at,
        )

    async def send_message(
        self,
        *,
        conversation_id: int,
        current_user: User,
        text_body: str,
    ) -> MessageResponse:
        text = text_body.strip()
        if not text:
            raise AppException(400, "Message text is required")

        conv = await self.get_conversation_if_member(conversation_id, current_user)
        uid = int(current_user.id)
        now = datetime.now(timezone.utc)
        msg = await MessageRepository.create(
            self._db,
            conversation_id=conversation_id,
            sender_id=uid,
            text_body=text,
            sent_at=now,
        )
        conv.last_message_at = now
        await self._db.flush()

        recipient_id = _other_user_id(conv, uid)
        preview = text[:200] if len(text) > 200 else text
        self._db.add(
            Notification(
                user_id=recipient_id,
                notification_type="new_message",
                title="New message",
                body=preview,
                is_read=False,
                target_type="conversation",
                target_id=conversation_id,
            )
        )
        await self._db.commit()

        result = await self._db.execute(
            select(Message)
            .where(Message.id == msg.id)
            .options(selectinload(Message.sender))
        )
        msg_loaded = result.scalar_one()
        payload = self._message_to_response(msg_loaded)
        await broadcast_to_conversation(
            conversation_id,
            {"event": "new_message", "data": payload.model_dump(mode="json")},
        )

        # Skip FCM when the peer has this conversation open in a WebSocket (Redis presence).
        recipient_in_chat = await is_user_active_in_conversation(
            conversation_id,
            recipient_id,
        )
        if not recipient_in_chat:
            sender_name = (payload.sender.full_name or "").strip() or "Someone"
            enqueue_fcm_to_user(
                recipient_id,
                title=f"New message from {sender_name}",
                body=preview,
                data={
                    "type": "new_message",
                    "conversation_id": str(conversation_id),
                    "message_id": str(msg_loaded.id),
                },
            )

        return payload
