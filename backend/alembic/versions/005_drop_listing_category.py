"""Remove listings.category_id (cars-only marketplace).

Revision ID: 005_drop_listing_category
Revises: 004_seed_categories
Create Date: 2026-03-29

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "005_drop_listing_category"
down_revision: Union[str, None] = "004_seed_categories"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    column_names = {c["name"] for c in inspector.get_columns("listings")}
    if "category_id" not in column_names:
        # Fresh DBs created from ORM without category_id (e.g. 001 create_all).
        return
    for fk in inspector.get_foreign_keys("listings"):
        cols = fk.get("constrained_columns") or []
        if "category_id" in cols:
            op.drop_constraint(fk["name"], "listings", type_="foreignkey")
            break
    op.drop_column("listings", "category_id")


def downgrade() -> None:
    op.add_column(
        "listings",
        sa.Column("category_id", sa.Integer(), nullable=True),
    )
    op.execute(sa.text("UPDATE listings SET category_id = 1 WHERE category_id IS NULL"))
    op.alter_column("listings", "category_id", existing_type=sa.Integer(), nullable=False)
    op.create_foreign_key(
        "fk_listings_category_id_categories",
        "listings",
        "categories",
        ["category_id"],
        ["id"],
    )
