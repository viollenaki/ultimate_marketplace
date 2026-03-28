from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .base import BaseModel


class MessageAttachment(BaseModel):
    __tablename__ = "message_attachments"

    message_id = Column(Integer, ForeignKey("messages.id"), nullable=False)
    file_url = Column(String(500), nullable=False)
    original_name = Column(String(255), nullable=False)
    mime_type = Column(String(100), nullable=True)
    file_size = Column(Integer, nullable=True)

    message = relationship("Message", back_populates="attachments")
