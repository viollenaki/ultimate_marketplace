from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from .base import BaseModel
from .enums import ReportStatus


class Report(BaseModel):
    __tablename__ = "reports"

    reporter_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    target_type = Column(String(30), nullable=False)
    target_id = Column(Integer, nullable=False)
    reason_code = Column(String(50), nullable=False)
    reason_text = Column(Text, nullable=True)
    status = Column(String(30), default=ReportStatus.pending.value)
    resolution_note = Column(Text, nullable=True)
    reviewed_by_admin_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    reviewed_at = Column(DateTime, nullable=True)

    reporter = relationship(
        "User", foreign_keys=[reporter_user_id], back_populates="reports_made"
    )
