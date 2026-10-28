import uuid

import pytest
from httpx import AsyncClient


async def _register(client: AsyncClient) -> str:
    email = f"fnose_{uuid.uuid4().hex[:8]}@example.com"
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "secret12",
            "name": "Fnose",
            "consent": True,
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["tokens"]["access_token"]


@pytest.mark.asyncio
async def test_fnose_settings_get_put_restore(client: AsyncClient):
    token = await _register(client)
    headers = {"Authorization": f"Bearer {token}"}

    get1 = await client.get("/api/v1/fnose/settings", headers=headers)
    assert get1.status_code == 200
    body = get1.json()
    assert body["game_mode"] == "leftHand"
    assert body["total_time"] == 60
    assert body["target_size"] == 1.0

    put = await client.put(
        "/api/v1/fnose/settings",
        headers=headers,
        json={"game_mode": "rightHand", "total_time": 90, "target_size": 1.2},
    )
    assert put.status_code == 200
    assert put.json()["game_mode"] == "rightHand"
    assert put.json()["total_time"] == 90

    restore = await client.post("/api/v1/fnose/settings/restore", headers=headers)
    assert restore.status_code == 200
    assert restore.json()["game_mode"] == "leftHand"
    assert restore.json()["total_time"] == 60


@pytest.mark.asyncio
async def test_fnose_adv_settings(client: AsyncClient):
    token = await _register(client)
    headers = {"Authorization": f"Bearer {token}"}

    get1 = await client.get("/api/v1/fnose/adv-settings", headers=headers)
    assert get1.status_code == 200
    data = get1.json()["data"]
    assert "target_scale" in data
    assert "x_target_position" in data

    put = await client.put(
        "/api/v1/fnose/adv-settings",
        headers=headers,
        json={"data": {"target_scale": 0.5}},
    )
    assert put.status_code == 200
    assert put.json()["data"]["target_scale"] == 0.5

    restore = await client.post("/api/v1/fnose/adv-settings/restore", headers=headers)
    assert restore.status_code == 200
    assert restore.json()["data"]["target_scale"] == 0.45


@pytest.mark.asyncio
async def test_fnose_match_create_with_chunks(client: AsyncClient):
    token = await _register(client)
    headers = {"Authorization": f"Bearer {token}"}

    payload = {
        "device_model": "pytest-device",
        "total_time": 60,
        "game_mode": "leftHand",
        "total_left_sparks": 2,
        "total_right_sparks": 0,
        "total_sparks": 2,
        "avg_distance": 0.4,
        "avg_angle": 155.0,
        "settings_snapshot": {"total_time": 60},
        "adv_settings_snapshot": {"target_scale": 0.45},
        "pose_samples": [{"timestamp": 1, "pose": []}],
        "touch_events": [{"timestamp": 1, "isLeft": True}],
    }
    response = await client.post("/api/v1/fnose/matches", headers=headers, json=payload)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["total_sparks"] == 2
    assert body["pose_chunk_count"] == 1
    assert body["touch_chunk_count"] == 1
    assert body["session_id"]


@pytest.mark.asyncio
async def test_fnose_match_requires_auth(client: AsyncClient):
    response = await client.post(
        "/api/v1/fnose/matches",
        json={
            "total_time": 60,
            "game_mode": "leftHand",
            "total_sparks": 0,
        },
    )
    assert response.status_code == 401
