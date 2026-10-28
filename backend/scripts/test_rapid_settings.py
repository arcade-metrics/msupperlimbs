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


email = f"rapid_{uuid.uuid4().hex[:8]}@example.com"
password = "test1234"
print("health", req("GET", "/health"))
st, reg = req(
    "POST",
    "/api/v1/auth/register",
    {
        "email": email,
        "password": password,
        "name": "Rapid Tester",
        "consent": True,
    },
)
print("register", st)
assert st == 200, reg
token = reg["tokens"]["access_token"]

st, settings = req("GET", "/api/v1/rapid/settings", token=token)
print(
    "get settings",
    st,
    settings.get("game_mode"),
    settings.get("total_time"),
    settings.get("visualization_type"),
)
assert st == 200
assert settings["game_mode"] == "rightHand"
assert settings["total_time"] == 30

st, updated = req(
    "PUT",
    "/api/v1/rapid/settings",
    {
        "game_mode": "leftHand",
        "total_time": 45,
        "visualization_type": "bar",
    },
    token=token,
)
print(
    "put settings",
    st,
    updated.get("game_mode"),
    updated.get("total_time"),
    updated.get("visualization_type"),
)
assert st == 200
assert updated["game_mode"] == "leftHand"
assert updated["total_time"] == 45
assert updated["visualization_type"] == "bar"

st, again = req("GET", "/api/v1/rapid/settings", token=token)
print(
    "get again",
    st,
    again.get("game_mode"),
    again.get("total_time"),
    again.get("visualization_type"),
)
assert again["game_mode"] == "leftHand"
assert again["total_time"] == 45
assert again["visualization_type"] == "bar"

st, restored = req("POST", "/api/v1/rapid/settings/restore", token=token)
print("restore", st, restored.get("game_mode"), restored.get("total_time"))
assert restored["game_mode"] == "rightHand"
assert restored["total_time"] == 30
print("API_OK")
