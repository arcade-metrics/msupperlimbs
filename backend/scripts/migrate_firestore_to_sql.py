"""
Optional Firestore JSON → SQL importer (users + rapid_settings).

Expected files under --input:
  users.json          list of {email, name, legacyUid?, consentAt?}
  rapid_settings.json list of {email|legacyUid, ...settings fields camelCase or snake}

Passwords are NOT migrated — a temporary password is generated per user when --apply.
"""

from __future__ import annotations

import argparse
import json
import secrets
import sys
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

# Allow running from backend/
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.config import settings  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.models.rapid_settings import RapidSettings  # noqa: E402
from app.models.user import User  # noqa: E402
from app.services.rapid_settings_service import _DEFAULTS  # noqa: E402


def _sync_url() -> str:
    url = settings.database_url
    if url.startswith("postgresql+asyncpg://"):
        return url.replace("postgresql+asyncpg://", "postgresql+psycopg2://", 1)
    return url


def _load_list(path: Path) -> list[dict]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict) and "documents" in data:
        data = data["documents"]
    if not isinstance(data, list):
        raise SystemExit(f"Expected list in {path}")
    return data


def _camel_to_snake_settings(raw: dict) -> dict:
    mapping = {
        "showInfoVideo": "show_info_video",
        "totalTime": "total_time",
        "gameMode": "game_mode",
        "visualizationType": "visualization_type",
        "tapSensitivity": "tap_sensitivity",
        "tapCooldownMs": "tap_cooldown_ms",
        "maxPoints": "max_points",
        "minY": "min_y",
        "maxY": "max_y",
        "baseline": "baseline",
        "gravityPerSecond": "gravity_per_second",
        "impulseStrength": "impulse_strength",
        "floorRestitution": "floor_restitution",
        "decayRateIdle": "decay_rate_idle",
        "decayRateActive": "decay_rate_active",
        "decayRateUnstable": "decay_rate_unstable",
        "decayRateFlatline": "decay_rate_flatline",
        "lineColor": "line_color",
        "lineWidth": "line_width",
        "glowEnabled": "glow_enabled",
        "glowBlurSigma": "glow_blur_sigma",
        "useFixedDt": "use_fixed_dt",
        "fixedDtSeconds": "fixed_dt_seconds",
        "pulseMaxIntensity": "pulse_max_intensity",
        "pulseGravity": "pulse_gravity",
        "pulseImpulse": "pulse_impulse",
    }
    out = dict(_DEFAULTS)
    for key, value in raw.items():
        snake = mapping.get(key, key)
        if snake in out or snake in {
            "show_info_video",
            "total_time",
            "game_mode",
            "visualization_type",
        }:
            out[snake] = value
    return out


def migrate(input_dir: Path, apply: bool) -> None:
    users_raw = _load_list(input_dir / "users.json")
    settings_raw = _load_list(input_dir / "rapid_settings.json")
    settings_by_email = {
        (s.get("email") or "").lower(): s for s in settings_raw if s.get("email")
    }
    settings_by_uid = {
        s.get("legacyUid") or s.get("userId") or s.get("uid"): s
        for s in settings_raw
        if s.get("legacyUid") or s.get("userId") or s.get("uid")
    }

    print(f"users={len(users_raw)} rapid_settings={len(settings_raw)} apply={apply}")
    if not apply:
        print("Dry-run only. Re-run with --apply to write.")
        for u in users_raw[:5]:
            print("  would import", u.get("email"), u.get("name"))
        if len(users_raw) > 5:
            print(f"  … +{len(users_raw) - 5} more")
        return

    engine = create_engine(_sync_url())
    created = 0
    with Session(engine) as db:
        for raw in users_raw:
            email = (raw.get("email") or "").strip().lower()
            name = (raw.get("name") or email or "imported").strip()
            if not email:
                print("skip user without email", raw)
                continue
            existing = db.scalar(select(User).where(User.email == email))
            if existing:
                print("skip existing", email)
                continue

            temp_password = secrets.token_urlsafe(12)
            consent = raw.get("consentAt") or raw.get("consent_at")
            consent_at = None
            if consent:
                try:
                    consent_at = datetime.fromisoformat(str(consent).replace("Z", "+00:00"))
                except ValueError:
                    consent_at = datetime.now(timezone.utc)
            else:
                consent_at = datetime.now(timezone.utc)

            user = User(
                email=email,
                password_hash=hash_password(temp_password),
                name=name,
                consent_at=consent_at,
            )
            db.add(user)
            db.flush()

            legacy = raw.get("legacyUid") or raw.get("uid") or raw.get("userId")
            src = settings_by_email.get(email) or settings_by_uid.get(legacy) or {}
            fields = _camel_to_snake_settings(src)
            db.add(RapidSettings(user_id=user.id, **fields))
            print(f"imported {email} temp_password={temp_password}")
            created += 1

        db.commit()
    print(f"done created={created}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Firestore JSON → SQL (users/settings)")
    parser.add_argument("--input", type=Path, required=True, help="Folder with JSON exports")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true", help="Write to database")
    args = parser.parse_args()
    apply = bool(args.apply)
    if apply:
        args.dry_run = False
    migrate(args.input, apply=apply)


if __name__ == "__main__":
    main()
