import uuid

import pytest
from httpx import AsyncClient


async def _register(client: AsyncClient) -> str:
    email = f"rapid_{uuid.uuid4().hex[:8]}@example.com"
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "secret12",
            "name": "Rapid",
            "consent": True,
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["tokens"]["access_token"]


@pytest.mark.asyncio
async def test_rapid_settings_get_put_restore(client: AsyncClient):
    token = await _register(client)
    headers = {"Authorization": f"Bearer {token}"}

    get1 = await client.get("/api/v1/rapid/settings", headers=headers)
    assert get1.status_code == 200
    body = get1.json()
    assert body["game_mode"] == "rightHand"
    assert body["total_time"] == 30

    put = await client.put(
        "/api/v1/rapid/settings",
        headers=headers,
        json={"game_mode": "leftHand", "total_time": 45, "visualization_type": "bar"},
    )
    assert put.status_code == 200
    assert put.json()["game_mode"] == "leftHand"
    assert put.json()["total_time"] == 45

    get2 = await client.get("/api/v1/rapid/settings", headers=headers)
    assert get2.json()["visualization_type"] == "bar"

    restore = await client.post("/api/v1/rapid/settings/restore", headers=headers)
    assert restore.status_code == 200
    assert restore.json()["game_mode"] == "rightHand"
    assert restore.json()["total_time"] == 30


@pytest.mark.asyncio
async def test_rapid_match_create_with_chunks(client: AsyncClient):
    token = await _register(client)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "device_model": "pytest-device",
        "total_time": 30,
        "game_mode": "rightHand",
        "visualization_type": "line",
        "tap_count": 2,
        "avg_tap_frequency": 0.06,
        "avg_pulse_height": 0.3,
        "max_pulse_height": 0.7,
        "settings_snapshot": {"total_time": 30},
        "tap_events": [{"timestamp": 1}, {"timestamp": 2}],
        "pulse_events": [{"timestamp": 1, "eventType": "tick"}],
        "pose_samples": [{"timestamp": 1, "hands": []}],
    }
    response = await client.post("/api/v1/rapid/matches", headers=headers, json=payload)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["tap_count"] == 2
    assert body["tap_chunk_count"] == 1
    assert body["pulse_chunk_count"] == 1
    assert body["pose_chunk_count"] == 1
    assert body["session_id"]


@pytest.mark.asyncio
async def test_rapid_match_requires_auth(client: AsyncClient):
    response = await client.post(
        "/api/v1/rapid/matches",
        json={
            "total_time": 30,
            "game_mode": "rightHand",
            "visualization_type": "line",
            "tap_count": 0,
        },
    )
    assert response.status_code == 401
