from sqlalchemy import Column, DateTime, ForeignKey, Integer
from sqlalchemy.orm import relationship

from .base import BaseModel


class Conversation(BaseModel):
    __tablename__ = "conversations"

    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=True)
    participant_a_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    participant_b_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    last_message_at = Column(DateTime, nullable=True)

    participant_a = relationship("User", foreign_keys=[participant_a_id])
    participant_b = relationship("User", foreign_keys=[participant_b_id])
    messages = relationship(
        "Message", back_populates="conversation", cascade="all, delete-orphan"
    )
