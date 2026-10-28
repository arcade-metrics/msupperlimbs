from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.auth import router as auth_router
from app.api.fnose import router as fnose_router
from app.api.rapid import router as rapid_router
from app.core.config import settings
from app.core.database import engine
import app.models  # noqa: F401


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Schema via Alembic: `alembic upgrade head`
    yield


app = FastAPI(title="MS Upper Limbs API", version="0.1.0", lifespan=lifespan)

origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1")
app.include_router(rapid_router, prefix="/api/v1")
app.include_router(fnose_router, prefix="/api/v1")


@app.get("/health")
async def health():
    db_status = "ok"
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception as exc:  # noqa: BLE001 — health must not raise
        db_status = f"error: {exc.__class__.__name__}"
    status = "ok" if db_status == "ok" else "degraded"
    return {"status": status, "db": db_status}
