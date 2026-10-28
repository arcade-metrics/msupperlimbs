# Migração Firestore → SQL (opcional)

O app novo **não** usa Firebase. Se precisares de trazer dados antigos:

## O que mapear

| Firestore | SQL |
|-----------|-----|
| `users/{uid}` | `users` (gera novo UUID; guarda `legacy_uid` só no script/logs) |
| `users/{uid}/settings/rapidSettings` | `rapid_settings` |
| `users/{uid}/sessions/{YYYYMMDD}` | `sessions` |
| `…/rapid_matches/{id}` | `rapid_matches` |
| `…/pose_data`, `tap_data`, `pulse_state_data` | `rapid_*_chunks.payload` (JSONB) |

**Nota:** passwords Firebase (Google / scrypt) **não** migram para bcrypt. Utilizadores importados precisam de **reset de senha** ou registo de novo.

## Export

1. Exporta coleções relevantes para JSON (Firebase console / `gcloud firestore export` + conversão).
2. Coloca ficheiros numa pasta, ex. `export/firestore/`:
   - `users.json` — lista de docs user
   - `rapid_settings.json` — lista `{ "userEmail" ou "legacyUid", ...campos }`

## Script

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
# dry-run (não escreve na BD)
python scripts/migrate_firestore_to_sql.py --input ..\export\firestore --dry-run

# aplicar
python scripts/migrate_firestore_to_sql.py --input ..\export\firestore --apply
```

O script:

- cria `users` com password temporária aleatória (imprime no log)
- cria `rapid_settings` default + overlay dos campos exportados
- **não** importa matches por defeito (usa `--with-matches` se o JSON existir)

Revisa sempre em staging antes de produção.
