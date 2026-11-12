# Relatórios (somente leitura)

Módulo de consulta e exportação de dados do MS Upper Limbs. **Não faz parte do app**: roda no PC,
lê o Postgres do ciatec-core e grava arquivos em `output/`. As consultas são os `.sql` de
[../../queries](../../queries), a mesma fonte usada no pgAdmin.

## Uso

```powershell
.\scripts\report.ps1 list
.\scripts\report.ps1 fnose-matches -Format xlsx
.\scripts\report.ps1 fnose-match -MatchId <uuid> -Format xlsx      # uma aba por consulta
.\scripts\report.ps1 fnose-match-2-eventos -MatchId <uuid> -Format csv
```

| Parâmetro | Descrição |
|---|---|
| `Name` | `list`, um relatório (`fnose-match`) ou o nome de um `.sql` de `queries/`. |
| `-MatchId` | UUID da partida (consultas que usam `%(match_id)s`). |
| `-Format` | `xlsx` (padrão), `csv` ou `json`. Relatório com várias consultas: XLSX = uma aba cada; CSV = um arquivo cada. |
| `-FrameLimit` | Máximo de frames de pose (padrão: todos). |
| `-Out` | Pasta de saída. Padrão: `output\matches\<match_id>\` nas consultas de partida, senão `output\`. |
| `-EnvFile` | Arquivo `.env` de onde ler **só** a chave `DATABASE_URL`. |

Primeira execução: o script cria `tools\.venv` e instala `requirements.txt`.

## Conexão

`DATABASE_URL` na sessão do PowerShell; a URL nunca é impressa.

```powershell
$env:DATABASE_URL = "postgresql://utilizador_readonly:...@host:5432/db?sslmode=require"
```

Use um usuário do Postgres **só com `SELECT`**; é a camada de proteção do próprio banco, por cima
das do script.

## Garantias de só leitura

1. O SQL é validado antes de ligar: um único `SELECT`/`WITH`, sem `INSERT/UPDATE/DELETE/DDL/COPY/SET/INTO`
   nem funções com efeito (`nextval`, `pg_sleep`, `set_config`, `pg_terminate_backend`…).
2. A sessão abre com `default_transaction_read_only = on`.
3. A transação é `READ ONLY` e termina sempre em `ROLLBACK`.
4. `statement_timeout` de 120 s por consulta.

## Adicionar uma consulta ou relatório

- **Consulta avulsa:** crie `queries/<nome>.sql` (só `SELECT`). Use `%(match_id)s` para o UUID.
  Ela aparece em `list` e roda por `report.ps1 <nome>`.
- **Relatório com várias abas:** acrescente uma entrada em `BUNDLES` no [report.py](report.py).
- No pgAdmin, troque `%(match_id)s` por `'<uuid>'` (e `%(frame_limit)s` por um número, ou `NULL`
  para sem limite).

## Cuidados

- `output/` e `tools/.venv/` estão no `.gitignore`: os dados são de participantes de pesquisa.
  Não commitar, não enviar a serviços externos.
- No XLSX, células acima de 32 000 caracteres são truncadas (limite do Excel); use CSV/JSON para o dado completo.
