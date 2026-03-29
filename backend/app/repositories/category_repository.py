from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Category


class CategoryRepository:
    @staticmethod
    async def get_by_id(session: AsyncSession, category_id: int) -> Category | None:
        result = await session.execute(
            select(Category).where(
                Category.id == category_id,
                Category.is_active.is_(True),
            )
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def list_active(session: AsyncSession) -> list[Category]:
        result = await session.execute(
            select(Category)
            .where(
                Category.is_active.is_(True),
                Category.is_deleted.is_(False),
            )
            .order_by(Category.display_order, Category.name)
        )
        return list(result.scalars().all())
