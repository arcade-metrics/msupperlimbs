from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.rapid_match import (
    RapidMatch,
    RapidPoseChunk,
    RapidPulseChunk,
    RapidTapChunk,
)
from app.models.session import Session
from app.schemas.rapid import RapidMatchCreate


def _today_yyyymmdd() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d")


def _chunk_payload(items: list, max_items: int = 2000) -> list[list]:
    if not items:
        return []
    return [items[i : i + max_items] for i in range(0, len(items), max_items)]


async def get_or_create_today_session(
    db: AsyncSession,
    user_id: UUID,
    device_model: str | None = None,
) -> Session:
    date = _today_yyyymmdd()
    session = await db.scalar(
        select(Session).where(Session.user_id == user_id, Session.date == date)
    )
    if session:
        if device_model and not session.device_model:
            session.device_model = device_model
            await db.commit()
            await db.refresh(session)
        return session

    session = Session(user_id=user_id, date=date, device_model=device_model)
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


async def create_match(
    db: AsyncSession,
    user_id: UUID,
    data: RapidMatchCreate,
) -> tuple[RapidMatch, int, int, int]:
    session = await get_or_create_today_session(db, user_id, data.device_model)

    match = RapidMatch(
        session_id=session.id,
        user_id=user_id,
        total_time=data.total_time,
        game_mode=data.game_mode,
        visualization_type=data.visualization_type,
        tap_count=data.tap_count,
        avg_tap_frequency=data.avg_tap_frequency,
        avg_pulse_height=data.avg_pulse_height,
        max_pulse_height=data.max_pulse_height,
        settings_snapshot=data.settings_snapshot,
        screen_width=data.screen_width,
        screen_height=data.screen_height,
        image_width=data.image_width,
        image_height=data.image_height,
        started_at_ms=data.started_at_ms,
        ended_at_ms=data.ended_at_ms,
        preview=data.preview,
        data_contract_version=data.data_contract_version,
        is_valid_match=data.is_valid_match,
    )
    db.add(match)
    await db.flush()

    tap_chunks = _chunk_payload(data.tap_events)
    pulse_chunks = _chunk_payload(data.pulse_events)
    pose_chunks = _chunk_payload(data.pose_samples)

    for i, payload in enumerate(tap_chunks):
        db.add(RapidTapChunk(match_id=match.id, chunk_index=i, payload=payload))
    for i, payload in enumerate(pulse_chunks):
        db.add(RapidPulseChunk(match_id=match.id, chunk_index=i, payload=payload))
    for i, payload in enumerate(pose_chunks):
        db.add(RapidPoseChunk(match_id=match.id, chunk_index=i, payload=payload))

    await db.commit()
    await db.refresh(match)
    return match, len(tap_chunks), len(pulse_chunks), len(pose_chunks)
