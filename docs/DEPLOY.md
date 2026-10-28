# Deploy — MS Upper Limbs API

## Pré-requisitos

- Python 3.12+
- PostgreSQL 16 (local ou Docker)
- Flutter stable (mobile)

## Desenvolvimento local (Postgres já existente)

Se usas a base `teamap_db` (como no `.env.example`):

```powershell
cd backend
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
# edita JWT_SECRET em produção
alembic upgrade head
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Health: http://localhost:8000/health (`status` + `db`)  
OpenAPI: http://localhost:8000/docs

## Docker Compose (API + Postgres)

Na raiz do repo:

```powershell
$env:JWT_SECRET = "<segredo-longo>"
docker compose up -d --build
```

- DB: `msupperlimbs` / user+pass `msupperlimbs` na porta `5432`
- API: http://localhost:8000  
- Entrypoint corre `alembic upgrade head` antes do uvicorn

Para apontar o Flutter para a API no PC (device físico):

```powershell
flutter run --dart-define=API_BASE_URL=http://<IP-do-PC>:8000
```

## Checklist produção

1. `JWT_SECRET` forte (não uses o default)
2. `CORS_ORIGINS` com os hosts reais (não `*` se possível)
3. HTTPS à frente da API (reverse proxy)
4. Postgres com backups / volume persistente
5. Sem `--reload` no uvicorn (já é o default do Dockerfile)
6. `alembic upgrade head` em cada deploy (automático no container)

## Mobile (release)

```powershell
cd mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://api.exemplo.com
```

MediaPipe: modelos `.task` em `android/app/src/main/assets/`.

## Verificação rápida

```powershell
.\scripts\check.ps1
```

Corre testes backend (pytest) + Flutter (`test/features/rapid`).

## Migração Firestore → SQL

Opcional, ver [MIGRATION_FIRESTORE.md](MIGRATION_FIRESTORE.md).
