from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fnose_match import FnoseMatch, FnosePoseChunk, FnoseTouchChunk
from app.schemas.fnose import FnoseMatchCreate
from app.services import fnose_pregame_service
from app.services.rapid_match_service import _chunk_payload, get_or_create_today_session


async def create_match(
    db: AsyncSession,
    user_id: UUID,
    data: FnoseMatchCreate,
) -> tuple[FnoseMatch, int, int]:
    session = await get_or_create_today_session(db, user_id, data.device_model)
    match = FnoseMatch(
        session_id=session.id,
        user_id=user_id,
        total_time=data.total_time,
        game_mode=data.game_mode,
        total_left_sparks=data.total_left_sparks,
        total_right_sparks=data.total_right_sparks,
        total_sparks=data.total_sparks,
        avg_distance=data.avg_distance,
        avg_angle=data.avg_angle,
        settings_snapshot=data.settings_snapshot,
        adv_settings_snapshot=data.adv_settings_snapshot,
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

    pose_chunks = _chunk_payload(data.pose_samples)
    touch_chunks = _chunk_payload(data.touch_events)
    for i, payload in enumerate(pose_chunks):
        db.add(FnosePoseChunk(match_id=match.id, chunk_index=i, payload=payload))
    for i, payload in enumerate(touch_chunks):
        db.add(FnoseTouchChunk(match_id=match.id, chunk_index=i, payload=payload))

    await db.commit()
    await db.refresh(match)

    if data.pregame_run_id is not None:
        await fnose_pregame_service.link_pregame_to_match(
            db, user_id, data.pregame_run_id, match.id
        )

    return match, len(pose_chunks), len(touch_chunks)
