from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Message


class MessageRepository:
    @staticmethod
    async def get_by_id(session: AsyncSession, message_id: int) -> Message | None:
        result = await session.execute(select(Message).where(Message.id == message_id))
        return result.scalar_one_or_none()

    @staticmethod
    async def get_last_for_conversation(
        session: AsyncSession,
        conversation_id: int,
    ) -> Message | None:
        result = await session.execute(
            select(Message)
            .where(Message.conversation_id == conversation_id)
            .order_by(Message.id.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def list_for_conversation(
        session: AsyncSession,
        conversation_id: int,
        *,
        limit: int = 50,
        before_id: int | None = None,
    ) -> list[Message]:
        q = (
            select(Message)
            .where(Message.conversation_id == conversation_id)
            .options(selectinload(Message.sender))
            .order_by(Message.id.desc())
            .limit(limit)
        )
        if before_id is not None:
            q = q.where(Message.id < before_id)
        result = await session.execute(q)
        rows = list(result.scalars().all())
        rows.reverse()
        return rows

    @staticmethod
    async def create(
        session: AsyncSession,
        *,
        conversation_id: int,
        sender_id: int,
        text_body: str,
        sent_at,
    ) -> Message:
        msg = Message(
            conversation_id=conversation_id,
            sender_id=sender_id,
            text_body=text_body,
            is_read=False,
            sent_at=sent_at,
        )
        session.add(msg)
        await session.flush()
        return msg
