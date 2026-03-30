"""user_fcm_tokens for FCM push delivery.

Revision ID: 006_user_fcm_tokens
Revises: 005_drop_listing_category
Create Date: 2026-03-30

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "006_user_fcm_tokens"
down_revision: Union[str, None] = "005_drop_listing_category"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = inspector.get_table_names()
    if "user_fcm_tokens" not in tables:
        op.create_table(
            "user_fcm_tokens",
            sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                server_default=sa.text("CURRENT_TIMESTAMP"),
                nullable=True,
            ),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column(
                "is_deleted",
                sa.Boolean(),
                server_default=sa.text("0"),
                nullable=False,
            ),
            sa.Column("user_id", sa.Integer(), nullable=False),
            sa.Column("token", sa.String(length=512), nullable=False),
            sa.Column("platform", sa.String(length=20), nullable=True),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("token", name="uq_user_fcm_tokens_token"),
        )
        op.create_index(
            "ix_user_fcm_tokens_user_id",
            "user_fcm_tokens",
            ["user_id"],
            unique=False,
        )
        return

    idx_names = {i["name"] for i in inspector.get_indexes("user_fcm_tokens")}
    if "ix_user_fcm_tokens_user_id" not in idx_names:
        op.create_index(
            "ix_user_fcm_tokens_user_id",
            "user_fcm_tokens",
            ["user_id"],
            unique=False,
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "user_fcm_tokens" not in inspector.get_table_names():
        return
    idx_names = {i["name"] for i in inspector.get_indexes("user_fcm_tokens")}
    if "ix_user_fcm_tokens_user_id" in idx_names:
        op.drop_index("ix_user_fcm_tokens_user_id", table_name="user_fcm_tokens")
    op.drop_table("user_fcm_tokens")
