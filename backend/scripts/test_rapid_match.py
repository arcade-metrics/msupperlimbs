"""API smoke: create rapid match with chunks."""

import json
import urllib.error
import urllib.request
import uuid

BASE = "http://127.0.0.1:8000"


def req(method, path, body=None, token=None):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        BASE + path, data=data, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(request) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode()


email = f"match_{uuid.uuid4().hex[:8]}@example.com"
st, reg = req(
    "POST",
    "/api/v1/auth/register",
    {
        "email": email,
        "password": "test1234",
        "name": "Match Tester",
        "consent": True,
    },
)
assert st == 200, reg
token = reg["tokens"]["access_token"]

payload = {
    "device_model": "test-device",
    "total_time": 30,
    "game_mode": "rightHand",
    "visualization_type": "line",
    "tap_count": 3,
    "avg_tap_frequency": 0.1,
    "avg_pulse_height": 0.4,
    "max_pulse_height": 0.8,
    "settings_snapshot": {"total_time": 30},
    "screen_width": 1080,
    "screen_height": 2340,
    "tap_events": [
        {"timestamp": 1, "tappedFinger": "tip"},
        {"timestamp": 2, "tappedFinger": "tip"},
        {"timestamp": 3, "tappedFinger": "tip"},
    ],
    "pulse_events": [{"timestamp": 1, "pulseHeight": 0.5, "eventType": "tick"}],
    "pose_samples": [{"timestamp": 1, "hands": []}],
}

st, match = req("POST", "/api/v1/rapid/matches", payload, token=token)
print("create match", st, match if isinstance(match, dict) else match)
assert st == 200, match
assert match["tap_count"] == 3
assert match["tap_chunk_count"] == 1
assert match["pulse_chunk_count"] == 1
assert match["pose_chunk_count"] == 1
assert match["session_id"]
print("MATCH_API_OK", match["id"])
