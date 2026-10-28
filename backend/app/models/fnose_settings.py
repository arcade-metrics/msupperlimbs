from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class FnoseSettings(Base):
    __tablename__ = "fnose_settings"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    game_mode: Mapped[str] = mapped_column(String(32), nullable=False, default="leftHand")
    show_info_video: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    total_time: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    target_size: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
