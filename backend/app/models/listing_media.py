from sqlalchemy import Boolean, Column, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .base import BaseModel


class ListingMedia(BaseModel):
    __tablename__ = "listing_media"

    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    # Firebase Storage object id (bucket is in storage_bucket); mobile can use file_url or gs://bucket/path
    storage_bucket = Column(String(255), nullable=True)
    storage_path = Column(String(1024), nullable=True)
    content_type = Column(String(128), nullable=True)
    file_size = Column(Integer, nullable=True)
    # Public/signed HTTPS URL for Image.network etc.
    file_url = Column(String(2048), nullable=False)
    order_index = Column(Integer, default=0)
    is_primary = Column(Boolean, default=False)
    # Optional EXIF / per-photo coordinates if different from listing location
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    listing = relationship("Listing", back_populates="media")
