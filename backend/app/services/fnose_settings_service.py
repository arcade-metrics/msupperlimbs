from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fnose_adv_settings import FnoseAdvSettings
from app.models.fnose_settings import FnoseSettings

ALLOWED_GAME_MODES = {"leftHand", "rightHand", "bothHands"}

FNOSE_SETTINGS_DEFAULTS = {
    "game_mode": "leftHand",
    "show_info_video": True,
    "total_time": 60,
    "target_size": 1.0,
}

FNOSE_ADV_DEFAULTS = {
    "alpha": 0.3,
    "angle_buffer_size": 2.0,
    "angle_window_seconds": 1,
    "elbow_flexion_threshold": 45.0,
    "elbow_extension_threshold": 160.0,
    "horizontal_elbow_shoulder_distance_threshold": 0.25,
    "max_shoulder_distance": 0.3,
    "min_angle_change_for_elbow_detection": 4.0,
    "min_angle_change_for_shoulder_detection": 4.0,
    "min_distance_to_target": 0.18,
    "min_shoulder_distance": 0.2,
    "moving_average_frames": 5,
    "nose_center_threshold": 0.45,
    "nose_touch_distance_threshold": 0.28,
    "spark_fire_ms": 450,
    "target_number": 4,
    "target_scale": 0.45,
    "required_stable_time_ms": 2500,
    "stability_grace_ms": 400,
    "tilt_hold_ms": 700,
    "nose_hold_ms": 1200,
    "finger_hold_ms": 1200,
    # Margem além da borda do alvo, em fração do menor lado do ecrã.
    "finger_stability": 0.05,
    "finger_smoothing": 0.35,
    "finger_grace_ms": 400,
    "pitch_min_deg": -12.0,
    "pitch_max_deg": 12.0,
    "roll_min_deg": -8.0,
    "roll_max_deg": 8.0,
    "shoulder_y_alignment_threshold": 0.35,
    "shoulder_z_alignment_threshold": 0.35,
    "stability_threshold": 0.5,
    "event_throttle_ms": 50,
    "update_debounce_ms": 50,
    "min_angle": 70.0,
    "max_angle": 120.0,
    "vertical_elbow_shoulder_distance_threshold": 0.2,
    "x_target_position": 0.1,
    "y_target_position": 0.5,
    "x_nose_alignment": 0.7,
    "y_nose_alignment": 0.3,
    "nose_alignment_threshold": 0.05,
    "nose_alignment_target_radius": 0.07,
    "landmark_buffer_size": 3,
}


def default_fnose_settings(user_id: UUID) -> FnoseSettings:
    return FnoseSettings(user_id=user_id, **FNOSE_SETTINGS_DEFAULTS)


def default_fnose_adv_settings(user_id: UUID) -> FnoseAdvSettings:
    return FnoseAdvSettings(user_id=user_id, data=dict(FNOSE_ADV_DEFAULTS))


async def get_or_create_settings(db: AsyncSession, user_id: UUID) -> FnoseSettings:
    row = await db.scalar(select(FnoseSettings).where(FnoseSettings.user_id == user_id))
    if row:
        return row
    row = default_fnose_settings(user_id)
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return row


async def get_or_create_adv_settings(db: AsyncSession, user_id: UUID) -> FnoseAdvSettings:
    row = await db.scalar(
        select(FnoseAdvSettings).where(FnoseAdvSettings.user_id == user_id)
    )
    if row:
        # merge missing keys from defaults
        merged = {**FNOSE_ADV_DEFAULTS, **(row.data or {})}
        if merged != row.data:
            row.data = merged
            await db.commit()
            await db.refresh(row)
        return row
    row = default_fnose_adv_settings(user_id)
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return row


async def update_settings(db: AsyncSession, user_id: UUID, payload: dict) -> FnoseSettings:
    row = await get_or_create_settings(db, user_id)
    if "game_mode" in payload and payload["game_mode"] not in ALLOWED_GAME_MODES:
        raise ValueError("Invalid game_mode")
    for key, value in payload.items():
        setattr(row, key, value)
    row.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(row)
    return row


async def restore_settings(db: AsyncSession, user_id: UUID) -> FnoseSettings:
    row = await get_or_create_settings(db, user_id)
    for key, value in FNOSE_SETTINGS_DEFAULTS.items():
        setattr(row, key, value)
    row.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(row)
    return row


async def update_adv_settings(
    db: AsyncSession, user_id: UUID, patch: dict
) -> FnoseAdvSettings:
    row = await get_or_create_adv_settings(db, user_id)
    data = {**FNOSE_ADV_DEFAULTS, **(row.data or {}), **patch}
    row.data = data
    row.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(row)
    return row


async def restore_adv_settings(db: AsyncSession, user_id: UUID) -> FnoseAdvSettings:
    row = await get_or_create_adv_settings(db, user_id)
    row.data = dict(FNOSE_ADV_DEFAULTS)
    row.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(row)
    return row
