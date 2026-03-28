from sqlalchemy import Column, String, Text
from sqlalchemy.orm import relationship

from .base import BaseModel
from .enums import UserStatus


class User(BaseModel):
    __tablename__ = "users"

    full_name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(50), unique=True, nullable=True)
    hashed_password = Column(String(255), nullable=False)
    profile_image_url = Column(String(500), nullable=True)
    bio = Column(Text, nullable=True)
    city = Column(String(100), index=True, nullable=True)
    preferred_language = Column(String(10), default="en")
    account_status = Column(String(30), default=UserStatus.active.value)
    firebase_uid = Column(String(255), unique=True, nullable=True)

    listings = relationship(
        "Listing", back_populates="owner", cascade="all, delete-orphan"
    )
    favorites = relationship(
        "Favorite", back_populates="user", cascade="all, delete-orphan"
    )
    payments = relationship("Payment", back_populates="user")
    promotions = relationship("Promotion", back_populates="user")
    reports_made = relationship(
        "Report",
        back_populates="reporter",
        foreign_keys="[Report.reporter_user_id]",
    )
    notifications = relationship("Notification", back_populates="user")
