from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field


class FnosePregameCreate(BaseModel):
    data_contract_version: int = 1
    device_model: str | None = None
    game_mode: str
    status: Literal["completed", "abandoned"] = "completed"
    started_at_ms: int
    ended_at_ms: int
    target_calibration_offset: dict[str, Any] | None = None
    screen_width: int | None = None
    screen_height: int | None = None
    image_width: int | None = None
    image_height: int | None = None
    preview: dict[str, float] | None = None
    settings_snapshot: dict[str, Any] | None = None
    adv_settings_snapshot: dict[str, Any] | None = None
    pose_samples: list[dict[str, Any]] = Field(default_factory=list)
    sensor_samples: list[dict[str, Any]] = Field(default_factory=list)
    events: list[dict[str, Any]] = Field(default_factory=list)


class FnosePregameResponse(BaseModel):
    id: UUID
    session_id: UUID
    user_id: UUID
    match_id: UUID | None
    status: str
    started_at: datetime
    ended_at: datetime
    pose_chunk_count: int = 0
    sensor_chunk_count: int = 0
    event_chunk_count: int = 0

    model_config = {"from_attributes": True}
