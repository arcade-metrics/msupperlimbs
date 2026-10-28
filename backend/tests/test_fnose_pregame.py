import uuid
from datetime import datetime, timezone

import pytest
from httpx import AsyncClient


async def _register(client: AsyncClient) -> str:
    email = f"pregame_{uuid.uuid4().hex[:8]}@example.com"
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "secret12",
            "name": "Pregame",
            "consent": True,
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["tokens"]["access_token"]


@pytest.mark.asyncio
async def test_fnose_pregame_create_with_chunks(client: AsyncClient):
    token = await _register(client)
    headers = {"Authorization": f"Bearer {token}"}
    now = int(datetime.now(timezone.utc).timestamp() * 1000)

    payload = {
        "device_model": "pytest-device",
        "game_mode": "leftHand",
        "status": "completed",
        "started_at_ms": now - 5000,
        "ended_at_ms": now,
        "target_calibration_offset": {"dx": 0.0, "dy": 0.0},
        "pose_samples": [{"t": now - 4000, "landmarks": [{"index": 0, "x": 0.5, "y": 0.3, "z": 0}]}],
        "sensor_samples": [{"t": now - 3900, "ax": 0.1, "ay": 0.2, "az": 9.8, "angle": 90.0}],
        "events": [
            {"t": now - 5000, "type": "calibration_start"},
            {"t": now - 3000, "type": "stability_ok"},
            {"t": now, "type": "game_start"},
        ],
    }
    response = await client.post("/api/v1/fnose/pregame", headers=headers, json=payload)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "completed"
    assert body["pose_chunk_count"] == 1
    assert body["sensor_chunk_count"] == 1
    assert body["event_chunk_count"] == 1
    pregame_id = body["id"]

    match = await client.post(
        "/api/v1/fnose/matches",
        headers=headers,
        json={
            "total_time": 60,
            "game_mode": "leftHand",
            "total_sparks": 1,
            "pregame_run_id": pregame_id,
        },
    )
    assert match.status_code == 200, match.text
    assert match.json()["pregame_run_id"] == pregame_id


@pytest.mark.asyncio
async def test_fnose_pregame_requires_auth(client: AsyncClient):
    now = int(datetime.now(timezone.utc).timestamp() * 1000)
    response = await client.post(
        "/api/v1/fnose/pregame",
        json={
            "game_mode": "leftHand",
            "started_at_ms": now,
            "ended_at_ms": now,
        },
    )
    assert response.status_code == 401
