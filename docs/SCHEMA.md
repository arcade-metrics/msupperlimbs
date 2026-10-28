# Schema SQL (estado atual)

## Diagrama lógico

```
users 1──1 rapid_settings
     1──1 fnose_settings
     1──1 fnose_adv_settings
     1──* sessions
              1──* rapid_matches + chunks
              1──* fnose_matches + pose/touch chunks
              1──* fnose_pregame_runs + pose/sensor/event chunks
                        └── match_id opcional → fnose_matches
```

## Migrations Alembic

| Rev | Conteúdo |
|-----|----------|
| `001_users_rapid` | `users`, `rapid_settings` |
| `002_rapid_matches` | `sessions`, `rapid_matches`, chunks pose/tap/pulse |
| `003_fnose` | `fnose_settings`, `fnose_adv_settings`, `fnose_matches` + chunks |
| `004_fnose_pregame` | `fnose_pregame_runs` + pose/sensor/event chunks |

```powershell
cd backend
alembic upgrade head
```

## Tabelas implementadas

### users
| Coluna | Tipo | Notas |
|--------|------|-------|
| id | UUID PK | |
| email | VARCHAR UNIQUE | login |
| password_hash | VARCHAR | bcrypt |
| name | VARCHAR | |
| consent_at | TIMESTAMPTZ NULL | LGPD |
| created_at | TIMESTAMPTZ | |
| last_access | TIMESTAMPTZ | |

### rapid_settings
1:1 com `users` — campos de jogo/pulse/tap (ver API `/api/v1/rapid/settings`).

### sessions
| Coluna | Tipo | Notas |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK | |
| date | CHAR(8) | YYYYMMDD UTC |
| device_model | VARCHAR | |
| created_at | TIMESTAMPTZ | |
| UNIQUE(user_id, date) | | |

### rapid_matches + chunks
Métricas da partida + `payload` JSONB (listas de eventos). Chunks usam `chunk_index`.

## Auth
JWT access (curto) + refresh (sem tabela de refresh nesta versão).
