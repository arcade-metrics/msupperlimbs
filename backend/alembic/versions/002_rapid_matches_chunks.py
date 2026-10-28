"""sessions + rapid_matches + chunks

Revision ID: 002_rapid_matches
Revises: 001_users_rapid
Create Date: 2026-09-18

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import postgresql

revision: str = "002_rapid_matches"
down_revision: Union[str, None] = "001_users_rapid"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())

    if "sessions" not in existing:
        op.create_table(
            "sessions",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("date", sa.String(length=8), nullable=False),
            sa.Column("device_model", sa.String(length=128), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("user_id", "date", name="uq_sessions_user_date"),
        )
        op.create_index(op.f("ix_sessions_user_id"), "sessions", ["user_id"], unique=False)

    if "rapid_matches" not in existing:
        op.create_table(
            "rapid_matches",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("session_id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("total_time", sa.Integer(), nullable=False),
            sa.Column("game_mode", sa.String(length=32), nullable=False),
            sa.Column("visualization_type", sa.String(length=16), nullable=False),
            sa.Column("tap_count", sa.Integer(), nullable=False),
            sa.Column("avg_tap_frequency", sa.Float(), nullable=True),
            sa.Column("avg_pulse_height", sa.Float(), nullable=True),
            sa.Column("max_pulse_height", sa.Float(), nullable=True),
            sa.Column("settings_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
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
        op.create_index(op.f("ix_rapid_matches_session_id"), "rapid_matches", ["session_id"])
        op.create_index(op.f("ix_rapid_matches_user_id"), "rapid_matches", ["user_id"])

    for table in ("rapid_pose_chunks", "rapid_tap_chunks", "rapid_pulse_chunks"):
        if table in existing:
            continue
        op.create_table(
            table,
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("match_id", sa.Uuid(), nullable=False),
            sa.Column("chunk_index", sa.Integer(), nullable=False),
            sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
            sa.ForeignKeyConstraint(["match_id"], ["rapid_matches.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(f"ix_{table}_match_id", table, ["match_id"])


def downgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())
    for table in ("rapid_pulse_chunks", "rapid_tap_chunks", "rapid_pose_chunks", "rapid_matches"):
        if table in existing:
            op.drop_table(table)
    if "sessions" in existing:
        op.drop_index(op.f("ix_sessions_user_id"), table_name="sessions")
        op.drop_table("sessions")
