"""Map fields: listing location_display_name, media lat/lng, indexes on listing coords.

Revision ID: 002_listing_map
Revises: 001_initial
Create Date: 2026-03-29

Note: 001_initial uses create_all() from current ORM metadata, so these columns may
already exist. This revision is idempotent so upgrade head works either way.

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect

revision: str = "002_listing_map"
down_revision: Union[str, None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _column_names(bind, table: str) -> set[str]:
    return {c["name"] for c in inspect(bind).get_columns(table)}


def _index_names(bind, table: str) -> set[str]:
    return {ix["name"] for ix in inspect(bind).get_indexes(table)}


def upgrade() -> None:
    bind = op.get_bind()
    listings_cols = _column_names(bind, "listings")
    media_cols = _column_names(bind, "listing_media")
    listing_ix = _index_names(bind, "listings")

    if "location_display_name" not in listings_cols:
        op.add_column(
            "listings",
            sa.Column("location_display_name", sa.String(length=255), nullable=True),
        )
    ix_lat = op.f("ix_listings_latitude")
    ix_lng = op.f("ix_listings_longitude")
    if ix_lat not in listing_ix:
        op.create_index(ix_lat, "listings", ["latitude"], unique=False)
    if ix_lng not in listing_ix:
        op.create_index(ix_lng, "listings", ["longitude"], unique=False)
    if "latitude" not in media_cols:
        op.add_column("listing_media", sa.Column("latitude", sa.Float(), nullable=True))
    if "longitude" not in media_cols:
        op.add_column("listing_media", sa.Column("longitude", sa.Float(), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    media_cols = _column_names(bind, "listing_media")
    listings_cols = _column_names(bind, "listings")
    listing_ix = _index_names(bind, "listings")

    if "longitude" in media_cols:
        op.drop_column("listing_media", "longitude")
    if "latitude" in media_cols:
        op.drop_column("listing_media", "latitude")
    ix_lng = op.f("ix_listings_longitude")
    ix_lat = op.f("ix_listings_latitude")
    if ix_lng in listing_ix:
        op.drop_index(ix_lng, table_name="listings")
    if ix_lat in listing_ix:
        op.drop_index(ix_lat, table_name="listings")
    if "location_display_name" in listings_cols:
        op.drop_column("listings", "location_display_name")
