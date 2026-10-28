from sqlalchemy import create_engine, text

from app.core.config import settings

url = settings.database_url.replace("postgresql+asyncpg://", "postgresql+psycopg2://")
engine = create_engine(url)
with engine.connect() as conn:
    rows = conn.execute(
        text(
            """
            SELECT u.email, r.game_mode, r.visualization_type, r.total_time, r.updated_at
            FROM users u
            JOIN rapid_settings r ON r.user_id = u.id
            ORDER BY u.email
            """
        )
    ).fetchall()
    for row in rows:
        print(dict(row._mapping))
