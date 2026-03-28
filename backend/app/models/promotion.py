from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .base import BaseModel
from .enums import PromotionType


class Promotion(BaseModel):
    __tablename__ = "promotions"

    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    promotion_type = Column(String(50), default=PromotionType.featured.value)
    target_city = Column(String(100), nullable=True)
    target_category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    starts_at = Column(DateTime, nullable=True)
    ends_at = Column(DateTime, nullable=True)
    status = Column(String(30), default="active")
    purchased_price = Column(Float, nullable=False)

    listing = relationship("Listing", back_populates="promotions")
    user = relationship("User", back_populates="promotions")
