# Arquitetura (v3)

## Stack

| Camada | Tecnologia |
|--------|------------|
| Mobile | Flutter (stable) + Riverpod + go_router |
| API | [ciatec-core](https://github.com/ciatec-org/ciatec-core) (`https://api.ciatec.org/api/v1`) |
| ML | MediaPipe nativo (pose + hands), Android-first |
| Auth | Email/senha + JWT do ciatec-core (access curto + refresh rotativo) |

Até à v2 o repositório tinha um backend FastAPI próprio (`backend/`). Na v3
o app passou a falar só com o ciatec-core e esse backend foi removido; o
código fica na tag `v2.0.0`. O contrato que o app implementa está em
`docs/games/msupperlimbs/MSUPPERLIMBS-API.md` no ciatec-core.

## Repositório

```
mobile/     # Flutter
docs/       # Arquitetura, fluxos, inventário do legado
scripts/    # dev local, verificação, ADB wireless
old/        # Legado (somente leitura, fora do git)
```

## Princípios

1. Regras de negócio do legado; código reescrito.
2. Firebase não entra no app novo.
3. Um contrato Dart para landmarks; engine nativa atrás do MethodChannel.
4. Um relógio por execução: todo tempo é `offsetMs` desde `SessionClock.startedAt`.
5. Uploads idempotentes; o que falha por rede fica no device e é reenviado.

## Fluxo de dados

```
Login    → ciatec-core /auth (refresh no arranque e em 401)
Settings → /{slug}/players/{me}/settings
FNose    → setup (5 etapas) → /calibrations
Jogo     → Câmera → MediaPipe nativo → regras Dart →
           /sessions/matches → context → pose/events em chunks → metrics → finish
Offline  → job guardado no device → reenviado no próximo login/arranque
```

Código: `lib/features/match/` (fluxo de partida, uploads, fila),
`lib/features/calibration/` (módulo de calibração), `lib/features/{rapid,fnose}/`
(engines, telas e a ligação com o fluxo comum).
