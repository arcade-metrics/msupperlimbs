from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class RapidSettingsResponse(BaseModel):
    user_id: UUID
    show_info_video: bool
    total_time: int
    game_mode: str
    visualization_type: str
    tap_sensitivity: float
    tap_cooldown_ms: int
    max_points: int
    min_y: float
    max_y: float
    baseline: float
    gravity_per_second: float
    impulse_strength: float
    floor_restitution: float
    decay_rate_idle: float
    decay_rate_active: float
    decay_rate_unstable: float
    decay_rate_flatline: float
    line_color: int | None
    line_width: float
    glow_enabled: bool
    glow_blur_sigma: float
    use_fixed_dt: bool
    fixed_dt_seconds: float
    pulse_max_intensity: float
    pulse_gravity: float
    pulse_impulse: float
    updated_at: datetime

    model_config = {"from_attributes": True}


class RapidSettingsUpdate(BaseModel):
    show_info_video: bool | None = None
    total_time: int | None = Field(default=None, ge=5, le=600)
    game_mode: str | None = None
    visualization_type: str | None = None
    tap_sensitivity: float | None = None
    tap_cooldown_ms: int | None = Field(default=None, ge=0)
    max_points: int | None = Field(default=None, ge=10)
    min_y: float | None = None
    max_y: float | None = None
    baseline: float | None = None
    gravity_per_second: float | None = None
    impulse_strength: float | None = None
    floor_restitution: float | None = None
    decay_rate_idle: float | None = None
    decay_rate_active: float | None = None
    decay_rate_unstable: float | None = None
    decay_rate_flatline: float | None = None
    line_color: int | None = None
    line_width: float | None = None
    glow_enabled: bool | None = None
    glow_blur_sigma: float | None = None
    use_fixed_dt: bool | None = None
    fixed_dt_seconds: float | None = None
    pulse_max_intensity: float | None = None
    pulse_gravity: float | None = None
    pulse_impulse: float | None = None


class RapidMatchCreate(BaseModel):
    data_contract_version: int = 1
    device_model: str | None = None
    total_time: int = Field(ge=1, le=600)
    game_mode: str
    visualization_type: str
    tap_count: int = Field(ge=0)
    avg_tap_frequency: float | None = None
    avg_pulse_height: float | None = None
    max_pulse_height: float | None = None
    settings_snapshot: dict[str, Any] | None = None
    screen_width: int | None = None
    screen_height: int | None = None
    image_width: int | None = None
    image_height: int | None = None
    started_at_ms: int | None = None
    ended_at_ms: int | None = None
    preview: dict[str, float] | None = None
    is_valid_match: bool = True
    tap_events: list[dict[str, Any]] = Field(default_factory=list)
    pulse_events: list[dict[str, Any]] = Field(default_factory=list)
    pose_samples: list[dict[str, Any]] = Field(default_factory=list)


class RapidMatchResponse(BaseModel):
    id: UUID
    session_id: UUID
    user_id: UUID
    total_time: int
    game_mode: str
    visualization_type: str
    tap_count: int
    avg_tap_frequency: float | None
    avg_pulse_height: float | None
    max_pulse_height: float | None
    is_valid_match: bool
    created_at: datetime
    tap_chunk_count: int = 0
    pulse_chunk_count: int = 0
    pose_chunk_count: int = 0

    model_config = {"from_attributes": True}
