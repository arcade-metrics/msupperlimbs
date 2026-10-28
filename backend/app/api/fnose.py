from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.fnose import (
    FnoseAdvSettingsResponse,
    FnoseAdvSettingsUpdate,
    FnoseMatchCreate,
    FnoseMatchResponse,
    FnoseSettingsResponse,
    FnoseSettingsUpdate,
)
from app.schemas.fnose_pregame import FnosePregameCreate, FnosePregameResponse
from app.services import fnose_match_service, fnose_pregame_service, fnose_settings_service

router = APIRouter(prefix="/fnose", tags=["fnose"])


@router.get("/settings", response_model=FnoseSettingsResponse)
async def get_settings(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    row = await fnose_settings_service.get_or_create_settings(db, user.id)
    return FnoseSettingsResponse.model_validate(row)


@router.put("/settings", response_model=FnoseSettingsResponse)
async def put_settings(
    data: FnoseSettingsUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        row = await fnose_settings_service.update_settings(
            db, user.id, data.model_dump(exclude_unset=True)
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return FnoseSettingsResponse.model_validate(row)


@router.post("/settings/restore", response_model=FnoseSettingsResponse)
async def restore_settings(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    row = await fnose_settings_service.restore_settings(db, user.id)
    return FnoseSettingsResponse.model_validate(row)


@router.get("/adv-settings", response_model=FnoseAdvSettingsResponse)
async def get_adv_settings(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    row = await fnose_settings_service.get_or_create_adv_settings(db, user.id)
    return FnoseAdvSettingsResponse.model_validate(row)


@router.put("/adv-settings", response_model=FnoseAdvSettingsResponse)
async def put_adv_settings(
    data: FnoseAdvSettingsUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    row = await fnose_settings_service.update_adv_settings(db, user.id, data.data)
    return FnoseAdvSettingsResponse.model_validate(row)


@router.post("/adv-settings/restore", response_model=FnoseAdvSettingsResponse)
async def restore_adv_settings(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    row = await fnose_settings_service.restore_adv_settings(db, user.id)
    return FnoseAdvSettingsResponse.model_validate(row)


@router.post("/pregame", response_model=FnosePregameResponse)
async def create_pregame(
    data: FnosePregameCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    run, pose_n, sensor_n, event_n = await fnose_pregame_service.create_pregame_run(
        db, user.id, data
    )
    return FnosePregameResponse(
        id=run.id,
        session_id=run.session_id,
        user_id=run.user_id,
        match_id=run.match_id,
        status=run.status,
        started_at=run.started_at,
        ended_at=run.ended_at,
        pose_chunk_count=pose_n,
        sensor_chunk_count=sensor_n,
        event_chunk_count=event_n,
    )


@router.post("/matches", response_model=FnoseMatchResponse)
async def create_match(
    data: FnoseMatchCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    match, pose_n, touch_n = await fnose_match_service.create_match(db, user.id, data)
    return FnoseMatchResponse(
        id=match.id,
        session_id=match.session_id,
        user_id=match.user_id,
        total_time=match.total_time,
        game_mode=match.game_mode,
        total_left_sparks=match.total_left_sparks,
        total_right_sparks=match.total_right_sparks,
        total_sparks=match.total_sparks,
        avg_distance=match.avg_distance,
        avg_angle=match.avg_angle,
        is_valid_match=match.is_valid_match,
        created_at=match.created_at,
        pose_chunk_count=pose_n,
        touch_chunk_count=touch_n,
        pregame_run_id=data.pregame_run_id,
    )
