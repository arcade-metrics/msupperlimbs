"""create users and rapid_settings

Revision ID: 001_users_rapid
Revises:
Create Date: 2026-09-18

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect

revision: str = "001_users_rapid"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())

    if "users" not in existing:
        op.create_table(
            "users",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("email", sa.String(length=255), nullable=False),
            sa.Column("password_hash", sa.String(length=255), nullable=False),
            sa.Column("name", sa.String(length=255), nullable=False),
            sa.Column("consent_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("last_access", sa.DateTime(timezone=True), nullable=True),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_users_email"), "users", ["email"], unique=True)

    if "rapid_settings" not in existing:
        op.create_table(
            "rapid_settings",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("user_id", sa.Uuid(), nullable=False),
            sa.Column("show_info_video", sa.Boolean(), nullable=False),
            sa.Column("total_time", sa.Integer(), nullable=False),
            sa.Column("game_mode", sa.String(length=32), nullable=False),
            sa.Column("visualization_type", sa.String(length=16), nullable=False),
            sa.Column("tap_sensitivity", sa.Float(), nullable=False),
            sa.Column("tap_cooldown_ms", sa.Integer(), nullable=False),
            sa.Column("max_points", sa.Integer(), nullable=False),
            sa.Column("min_y", sa.Float(), nullable=False),
            sa.Column("max_y", sa.Float(), nullable=False),
            sa.Column("baseline", sa.Float(), nullable=False),
            sa.Column("gravity_per_second", sa.Float(), nullable=False),
            sa.Column("impulse_strength", sa.Float(), nullable=False),
            sa.Column("floor_restitution", sa.Float(), nullable=False),
            sa.Column("decay_rate_idle", sa.Float(), nullable=False),
            sa.Column("decay_rate_active", sa.Float(), nullable=False),
            sa.Column("decay_rate_unstable", sa.Float(), nullable=False),
            sa.Column("decay_rate_flatline", sa.Float(), nullable=False),
            sa.Column("line_color", sa.Integer(), nullable=True),
            sa.Column("line_width", sa.Float(), nullable=False),
            sa.Column("glow_enabled", sa.Boolean(), nullable=False),
            sa.Column("glow_blur_sigma", sa.Float(), nullable=False),
            sa.Column("use_fixed_dt", sa.Boolean(), nullable=False),
            sa.Column("fixed_dt_seconds", sa.Float(), nullable=False),
            sa.Column("pulse_max_intensity", sa.Float(), nullable=False),
            sa.Column("pulse_gravity", sa.Float(), nullable=False),
            sa.Column("pulse_impulse", sa.Float(), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("user_id"),
        )


def downgrade() -> None:
    bind = op.get_bind()
    existing = set(inspect(bind).get_table_names())
    if "rapid_settings" in existing:
        op.drop_table("rapid_settings")
    if "users" in existing:
        op.drop_index(op.f("ix_users_email"), table_name="users")
        op.drop_table("users")
