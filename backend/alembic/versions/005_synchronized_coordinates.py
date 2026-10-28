"""synchronized run clock and normalized preview metadata

Revision ID: 005_synchronized_coordinates
Revises: 004_fnose_pregame
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "005_synchronized_coordinates"
down_revision: str | None = "004_fnose_pregame"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    for table in ("fnose_matches", "rapid_matches"):
        op.add_column(table, sa.Column("started_at_ms", sa.BigInteger(), nullable=True))
        op.add_column(table, sa.Column("ended_at_ms", sa.BigInteger(), nullable=True))
        op.add_column(table, sa.Column("preview", sa.JSON(), nullable=True))
        op.add_column(
            table,
            sa.Column(
                "data_contract_version",
                sa.Integer(),
                nullable=False,
                server_default="1",
            ),
        )
    op.add_column(
        "fnose_pregame_runs", sa.Column("preview", sa.JSON(), nullable=True)
    )
    op.add_column(
        "fnose_pregame_runs",
        sa.Column(
            "data_contract_version", sa.Integer(), nullable=False, server_default="1"
        ),
    )
    op.execute(
        "UPDATE rapid_settings "
        "SET tap_sensitivity = tap_sensitivity / 1250.0 "
        "WHERE tap_sensitivity >= 1.0"
    )


def downgrade() -> None:
    op.execute(
        "UPDATE rapid_settings "
        "SET tap_sensitivity = tap_sensitivity * 1250.0 "
        "WHERE tap_sensitivity < 1.0"
    )
    op.drop_column("fnose_pregame_runs", "preview")
    op.drop_column("fnose_pregame_runs", "data_contract_version")
    for table in ("rapid_matches", "fnose_matches"):
        op.drop_column(table, "data_contract_version")
        op.drop_column(table, "preview")
        op.drop_column(table, "ended_at_ms")
        op.drop_column(table, "started_at_ms")
