from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.rapid import (
    RapidMatchCreate,
    RapidMatchResponse,
    RapidSettingsResponse,
    RapidSettingsUpdate,
)
from app.services import rapid_match_service, rapid_settings_service

router = APIRouter(prefix="/rapid", tags=["rapid"])


@router.get("/settings", response_model=RapidSettingsResponse)
async def get_settings(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    settings = await rapid_settings_service.get_or_create_settings(db, user.id)
    return RapidSettingsResponse.model_validate(settings)


@router.put("/settings", response_model=RapidSettingsResponse)
async def put_settings(
    data: RapidSettingsUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        settings = await rapid_settings_service.update_settings(db, user.id, data)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return RapidSettingsResponse.model_validate(settings)


@router.post("/settings/restore", response_model=RapidSettingsResponse)
async def restore_settings(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    settings = await rapid_settings_service.restore_defaults(db, user.id)
    return RapidSettingsResponse.model_validate(settings)


@router.post("/matches", response_model=RapidMatchResponse)
async def create_match(
    data: RapidMatchCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    match, tap_n, pulse_n, pose_n = await rapid_match_service.create_match(
        db, user.id, data
    )
    return RapidMatchResponse(
        id=match.id,
        session_id=match.session_id,
        user_id=match.user_id,
        total_time=match.total_time,
        game_mode=match.game_mode,
        visualization_type=match.visualization_type,
        tap_count=match.tap_count,
        avg_tap_frequency=match.avg_tap_frequency,
        avg_pulse_height=match.avg_pulse_height,
        max_pulse_height=match.max_pulse_height,
        is_valid_match=match.is_valid_match,
        created_at=match.created_at,
        tap_chunk_count=tap_n,
        pulse_chunk_count=pulse_n,
        pose_chunk_count=pose_n,
    )
