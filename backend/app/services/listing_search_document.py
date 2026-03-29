"""Build Elasticsearch documents from Listing ORM."""
from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from app.models import Listing


def build_listing_search_document(listing: Listing) -> dict[str, Any]:
    """Flat document for keyword + full-text search and aggregations."""
    published = listing.published_at or listing.created_at
    published_iso = None
    if published is not None:
        published_iso = published.isoformat() if hasattr(published, "isoformat") else str(published)

    search_blob = " ".join(
        str(x)
        for x in (
            listing.title,
            listing.description,
            listing.brand,
            listing.model,
            listing.city,
            listing.fuel_type or "",
            listing.body_type or "",
            listing.transmission or "",
            listing.color or "",
        )
        if x
    )

    return {
        "listing_id": listing.id,
        "title": listing.title,
        "description": listing.description,
        "brand": listing.brand,
        "model": listing.model,
        "city": listing.city,
        "year": listing.year,
        "mileage": listing.mileage,
        "price": float(listing.price),
        "currency": listing.currency or "KGS",
        "fuel_type": listing.fuel_type or "",
        "transmission": listing.transmission or "",
        "body_type": listing.body_type or "",
        "color": listing.color or "",
        "status": listing.status or "",
        "is_deleted": bool(listing.is_deleted),
        "is_crashed": bool(listing.is_crashed),
        "published_at": published_iso,
        "search_blob": search_blob,
    }
