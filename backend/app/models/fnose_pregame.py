from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

JsonPayload = JSON().with_variant(JSONB(), "postgresql")


class FnosePregameRun(Base):
    __tablename__ = "fnose_pregame_runs"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    session_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    match_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("fnose_matches.id", ondelete="SET NULL"), nullable=True, index=True
    )
    game_mode: Mapped[str] = mapped_column(String(32), nullable=False)
    device_model: Mapped[str | None] = mapped_column(String(128), nullable=True)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="completed")
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    target_calibration_offset: Mapped[dict | None] = mapped_column(JsonPayload, nullable=True)
    screen_width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    screen_height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    image_width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    image_height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    preview: Mapped[dict | None] = mapped_column(JsonPayload, nullable=True)
    data_contract_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    settings_snapshot: Mapped[dict | None] = mapped_column(JsonPayload, nullable=True)
    adv_settings_snapshot: Mapped[dict | None] = mapped_column(JsonPayload, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


class FnosePregamePoseChunk(Base):
    __tablename__ = "fnose_pregame_pose_chunks"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    pregame_run_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("fnose_pregame_runs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    payload: Mapped[list | dict] = mapped_column(JsonPayload, nullable=False)


class FnosePregameSensorChunk(Base):
    __tablename__ = "fnose_pregame_sensor_chunks"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    pregame_run_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("fnose_pregame_runs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    payload: Mapped[list | dict] = mapped_column(JsonPayload, nullable=False)


class FnosePregameEventChunk(Base):
    __tablename__ = "fnose_pregame_event_chunks"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    pregame_run_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("fnose_pregame_runs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    payload: Mapped[list | dict] = mapped_column(JsonPayload, nullable=False)
