from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.security import create_access_token, create_refresh_token, get_user_id_from_token
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=dict)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    user, tokens = await auth_service.register_user(db, data)
    return {
        "user": auth_service.user_to_response(user),
        "tokens": tokens,
    }


@router.post("/login", response_model=dict)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    user, tokens = await auth_service.login_user(db, data)
    return {
        "user": auth_service.user_to_response(user),
        "tokens": tokens,
    }


@router.post("/refresh", response_model=TokenResponse)
async def refresh(authorization: str | None = Header(default=None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing refresh token")
    token = authorization.split(" ", 1)[1]
    try:
        user_id = get_user_id_from_token(token, expected_type="refresh")
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc
    return TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )


@router.get("/me", response_model=UserResponse)
async def me(user: User = Depends(get_current_user)):
    return auth_service.user_to_response(user)
