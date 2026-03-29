"""Listing media: Firebase Storage metadata columns, widen file_url.

Revision ID: 003_listing_media_fs
Revises: 002_listing_map
Create Date: 2026-03-29

Idempotent: 001_initial create_all() may already match the ORM (including these columns).

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect

revision: str = "003_listing_media_fs"
down_revision: Union[str, None] = "002_listing_map"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _column_names(bind, table: str) -> set[str]:
    return {c["name"] for c in inspect(bind).get_columns(table)}


def upgrade() -> None:
    bind = op.get_bind()
    media_cols = _column_names(bind, "listing_media")

    if "storage_bucket" not in media_cols:
        op.add_column(
            "listing_media",
            sa.Column("storage_bucket", sa.String(length=255), nullable=True),
        )
    if "storage_path" not in media_cols:
        op.add_column(
            "listing_media",
            sa.Column("storage_path", sa.String(length=1024), nullable=True),
        )
    if "content_type" not in media_cols:
        op.add_column(
            "listing_media",
            sa.Column("content_type", sa.String(length=128), nullable=True),
        )
    if "file_size" not in media_cols:
        op.add_column("listing_media", sa.Column("file_size", sa.Integer(), nullable=True))

    row = bind.execute(
        sa.text(
            "SELECT CHARACTER_MAXIMUM_LENGTH AS maxlen "
            "FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'listing_media' "
            "AND COLUMN_NAME = 'file_url'"
        )
    ).mappings().first()
    maxlen = row["maxlen"] if row else None
    if maxlen is not None and int(maxlen) < 2048:
        op.execute(
            sa.text("ALTER TABLE listing_media MODIFY file_url VARCHAR(2048) NOT NULL")
        )


def downgrade() -> None:
    bind = op.get_bind()
    media_cols = _column_names(bind, "listing_media")

    if "file_size" in media_cols:
        op.drop_column("listing_media", "file_size")
    if "content_type" in media_cols:
        op.drop_column("listing_media", "content_type")
    if "storage_path" in media_cols:
        op.drop_column("listing_media", "storage_path")
    if "storage_bucket" in media_cols:
        op.drop_column("listing_media", "storage_bucket")

    row = bind.execute(
        sa.text(
            "SELECT CHARACTER_MAXIMUM_LENGTH AS maxlen "
            "FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'listing_media' "
            "AND COLUMN_NAME = 'file_url'"
        )
    ).mappings().first()
    maxlen = row["maxlen"] if row else None
    if maxlen is not None and int(maxlen) > 500:
        op.execute(
            sa.text("ALTER TABLE listing_media MODIFY file_url VARCHAR(500) NOT NULL")
        )
