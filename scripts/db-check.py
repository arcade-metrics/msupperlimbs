"""Checks the Postgres connection given by the DATABASE_URL environment variable.

Prints only a masked host, the server version and the table list. The URL,
user and password are never printed. Run through scripts\\db-check.ps1 (uses the old\\backend\\.venv python).
"""

import os
import re
import sys
from urllib.parse import urlparse

try:
    import psycopg2
except ImportError:
    print("psycopg2 em falta: corra com o python do old\\backend\\.venv")
    sys.exit(2)

url = os.environ.get("DATABASE_URL", "")
if not url:
    print("DATABASE_URL não definida no ambiente.")
    sys.exit(2)

# SQLAlchemy style (postgresql+asyncpg://) -> libpq style
url = re.sub(r"^postgres(ql)?\+\w+://", "postgresql://", url)
parts = urlparse(url)
host = parts.hostname or ""
if host not in ("localhost", "127.0.0.1"):
    host = re.sub(r"^([^.]{3})[^.]*", r"\1***", host)
print(
    f"host={host} port={parts.port} db={parts.path.lstrip('/')} "
    f"user={'sim' if parts.username else 'não'} "
    f"password={'sim' if parts.password else 'não'} "
    f"sslmode={'na url' if 'sslmode' in (parts.query or '') else 'omisso'}"
)

try:
    conn = psycopg2.connect(url, connect_timeout=10)
except Exception as exc:  # noqa: BLE001 - report any driver error
    print(f"LIGAÇÃO FALHOU: {type(exc).__name__}: {str(exc).strip()[:300]}")
    sys.exit(1)

with conn, conn.cursor() as cur:
    cur.execute("select version(), current_database(), now()")
    version, database, now = cur.fetchone()
    print(f"LIGAÇÃO OK: {version.split(',')[0]} | db={database} | {now:%Y-%m-%d %H:%M:%S%z}")

    cur.execute(
        "select table_schema, table_name from information_schema.tables "
        "where table_schema not in ('pg_catalog', 'information_schema') "
        "order by 1, 2"
    )
    tables = [t if s == "public" else f"{s}.{t}" for s, t in cur.fetchall()]
    print(f"tabelas={len(tables)}: {', '.join(tables)}")

    cur.execute(
        "select 1 from information_schema.tables "
        "where table_schema = 'public' and table_name = 'alembic_version'"
    )
    if cur.fetchone():
        cur.execute("select version_num from alembic_version")
        print(f"alembic_version={[row[0] for row in cur.fetchall()]}")
conn.close()
