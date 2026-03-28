from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .base import BaseModel


class ListingMedia(BaseModel):
    __tablename__ = "listing_media"

    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=False)
    file_url = Column(String(500), nullable=False)
    order_index = Column(Integer, default=0)
    is_primary = Column(Boolean, default=False)

    listing = relationship("Listing", back_populates="media")
