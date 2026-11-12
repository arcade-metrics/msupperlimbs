# Queries (pgAdmin)

Consultas SQL de leitura para inspecionar os dados do MS Upper Limbs no Postgres do ciatec-core.
Só `SELECT`; não alteram nada. Tabelas definidas em `src/api/src/models/msupperlimbs.py` e
`session_match.py` (ciatec-core).

## FNose

| Arquivo | O que faz |
|---|---|
| [fnose-matches.sql](fnose-matches.sql) | Lista as partidas (resumo, métricas, nº de eventos e frames), mais recentes primeiro. |
| [fnose-match-1-resumo.sql](fnose-match-1-resumo.sql) | Uma partida: jogador, métricas, device, settings congeladas. Uma linha. |
| [fnose-match-2-eventos.sql](fnose-match-2-eventos.sql) | Uma partida: eventos (fases, faíscas, alvos), uma linha por evento. |
| [fnose-match-3-pose-chunks.sql](fnose-match-3-pose-chunks.sql) | Uma partida: chunks de pose sem os frames (leve, para conferir a telemetria). |
| [fnose-match-4-pose-frames.sql](fnose-match-4-pose-frames.sql) | Uma partida: frames de landmarks, um por linha. Pesada. |
| [fnose-match-extra-calibracao.sql](fnose-match-extra-calibracao.sql) | Uma partida: calibração que a precedeu. |

## Como usar no pgAdmin

1. No pgAdmin: banco → *Tools* → *Query Tool*.
2. Rode primeiro `fnose-matches.sql` e copie o `match_id` que quer inspecionar.
3. Abra a query desejada (*Open File*), troque `%(match_id)s` por `'<uuid>'` (ex.:
   `'b186394f-d16e-469e-9cee-d25dd6c9597e'`) e execute com `F5`. Na de frames, troque
   `%(frame_limit)s` por um número (ex.: `500`) ou `NULL`.

## Como usar por script (exporta CSV/XLSX/JSON)

Os mesmos arquivos alimentam `.\scripts\report.ps1`, que preenche os parâmetros e exporta para
`output\`. Ver [../tools/reports/README.md](../tools/reports/README.md).

## Notas

- `game_slug` do FNose: `msupperlimbs-fnose`.
- Partida com métricas `NULL` = criada mas não finalizada, ou upload ainda pendente no device
  (falhas de rede ficam no device e são reenviadas).
- Todo tempo dos eventos/frames é `offset_ms` desde o início da sessão.
- Compare `frame_count` somado (query 3) com `frames_pose` da lista para validar o upload.
- Nunca commitar credenciais de conexão aqui.
