from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from app.services.rapid_settings_service import default_rapid_settings
from app.services.fnose_settings_service import (
    default_fnose_adv_settings,
    default_fnose_settings,
)


async def register_user(db: AsyncSession, data: RegisterRequest) -> tuple[User, TokenResponse]:
    if not data.consent:
        raise HTTPException(status_code=400, detail="Consent is required")

    existing = await db.scalar(select(User).where(User.email == data.email.lower()))
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    now = datetime.now(timezone.utc)
    user = User(
        email=data.email.lower(),
        password_hash=hash_password(data.password),
        name=data.name.strip(),
        consent_at=now,
        created_at=now,
        last_access=now,
    )
    db.add(user)
    await db.flush()
    db.add(default_rapid_settings(user.id))
    db.add(default_fnose_settings(user.id))
    db.add(default_fnose_adv_settings(user.id))
    await db.commit()
    await db.refresh(user)
    return user, _tokens_for(user)


async def login_user(db: AsyncSession, data: LoginRequest) -> tuple[User, TokenResponse]:
    user = await db.scalar(select(User).where(User.email == data.email.lower()))
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    user.last_access = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(user)
    return user, _tokens_for(user)


def user_to_response(user: User) -> UserResponse:
    return UserResponse.model_validate(user)


def _tokens_for(user: User) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )
