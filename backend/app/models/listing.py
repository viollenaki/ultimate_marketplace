from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    Text,
)
from sqlalchemy.orm import relationship

from .base import BaseModel
from .enums import ListingStatus

# FuelType, TransmissionType, BodyType available for API/schemas; stored as strings.


class Listing(BaseModel):
    __tablename__ = "listings"

    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False, index=True)

    title = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=False)
    price = Column(Float, nullable=False)
    currency = Column(String(10), default="KGS")

    city = Column(String(100), nullable=False, index=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    brand = Column(String(100), nullable=False, index=True)
    model = Column(String(100), nullable=False, index=True)
    year = Column(Integer, nullable=False, index=True)
    mileage = Column(Integer, nullable=False, index=True)
    fuel_type = Column(String(30), nullable=True)
    transmission = Column(String(30), nullable=True)
    body_type = Column(String(50), nullable=True)
    color = Column(String(50), nullable=True, index=True)
    engine_volume = Column(Float, nullable=True)
    horsepower = Column(Integer, nullable=True)
    doors = Column(Integer, nullable=True)
    is_crashed = Column(Boolean, default=False)
    has_warranty = Column(Boolean, default=False)

    status = Column(String(30), default=ListingStatus.draft.value)
    moderation_status = Column(String(30), default="pending")
    view_count = Column(Integer, default=0)
    published_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)

    additional_attributes = Column(JSON, nullable=True)

    owner = relationship("User", back_populates="listings")
    category = relationship("Category")
    media = relationship(
        "ListingMedia", back_populates="listing", cascade="all, delete-orphan"
    )
    favorites = relationship(
        "Favorite", back_populates="listing", cascade="all, delete-orphan"
    )
    promotions = relationship("Promotion", back_populates="listing")
