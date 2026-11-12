"""Consultas e relatórios SOMENTE LEITURA do MS Upper Limbs (fora do app).

Lê os .sql de ``queries/`` e exporta o resultado em CSV, JSON ou XLSX.
A ligação vem de ``DATABASE_URL`` (ambiente). A URL nunca é impressa.

Garantias de só leitura (todas ativas ao mesmo tempo):
  1. o SQL é validado: um único SELECT/WITH, sem palavras de escrita/DDL;
  2. a sessão abre com ``default_transaction_read_only = on``;
  3. a transação é READ ONLY e termina sempre em ROLLBACK;
  4. ``statement_timeout`` limita cada consulta.
Para a camada final, use um utilizador do Postgres só com SELECT.

Uso (via scripts\\report.ps1):
  report.py list
  report.py run fnose-matches --format xlsx
  report.py run fnose-match --match-id <uuid> --format xlsx
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import decimal
import json
import os
import re
import sys
import uuid
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
QUERIES_DIR = ROOT / "queries"
DEFAULT_OUT = ROOT / "output"
MATCHES_OUT = DEFAULT_OUT / "matches"  # output\matches\<match_id>\

# Relatórios que juntam várias consultas (uma aba/arquivo por consulta).
BUNDLES: dict[str, dict[str, Any]] = {
    "fnose-match": {
        "descricao": "FNose: tudo de uma partida (resumo, eventos, pose, calibração). Exige --match-id.",
        "sheets": [
            ("resumo", "fnose-match-1-resumo"),
            ("eventos", "fnose-match-2-eventos"),
            ("pose_chunks", "fnose-match-3-pose-chunks"),
            ("pose_frames", "fnose-match-4-pose-frames"),
            ("calibracao", "fnose-match-extra-calibracao"),
        ],
    },
}

STATEMENT_TIMEOUT_MS = 120_000
XLSX_CELL_MAX = 32_000  # limite do Excel é 32 767 caracteres por célula
PARAM_RE = re.compile(r"%\((\w+)\)s")

# Qualquer uma destas palavras (fora de comentários/strings) reprova o SQL.
FORBIDDEN = re.compile(
    r"\b(insert|update|delete|merge|drop|alter|create|truncate|grant|revoke|"
    r"copy|call|do|execute|prepare|vacuum|analyze|reindex|cluster|refresh|"
    r"lock|comment|security|reset|set|listen|notify|unlisten|discard|"
    r"into|nextval|setval|set_config|pg_sleep|pg_terminate_backend|"
    r"pg_cancel_backend|pg_reload_conf|lo_import|lo_export|lo_unlink|"
    r"dblink|pg_read_file|pg_ls_dir)\b",
    re.IGNORECASE,
)


class ReportError(Exception):
    """Erro esperado: mensagem curta para o utilizador."""


# --------------------------------------------------------------------- SQL --


def strip_sql(sql: str) -> str:
    """Remove comentários e conteúdo de strings, para inspecionar só a estrutura."""
    sql = re.sub(r"--[^\n]*", " ", sql)
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)
    sql = re.sub(r"'(?:[^']|'')*'", "''", sql)
    sql = re.sub(r'"(?:[^"]|"")*"', '""', sql)
    return sql


def assert_read_only_sql(sql: str, label: str) -> None:
    """Levanta ReportError se o SQL não for um único SELECT/WITH de leitura."""
    body = strip_sql(sql).strip()
    body = body.rstrip(";").strip()
    if ";" in body:
        raise ReportError(f"{label}: mais de uma instrução; só um SELECT é permitido.")
    if not re.match(r"(?is)^(select|with)\b", body):
        raise ReportError(f"{label}: tem de começar com SELECT ou WITH.")
    hit = FORBIDDEN.search(body)
    if hit:
        raise ReportError(f"{label}: palavra não permitida em modo leitura: {hit.group(0)!r}.")


def load_sql(stem: str) -> str:
    path = QUERIES_DIR / f"{stem}.sql"
    if not path.is_file():
        raise ReportError(f"Consulta não encontrada: queries/{stem}.sql")
    sql = path.read_text(encoding="utf-8")
    assert_read_only_sql(sql, f"{stem}.sql")
    return sql


def required_params(sql: str) -> set[str]:
    return set(PARAM_RE.findall(strip_comments_only(sql)))


def strip_comments_only(sql: str) -> str:
    sql = re.sub(r"--[^\n]*", " ", sql)
    return re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)


def available_queries() -> list[str]:
    return sorted(p.stem for p in QUERIES_DIR.glob("*.sql"))


# -------------------------------------------------------------- ligação ------


def connect():
    """Abre uma ligação READ ONLY. Nunca imprime a URL."""
    try:
        import psycopg
    except ImportError as exc:
        raise ReportError(
            "psycopg em falta. Corra scripts\\report.ps1 (instala tools\\.venv)."
        ) from exc

    url = os.environ.get("DATABASE_URL", "").strip()
    if not url:
        raise ReportError(
            'DATABASE_URL não definida. Defina-a na sessão ($env:DATABASE_URL = "...") '
            "ou use -EnvFile no report.ps1."
        )
    # Estilo SQLAlchemy (postgresql+asyncpg://) -> libpq
    url = re.sub(r"^postgres(ql)?\+\w+://", "postgresql://", url)
    try:
        conn = psycopg.connect(
            url,
            connect_timeout=15,
            options=(
                "-c default_transaction_read_only=on "
                f"-c statement_timeout={STATEMENT_TIMEOUT_MS} "
                "-c idle_in_transaction_session_timeout=300000"
            ),
            autocommit=False,
        )
        conn.read_only = True
    except Exception as exc:  # noqa: BLE001 - não vazar host/utilizador na mensagem
        raise ReportError(
            f"Falha ao ligar ao banco ({type(exc).__name__}). Verifique DATABASE_URL, rede e SSL."
        ) from None
    return conn


def run_query(conn, sql: str, params: dict[str, Any]) -> tuple[list[str], list[tuple]]:
    needed = required_params(sql)
    bound = {k: params.get(k) for k in needed}
    with conn.cursor() as cur:
        cur.execute(sql, bound if needed else None)
        columns = [d.name for d in cur.description] if cur.description else []
        rows = cur.fetchall() if cur.description else []
    return columns, rows


# ------------------------------------------------------------- exportação ----


def to_cell(value: Any, *, xlsx: bool = False) -> Any:
    """Converte um valor do Postgres para algo gravável em CSV/XLSX."""
    if value is None:
        return None
    if isinstance(value, (dict, list)):
        text = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    elif isinstance(value, (dt.datetime, dt.date, dt.time)):
        text = value.isoformat()
    elif isinstance(value, uuid.UUID):
        text = str(value)
    elif isinstance(value, decimal.Decimal):
        return float(value) if xlsx else str(value)
    elif isinstance(value, (bytes, memoryview)):
        text = bytes(value).hex()
    elif isinstance(value, (int, float, bool)):
        return value
    else:
        text = str(value)
    if xlsx and len(text) > XLSX_CELL_MAX:
        text = text[:XLSX_CELL_MAX] + "…[truncado]"
    return text


def json_default(value: Any) -> Any:
    if isinstance(value, (dt.datetime, dt.date, dt.time)):
        return value.isoformat()
    if isinstance(value, (uuid.UUID, decimal.Decimal)):
        return str(value)
    if isinstance(value, (bytes, memoryview)):
        return bytes(value).hex()
    return str(value)


def write_csv(path: Path, columns: list[str], rows: list[tuple]) -> None:
    with path.open("w", newline="", encoding="utf-8-sig") as fh:  # BOM: Excel abre com acentos
        writer = csv.writer(fh)
        writer.writerow(columns)
        for row in rows:
            writer.writerow([to_cell(v) for v in row])


def write_json(path: Path, results: dict[str, tuple[list[str], list[tuple]]]) -> None:
    payload = {
        name: [dict(zip(cols, row)) for row in rows] for name, (cols, rows) in results.items()
    }
    with path.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False, indent=2, default=json_default)


def write_xlsx(path: Path, results: dict[str, tuple[list[str], list[tuple]]]) -> None:
    from openpyxl import Workbook
    from openpyxl.styles import Font
    from openpyxl.utils import get_column_letter

    wb = Workbook()
    wb.remove(wb.active)
    for name, (cols, rows) in results.items():
        ws = wb.create_sheet(title=name[:31])
        ws.append(cols)
        for cell in ws[1]:
            cell.font = Font(bold=True)
        for row in rows:
            ws.append([to_cell(v, xlsx=True) for v in row])
        ws.freeze_panes = "A2"
        for idx, col in enumerate(cols, start=1):
            widest = max([len(col)] + [len(str(r[idx - 1])) for r in rows[:200] if r[idx - 1] is not None])
            ws.column_dimensions[get_column_letter(idx)].width = min(max(widest + 2, 10), 60)
    wb.save(path)


def export(
    name: str,
    results: dict[str, tuple[list[str], list[tuple]]],
    fmt: str,
    out_dir: Path,
    suffix: str,
) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    base = f"{name}{suffix}_{stamp}"
    if fmt == "xlsx":
        path = out_dir / f"{base}.xlsx"
        write_xlsx(path, results)
        return [path]
    if fmt == "json":
        path = out_dir / f"{base}.json"
        write_json(path, results)
        return [path]
    paths = []
    for sheet, (cols, rows) in results.items():
        piece = base if len(results) == 1 else f"{base}_{sheet}"
        path = out_dir / f"{piece}.csv"
        write_csv(path, cols, rows)
        paths.append(path)
    return paths


# -------------------------------------------------------------------- CLI ----


def resolve_report(name: str) -> list[tuple[str, str]]:
    """Devolve [(nome_da_aba, stem_do_sql)] para um relatório ou consulta."""
    if name in BUNDLES:
        return list(BUNDLES[name]["sheets"])
    if (QUERIES_DIR / f"{name}.sql").is_file():
        return [(name, name)]
    raise ReportError(f"Relatório desconhecido: {name!r}. Use 'list' para ver os disponíveis.")


def cmd_list(_: argparse.Namespace) -> int:
    print("Relatórios (juntam várias consultas):")
    for name, info in BUNDLES.items():
        print(f"  {name:34} {info['descricao']}")
    print("\nConsultas avulsas (queries/*.sql):")
    for stem in available_queries():
        sql = (QUERIES_DIR / f"{stem}.sql").read_text(encoding="utf-8")
        params = sorted(required_params(sql) - {"frame_limit"})
        extra = f"  [--{' --'.join(p.replace('_', '-') for p in params)}]" if params else ""
        print(f"  {stem}{extra}")
    return 0


def cmd_run(args: argparse.Namespace) -> int:
    sheets = resolve_report(args.name)
    sqls = {sheet: load_sql(stem) for sheet, stem in sheets}  # valida tudo antes de ligar

    params: dict[str, Any] = {"frame_limit": args.frame_limit}
    needed = set().union(*(required_params(s) for s in sqls.values()))
    if "match_id" in needed:
        if not args.match_id:
            raise ReportError("Este relatório exige --match-id <uuid>.")
        try:
            params["match_id"] = str(uuid.UUID(args.match_id))
        except ValueError:
            raise ReportError(f"match_id inválido: {args.match_id!r} (esperado um UUID).") from None

    conn = connect()
    results: dict[str, tuple[list[str], list[tuple]]] = {}
    try:
        for sheet, sql in sqls.items():
            cols, rows = run_query(conn, sql, params)
            results[sheet] = (cols, rows)
            print(f"  {sheet}: {len(rows)} linha(s)")
    except ReportError:
        raise
    except Exception as exc:  # noqa: BLE001
        raise ReportError(f"Erro na consulta ({type(exc).__name__}): {str(exc).strip()[:300]}") from None
    finally:
        conn.rollback()  # nada é gravado, nunca
        conn.close()

    if args.out:
        out_dir, suffix = Path(args.out), ""
    elif "match_id" in params:
        out_dir, suffix = MATCHES_OUT / params["match_id"], ""
    else:
        out_dir, suffix = DEFAULT_OUT, ""
    for path in export(args.name, results, args.format, out_dir, suffix):
        print(f"Gravado: {path}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Consultas e relatórios somente leitura.")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list", help="Lista relatórios e consultas").set_defaults(func=cmd_list)

    run = sub.add_parser("run", help="Executa e exporta um relatório ou consulta")
    run.add_argument("name", help="Nome do relatório ou do .sql (sem extensão)")
    run.add_argument("--match-id", help="UUID da partida")
    run.add_argument("--format", choices=["csv", "xlsx", "json"], default="xlsx")
    run.add_argument(
        "--out",
        help="Pasta de saída (padrão: output\\matches\\<match_id>\\ ou output\\)",
    )
    run.add_argument(
        "--frame-limit",
        type=int,
        default=None,
        help="Máximo de frames de pose (padrão: todos)",
    )
    run.set_defaults(func=cmd_run)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except ReportError as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
