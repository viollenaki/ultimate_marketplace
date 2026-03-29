"""Active categories for listing forms."""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_db
from app.repositories.category_repository import CategoryRepository
from app.schemas.listing import CategoryBrief

router = APIRouter()


@router.get(
    "",
    response_model=list[CategoryBrief],
    summary="List active categories",
)
async def list_categories(db: AsyncSession = Depends(get_db)) -> list[CategoryBrief]:
    repo = CategoryRepository()
    rows = await repo.list_active(db)
    return [CategoryBrief.model_validate(c) for c in rows]
