from sqlalchemy import Column, Float, Integer, String

from .base import BaseModel


class PromotionPackage(BaseModel):
    __tablename__ = "promotion_packages"

    name = Column(String(100), nullable=False)
    promotion_type = Column(String(50), nullable=False)
    price = Column(Float, nullable=False)
    duration_days = Column(Integer, nullable=False)
    description = Column(String(255), nullable=True)
