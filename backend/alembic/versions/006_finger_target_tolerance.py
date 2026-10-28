"""finger calibration validated inside the target with tolerance

Revision ID: 006_finger_target_tolerance
Revises: 005_synchronized_coordinates
"""

from collections.abc import Sequence

from alembic import op

revision: str = "006_finger_target_tolerance"
down_revision: str | None = "005_synchronized_coordinates"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # finger_stability deixou de ser jitter máximo e passou a ser a margem
    # além da borda do alvo, por isso o valor antigo é substituído.
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = data || '{\"finger_stability\": 0.05}'::jsonb "
        "WHERE (data->>'finger_stability')::float < 0.05"
    )
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = data || '{\"finger_smoothing\": 0.35}'::jsonb "
        "WHERE NOT data ? 'finger_smoothing'"
    )
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = data || '{\"finger_grace_ms\": 400}'::jsonb "
        "WHERE NOT data ? 'finger_grace_ms'"
    )


def downgrade() -> None:
    op.execute(
        "UPDATE fnose_adv_settings "
        "SET data = (data - 'finger_smoothing' - 'finger_grace_ms') "
        "|| '{\"finger_stability\": 0.0167}'::jsonb"
    )
