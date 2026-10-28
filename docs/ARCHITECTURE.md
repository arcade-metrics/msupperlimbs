# Arquitetura (app novo)

## Stack

| Camada | Tecnologia |
|--------|------------|
| Mobile | Flutter (stable) + Riverpod + go_router |
| API | FastAPI + SQLAlchemy 2 + Alembic |
| DB | PostgreSQL 16 |
| ML | MediaPipe nativo (pose + hands), Android-first |
| Auth | Email/senha + JWT |

## Monorepo

```
mobile/     # Flutter
backend/    # FastAPI
docs/       # Inventário, schema, fluxos
old/        # Legado (somente leitura)
```

## Princípios

1. Regras de negócio do legado; código reescrito.
2. Firebase não entra no app novo.
3. Um contrato Dart para landmarks; engine nativa atrás do MethodChannel.
4. Entregar por fases: auth → câmera/ML → FNose → Rapid → hardening.

## Fluxo de dados (alvo)

```
Login → API JWT → bootstrap user/settings/session
Jogo  → Camera → MediaPipe nativo → regras Dart → API (match + chunks)
```
