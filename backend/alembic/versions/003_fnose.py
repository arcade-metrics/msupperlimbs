"""fnose settings + matches + chunks

Revision ID: 003_fnose
Revises: 002_rapid_matches
Create Date: 2026-09-18

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import postgresql

revision: str = "003_fnose"
down_revision: Union[str, None] = "002_rapid_matches"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())

    if "fnose_settings" not in existing:
        op.create_table(
            "fnose_settings",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("game_mode", sa.String(length=32), nullable=False),
            sa.Column("show_info_video", sa.Boolean(), nullable=False),
            sa.Column("total_time", sa.Integer(), nullable=False),
            sa.Column("target_size", sa.Float(), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("user_id"),
        )

    if "fnose_adv_settings" not in existing:
        op.create_table(
            "fnose_adv_settings",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("data", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("user_id"),
        )

    if "fnose_matches" not in existing:
        op.create_table(
            "fnose_matches",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("session_id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("total_time", sa.Integer(), nullable=False),
            sa.Column("game_mode", sa.String(length=32), nullable=False),
            sa.Column("total_left_sparks", sa.Integer(), nullable=False),
            sa.Column("total_right_sparks", sa.Integer(), nullable=False),
            sa.Column("total_sparks", sa.Integer(), nullable=False),
            sa.Column("avg_distance", sa.Float(), nullable=True),
            sa.Column("avg_angle", sa.Float(), nullable=True),
            sa.Column("settings_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
            sa.Column(
                "adv_settings_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=True
            ),
            sa.Column("screen_width", sa.Integer(), nullable=True),
            sa.Column("screen_height", sa.Integer(), nullable=True),
            sa.Column("image_width", sa.Integer(), nullable=True),
            sa.Column("image_height", sa.Integer(), nullable=True),
            sa.Column("is_valid_match", sa.Boolean(), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["session_id"], ["sessions.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index("ix_fnose_matches_session_id", "fnose_matches", ["session_id"])
        op.create_index("ix_fnose_matches_user_id", "fnose_matches", ["user_id"])

    for table in ("fnose_pose_chunks", "fnose_touch_chunks"):
        if table in existing:
            continue
        op.create_table(
            table,
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("match_id", sa.Uuid(), nullable=False),
            sa.Column("chunk_index", sa.Integer(), nullable=False),
            sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
            sa.ForeignKeyConstraint(["match_id"], ["fnose_matches.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(f"ix_{table}_match_id", table, ["match_id"])


def downgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())
    for table in (
        "fnose_touch_chunks",
        "fnose_pose_chunks",
        "fnose_matches",
        "fnose_adv_settings",
        "fnose_settings",
    ):
        if table in existing:
            op.drop_table(table)
