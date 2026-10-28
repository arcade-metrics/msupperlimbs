from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class RapidSettings(Base):
    __tablename__ = "rapid_settings"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )

    show_info_video: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    total_time: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    game_mode: Mapped[str] = mapped_column(String(32), nullable=False, default="rightHand")
    visualization_type: Mapped[str] = mapped_column(String(16), nullable=False, default="line")

    tap_sensitivity: Mapped[float] = mapped_column(Float, nullable=False, default=50.0)
    tap_cooldown_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=110)

    max_points: Mapped[int] = mapped_column(Integer, nullable=False, default=420)
    min_y: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    max_y: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    baseline: Mapped[float] = mapped_column(Float, nullable=False, default=0.25)
    gravity_per_second: Mapped[float] = mapped_column(Float, nullable=False, default=0.35)
    impulse_strength: Mapped[float] = mapped_column(Float, nullable=False, default=0.06)
    floor_restitution: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    decay_rate_idle: Mapped[float] = mapped_column(Float, nullable=False, default=0.05)
    decay_rate_active: Mapped[float] = mapped_column(Float, nullable=False, default=0.03)
    decay_rate_unstable: Mapped[float] = mapped_column(Float, nullable=False, default=0.07)
    decay_rate_flatline: Mapped[float] = mapped_column(Float, nullable=False, default=0.10)

    line_color: Mapped[int | None] = mapped_column(Integer, nullable=True)
    line_width: Mapped[float] = mapped_column(Float, nullable=False, default=3.0)
    glow_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    glow_blur_sigma: Mapped[float] = mapped_column(Float, nullable=False, default=8.0)

    use_fixed_dt: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    fixed_dt_seconds: Mapped[float] = mapped_column(Float, nullable=False, default=1.0 / 30.0)

    pulse_max_intensity: Mapped[float] = mapped_column(Float, nullable=False, default=0.6)
    pulse_gravity: Mapped[float] = mapped_column(Float, nullable=False, default=0.003)
    pulse_impulse: Mapped[float] = mapped_column(Float, nullable=False, default=0.16)

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
