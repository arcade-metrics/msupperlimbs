# Inventário do legado (old/msupperlimbs-main)

Referência: `old/msupperlimbs-main/msupperlimbs-main/`  
Versão legada: `1.1.0+3` · Dart `^3.6.1` · Flutter sem FVM/lock

## Propósito

App de avaliação de membros superiores com dois desafios:

| Módulo | O que faz | Stack ML efetiva |
|--------|-----------|------------------|
| **FNose** (Finger-to-Nose) | Toque nariz → alvo com pose | ML Kit Pose (Android) |
| **Rapid** | Taps de dedos + visualização pulse | MediaPipe Hands nativo |

## Features e ecrãs

### Auth / User
- `/login`, `/signup`, `/consent`, `/consent-full`
- Pós-login: user + settings default + sessão diária → `/home`

### Home
- `/home` — cards FNose e Rapid (fora de `features/` no legado)

### FNose
```
/fnose-intro → /fnose-mode → /fnose-settings → /fnose-adv-settings
→ /fnose-instructions → /fnose-game → /fnose-feedback → /fnose-gameover
```

Estados: `notStarted`, `touchNose`, `touchTarget`, `targetTouched`

### Rapid
```
/rapid-intro → /rapid-settings → /rapid-mode → /rapid-game
→ /rapid-feedback → /rapid-gameover
```

## Schema Firestore (a espelhar em SQL)

### users/{uid}
`uid`, `name`, `email`, `createdAt`, `lastAccess`, consentimento

### settings (subdocs)
- `fnoseSettings`: gameMode, showInfoVideo, totalTime, targetSize
- `fnoseAdvSettings`: ~43 campos (ângulos, distâncias, alinhamento, estabilidade, suavização)
- `rapidSettings`: gameMode, visualizationType, tap*, pulse*, decay*, legacy pulse*

### sessions/{YYYYMMDD}
`sessionId`, `date`, `createdAt`, `deviceModel` + `logs/`

### fnose_matches / rapid_matches
Métricas da partida + chunks:
- FNose: `pose_data/`, `touch_data/`
- Rapid: `pose_data/`, `tap_data/`, `pulse_state_data/`

### Globais
- `games/fnose/global_stats`, `recent_matches`
- `camera_image_configs` (GLOBAL_ANDROID/IOS + por device)

## Dívida / não portar

| Item | Notas |
|------|-------|
| Firebase Auth/Firestore | Substituído por API + Postgres |
| ML Kit + MediaPipe pose morto | Unificar MediaPipe nativo |
| `sessionExists` path errado | `sessions/{uid}/sessions` vs `users/{uid}/sessions` |
| Providers auth duplicados | Em 3 ficheiros |
| Channel `com.example/native` | Renomear package real |
| `*_old.dart`, teste Counter | Lixo |
| Sem `pubspec.lock` | Builds não reproduzíveis |
| Google Sign-In | Fora de escopo (login email/senha) |

## Regras de negócio a preservar

Ver `doc/AppFlow.md` no legado e `docs/AppFlow.md` (cópia atualizada).

- Sessão diária `YYYYMMDD`
- Pré-jogo: estabilidade → posicionamento → calibração → countdown
- Ciclo FNose touchNose ↔ touchTarget com thresholds
- Chunks ~1MB de telemetria
- Consentimento no registo
- Configs de câmera por device

## Dependências legadas (referência)

Riverpod 2, go_router 14, camera, sensors_plus, fl_chart, flex_color_scheme, Firebase*, ML Kit*
