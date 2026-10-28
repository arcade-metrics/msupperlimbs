from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fnose_pregame import (
    FnosePregameEventChunk,
    FnosePregamePoseChunk,
    FnosePregameRun,
    FnosePregameSensorChunk,
)
from app.schemas.fnose_pregame import FnosePregameCreate
from app.services.rapid_match_service import _chunk_payload, get_or_create_today_session


def _ms_to_utc(ms: int) -> datetime:
    return datetime.fromtimestamp(ms / 1000.0, tz=timezone.utc)


async def create_pregame_run(
    db: AsyncSession,
    user_id: UUID,
    data: FnosePregameCreate,
) -> tuple[FnosePregameRun, int, int, int]:
    session = await get_or_create_today_session(db, user_id, data.device_model)
    run = FnosePregameRun(
        user_id=user_id,
        session_id=session.id,
        game_mode=data.game_mode,
        device_model=data.device_model,
        status=data.status,
        started_at=_ms_to_utc(data.started_at_ms),
        ended_at=_ms_to_utc(data.ended_at_ms),
        target_calibration_offset=data.target_calibration_offset,
        screen_width=data.screen_width,
        screen_height=data.screen_height,
        image_width=data.image_width,
        image_height=data.image_height,
        preview=data.preview,
        data_contract_version=data.data_contract_version,
        settings_snapshot=data.settings_snapshot,
        adv_settings_snapshot=data.adv_settings_snapshot,
    )
    db.add(run)
    await db.flush()

    pose_chunks = _chunk_payload(data.pose_samples)
    sensor_chunks = _chunk_payload(data.sensor_samples)
    event_chunks = _chunk_payload(data.events)

    for i, payload in enumerate(pose_chunks):
        db.add(
            FnosePregamePoseChunk(
                pregame_run_id=run.id, chunk_index=i, payload=payload
            )
        )
    for i, payload in enumerate(sensor_chunks):
        db.add(
            FnosePregameSensorChunk(
                pregame_run_id=run.id, chunk_index=i, payload=payload
            )
        )
    for i, payload in enumerate(event_chunks):
        db.add(
            FnosePregameEventChunk(
                pregame_run_id=run.id, chunk_index=i, payload=payload
            )
        )

    await db.commit()
    await db.refresh(run)
    return run, len(pose_chunks), len(sensor_chunks), len(event_chunks)


async def link_pregame_to_match(
    db: AsyncSession,
    user_id: UUID,
    pregame_run_id: UUID,
    match_id: UUID,
) -> None:
    run = await db.scalar(
        select(FnosePregameRun).where(
            FnosePregameRun.id == pregame_run_id,
            FnosePregameRun.user_id == user_id,
        )
    )
    if run is None:
        return
    run.match_id = match_id
    await db.commit()
