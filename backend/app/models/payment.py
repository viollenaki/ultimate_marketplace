from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .base import BaseModel
from .enums import PaymentStatus


class Payment(BaseModel):
    __tablename__ = "payments"

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=True)
    promotion_id = Column(Integer, ForeignKey("promotions.id"), nullable=True)
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="KGS")
    status = Column(String(30), default=PaymentStatus.pending.value)
    payment_provider = Column(String(50), nullable=True)
    provider_reference = Column(String(255), nullable=True)
    paid_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="payments")
    listing = relationship("Listing")
