"""simplified nose-then-target spark cycle defaults

Revision ID: 007_simplified_spark_cycle
Revises: 006_finger_target_tolerance
"""

from collections.abc import Sequence

from alembic import op

revision: str = "007_simplified_spark_cycle"
down_revision: str | None = "006_finger_target_tolerance"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = data || '{\"elbow_flexion_threshold\": 45.0}'::jsonb "
        "WHERE COALESCE((data->>'elbow_flexion_threshold')::float, 0) < 45"
    )
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = data || '{\"nose_touch_distance_threshold\": 0.28}'::jsonb "
        "WHERE COALESCE((data->>'nose_touch_distance_threshold')::float, 0) < 0.28"
    )
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = data || '{\"spark_fire_ms\": 450}'::jsonb "
        "WHERE NOT data ? 'spark_fire_ms'"
    )


def downgrade() -> None:
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = (data - 'spark_fire_ms') "
        "|| '{\"elbow_flexion_threshold\": 30.0, "
        "\"nose_touch_distance_threshold\": 0.18}'::jsonb"
    )
