from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Conversation


class ConversationRepository:
    @staticmethod
    async def get_by_id(
        session: AsyncSession,
        conversation_id: int,
    ) -> Conversation | None:
        result = await session.execute(
            select(Conversation).where(Conversation.id == conversation_id)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def find_between_users(
        session: AsyncSession,
        user_a_id: int,
        user_b_id: int,
        listing_id: int | None,
    ) -> Conversation | None:
        low, high = (user_a_id, user_b_id) if user_a_id < user_b_id else (user_b_id, user_a_id)
        q = select(Conversation).where(
            Conversation.participant_a_id == low,
            Conversation.participant_b_id == high,
        )
        if listing_id is None:
            q = q.where(Conversation.listing_id.is_(None))
        else:
            q = q.where(Conversation.listing_id == listing_id)
        result = await session.execute(q)
        return result.scalar_one_or_none()

    @staticmethod
    async def list_for_user(
        session: AsyncSession,
        user_id: int,
        *,
        limit: int = 50,
    ) -> list[Conversation]:
        result = await session.execute(
            select(Conversation)
            .where(
                or_(
                    Conversation.participant_a_id == user_id,
                    Conversation.participant_b_id == user_id,
                )
            )
            .order_by(
                Conversation.last_message_at.desc().nulls_last(),
                Conversation.id.desc(),
            )
            .limit(limit)
        )
        return list(result.scalars().all())

    @staticmethod
    async def create(
        session: AsyncSession,
        *,
        participant_a_id: int,
        participant_b_id: int,
        listing_id: int | None,
    ) -> Conversation:
        conv = Conversation(
            participant_a_id=participant_a_id,
            participant_b_id=participant_b_id,
            listing_id=listing_id,
        )
        session.add(conv)
        await session.flush()
        await session.refresh(conv)
        return conv

    @staticmethod
    def user_is_participant(conv: Conversation, user_id: int) -> bool:
        return user_id in (conv.participant_a_id, conv.participant_b_id)
