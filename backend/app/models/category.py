from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .base import BaseModel


class Category(BaseModel):
    __tablename__ = "categories"

    name = Column(String(100), nullable=False)
    slug = Column(String(100), unique=True, index=True, nullable=False)
    is_active = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    parent_category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)


# Assign after class body so `Category.id` exists (inherited from BaseModel). Using
# `remote_side=[id]` inside the class runs in a namespace where `id` is the builtin.
Category.parent = relationship(
    "Category",
    remote_side=[Category.id],
    foreign_keys=[Category.parent_category_id],
    back_populates="subcategories",
)
Category.subcategories = relationship(
    "Category",
    foreign_keys=[Category.parent_category_id],
    back_populates="parent",
)
