from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import BigInteger, Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

JsonPayload = JSON().with_variant(JSONB(), "postgresql")


class FnoseMatch(Base):
    __tablename__ = "fnose_matches"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    session_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    total_time: Mapped[int] = mapped_column(Integer, nullable=False)
    game_mode: Mapped[str] = mapped_column(String(32), nullable=False)
    total_left_sparks: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_right_sparks: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_sparks: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    avg_distance: Mapped[float | None] = mapped_column(Float, nullable=True)
    avg_angle: Mapped[float | None] = mapped_column(Float, nullable=True)
    settings_snapshot: Mapped[dict | None] = mapped_column(JsonPayload, nullable=True)
    adv_settings_snapshot: Mapped[dict | None] = mapped_column(JsonPayload, nullable=True)
    screen_width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    screen_height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    image_width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    image_height: Mapped[int | None] = mapped_column(Integer, nullable=True)
    started_at_ms: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    ended_at_ms: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    preview: Mapped[dict | None] = mapped_column(JsonPayload, nullable=True)
    data_contract_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    is_valid_match: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


class FnosePoseChunk(Base):
    __tablename__ = "fnose_pose_chunks"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    match_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("fnose_matches.id", ondelete="CASCADE"), nullable=False, index=True
    )
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    payload: Mapped[list | dict] = mapped_column(JsonPayload, nullable=False)


class FnoseTouchChunk(Base):
    __tablename__ = "fnose_touch_chunks"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    match_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("fnose_matches.id", ondelete="CASCADE"), nullable=False, index=True
    )
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    payload: Mapped[list | dict] = mapped_column(JsonPayload, nullable=False)
