from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.rapid_settings import RapidSettings
from app.schemas.rapid import RapidSettingsUpdate

ALLOWED_GAME_MODES = {"leftHand", "rightHand", "bothHands"}
ALLOWED_VISUALIZATIONS = {"line", "bar", "circle"}

_DEFAULTS = {
    "show_info_video": True,
    "total_time": 30,
    "game_mode": "rightHand",
    "visualization_type": "line",
    # Distância no espaço A (MediaPipe normalizado).
    "tap_sensitivity": 0.04,
    "tap_cooldown_ms": 110,
    "max_points": 420,
    "min_y": 0.0,
    "max_y": 1.0,
    "baseline": 0.25,
    "gravity_per_second": 0.35,
    "impulse_strength": 0.06,
    "floor_restitution": 0.0,
    "decay_rate_idle": 0.05,
    "decay_rate_active": 0.03,
    "decay_rate_unstable": 0.07,
    "decay_rate_flatline": 0.10,
    "line_color": None,
    "line_width": 3.0,
    "glow_enabled": True,
    "glow_blur_sigma": 8.0,
    "use_fixed_dt": True,
    "fixed_dt_seconds": 1.0 / 30.0,
    "pulse_max_intensity": 0.6,
    "pulse_gravity": 0.003,
    "pulse_impulse": 0.16,
}


def default_rapid_settings(user_id: UUID) -> RapidSettings:
    return RapidSettings(user_id=user_id, **_DEFAULTS)


async def get_or_create_settings(db: AsyncSession, user_id: UUID) -> RapidSettings:
    settings = await db.scalar(
        select(RapidSettings).where(RapidSettings.user_id == user_id)
    )
    if settings:
        return settings
    settings = default_rapid_settings(user_id)
    db.add(settings)
    await db.commit()
    await db.refresh(settings)
    return settings


async def update_settings(
    db: AsyncSession, user_id: UUID, data: RapidSettingsUpdate
) -> RapidSettings:
    settings = await get_or_create_settings(db, user_id)
    payload = data.model_dump(exclude_unset=True)

    if "game_mode" in payload and payload["game_mode"] not in ALLOWED_GAME_MODES:
        raise ValueError("Invalid game_mode")
    if (
        "visualization_type" in payload
        and payload["visualization_type"] not in ALLOWED_VISUALIZATIONS
    ):
        raise ValueError("Invalid visualization_type")

    for key, value in payload.items():
        setattr(settings, key, value)
    settings.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(settings)
    return settings


async def restore_defaults(db: AsyncSession, user_id: UUID) -> RapidSettings:
    settings = await get_or_create_settings(db, user_id)
    for key, value in _DEFAULTS.items():
        setattr(settings, key, value)
    settings.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(settings)
    return settings
