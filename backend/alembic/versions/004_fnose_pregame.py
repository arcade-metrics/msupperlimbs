"""fnose pregame runs + pose/sensor/event chunks

Revision ID: 004_fnose_pregame
Revises: 003_fnose
Create Date: 2026-09-18

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import postgresql

revision: str = "004_fnose_pregame"
down_revision: Union[str, None] = "003_fnose"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())

    if "fnose_pregame_runs" not in existing:
        op.create_table(
            "fnose_pregame_runs",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("session_id", sa.Uuid(), nullable=False),
            sa.Column("match_id", sa.Uuid(), nullable=True),
            sa.Column("game_mode", sa.String(length=32), nullable=False),
            sa.Column("device_model", sa.String(length=128), nullable=True),
            sa.Column("status", sa.String(length=32), nullable=False),
            sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("ended_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column(
                "target_calibration_offset",
                postgresql.JSONB(astext_type=sa.Text()),
                nullable=True,
            ),
            sa.Column("screen_width", sa.Integer(), nullable=True),
            sa.Column("screen_height", sa.Integer(), nullable=True),
            sa.Column("image_width", sa.Integer(), nullable=True),
            sa.Column("image_height", sa.Integer(), nullable=True),
            sa.Column(
                "settings_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=True
            ),
            sa.Column(
                "adv_settings_snapshot",
                postgresql.JSONB(astext_type=sa.Text()),
                nullable=True,
            ),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["session_id"], ["sessions.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["match_id"], ["fnose_matches.id"], ondelete="SET NULL"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index("ix_fnose_pregame_runs_user_id", "fnose_pregame_runs", ["user_id"])
        op.create_index(
            "ix_fnose_pregame_runs_session_id", "fnose_pregame_runs", ["session_id"]
        )
        op.create_index(
            "ix_fnose_pregame_runs_match_id", "fnose_pregame_runs", ["match_id"]
        )

    for table in (
        "fnose_pregame_pose_chunks",
        "fnose_pregame_sensor_chunks",
        "fnose_pregame_event_chunks",
    ):
        if table in existing:
            continue
        op.create_table(
            table,
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("pregame_run_id", sa.Uuid(), nullable=False),
            sa.Column("chunk_index", sa.Integer(), nullable=False),
            sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
            sa.ForeignKeyConstraint(
                ["pregame_run_id"], ["fnose_pregame_runs.id"], ondelete="CASCADE"
            ),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(f"ix_{table}_pregame_run_id", table, ["pregame_run_id"])


def downgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())
    for table in (
        "fnose_pregame_event_chunks",
        "fnose_pregame_sensor_chunks",
        "fnose_pregame_pose_chunks",
        "fnose_pregame_runs",
    ):
        if table in existing:
            op.drop_table(table)
