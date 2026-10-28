from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class FnoseSettingsResponse(BaseModel):
    user_id: UUID
    game_mode: str
    show_info_video: bool
    total_time: int
    target_size: float
    updated_at: datetime

    model_config = {"from_attributes": True}


class FnoseSettingsUpdate(BaseModel):
    game_mode: str | None = None
    show_info_video: bool | None = None
    total_time: int | None = Field(default=None, ge=5, le=600)
    target_size: float | None = None


class FnoseAdvSettingsResponse(BaseModel):
    user_id: UUID
    data: dict[str, Any]
    updated_at: datetime

    model_config = {"from_attributes": True}


class FnoseAdvSettingsUpdate(BaseModel):
    data: dict[str, Any] = Field(default_factory=dict)


class FnoseMatchCreate(BaseModel):
    data_contract_version: int = 1
    device_model: str | None = None
    total_time: int = Field(ge=1, le=600)
    game_mode: str
    total_left_sparks: int = 0
    total_right_sparks: int = 0
    total_sparks: int = 0
    avg_distance: float | None = None
    avg_angle: float | None = None
    settings_snapshot: dict[str, Any] | None = None
    adv_settings_snapshot: dict[str, Any] | None = None
    screen_width: int | None = None
    screen_height: int | None = None
    image_width: int | None = None
    image_height: int | None = None
    started_at_ms: int | None = None
    ended_at_ms: int | None = None
    preview: dict[str, float] | None = None
    is_valid_match: bool = True
    pose_samples: list[dict[str, Any]] = Field(default_factory=list)
    touch_events: list[dict[str, Any]] = Field(default_factory=list)
    pregame_run_id: UUID | None = None


class FnoseMatchResponse(BaseModel):
    id: UUID
    session_id: UUID
    user_id: UUID
    total_time: int
    game_mode: str
    total_left_sparks: int
    total_right_sparks: int
    total_sparks: int
    avg_distance: float | None
    avg_angle: float | None
    is_valid_match: bool
    created_at: datetime
    pose_chunk_count: int = 0
    touch_chunk_count: int = 0
    pregame_run_id: UUID | None = None

    model_config = {"from_attributes": True}
