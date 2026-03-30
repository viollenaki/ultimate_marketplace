from sqlalchemy import Column, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from .base import BaseModel


class UserFcmToken(BaseModel):
    """Stores FCM registration tokens per user device for push delivery."""

    __tablename__ = "user_fcm_tokens"
    __table_args__ = (UniqueConstraint("token", name="uq_user_fcm_tokens_token"),)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    # FCM tokens are long; 512 is safe headroom
    token = Column(String(512), nullable=False)
    platform = Column(String(20), nullable=True)

    user = relationship("User", back_populates="fcm_tokens")
