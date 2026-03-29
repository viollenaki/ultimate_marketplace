"""Seed default categories for listing forms (INSERT IGNORE).

Revision ID: 004_seed_categories
Revises: 003_listing_media_fs
Create Date: 2026-03-29

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "004_seed_categories"
down_revision: Union[str, None] = "003_listing_media_fs"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        sa.text(
            """
            INSERT IGNORE INTO categories
                (id, name, slug, is_active, display_order, is_deleted)
            VALUES
                (1, 'Cars', 'cars', 1, 1, 0),
                (2, 'Apartments', 'apartments', 1, 2, 0),
                (3, 'Electronics', 'electronics', 1, 3, 0),
                (4, 'Services', 'services', 1, 4, 0),
                (5, 'Jobs', 'jobs', 1, 5, 0),
                (6, 'Home', 'home', 1, 6, 0),
                (7, 'Fashion', 'fashion', 1, 7, 0),
                (8, 'Kids', 'kids', 1, 8, 0)
            """
        )
    )


def downgrade() -> None:
    op.execute(sa.text("DELETE FROM categories WHERE id BETWEEN 1 AND 8"))
