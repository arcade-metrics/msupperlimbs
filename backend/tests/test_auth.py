import uuid

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] in ("ok", "degraded")
    assert "db" in body


@pytest.mark.asyncio
async def test_register_login_me(client: AsyncClient):
    email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "secret12",
            "name": "Tester",
            "consent": True,
        },
    )
    assert register.status_code == 200, register.text
    tokens = register.json()["tokens"]
    assert tokens["access_token"]
    assert tokens["refresh_token"]

    login = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "secret12"},
    )
    assert login.status_code == 200
    access = login.json()["tokens"]["access_token"]

    me = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access}"},
    )
    assert me.status_code == 200
    assert me.json()["email"] == email


@pytest.mark.asyncio
async def test_register_requires_consent(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": f"noconsent_{uuid.uuid4().hex[:8]}@example.com",
            "password": "secret12",
            "name": "No Consent",
            "consent": False,
        },
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_login_invalid(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "nobody@example.com", "password": "wrong"},
    )
    assert response.status_code == 401
