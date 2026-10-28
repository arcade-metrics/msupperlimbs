# AppFlow (regras preservadas — stack atualizada)

Adaptado de `old/.../doc/AppFlow.md`. Firebase → API + SQL. ML Kit → MediaPipe.

## Autenticação

1. Registo: email, senha, nome, consentimento obrigatório
2. Login: email/senha → JWT
3. Pós-auth: garantir settings default + sessão diária `YYYYMMDD` → `/home`

## FNose — navegação

```
/home → /fnose-intro → /fnose-mode → /fnose-settings →
/fnose-adv-settings → /fnose-instructions → /fnose-game →
/fnose-feedback → /fnose-gameover
```

### Estados
`notStarted` → `touchNose` ↔ `touchTarget` (+ `targetTouched` feedback)

### Pré-jogo
1. Estabilidade do device (~2.5s, acelerómetro)
2. Posicionamento (nariz + ombros)
3. Calibração do alvo (~0.8s)
4. Countdown 3-2-1-GO

### Telemetria pré-jogo
Do `calibration_start` até `game_start`, um único relógio (epoch ms `t`) sincroniza:
- landmarks (pose)
- sensores (accel ± gyro + ângulo)
- eventos de trigger (`stability_ok/lost`, `pose_valid/invalid`, `target_calibrated`, `countdown_start`, `game_start`)

Persistência: `POST /fnose/pregame` → `fnose_pregame_runs` + chunks pose/sensor/event; o match liga via `pregame_run_id`.

### Persistência (jogo)
Match + chunks pose/touch via API (JSONB).

## Rapid — navegação

```
/home → /rapid-intro → /rapid-settings → /rapid-mode →
/rapid-game → /rapid-feedback → /rapid-gameover
```

Hands via MediaPipe; taps + pulse visualization; chunks pose/tap/pulse.

## Câmera

- Resolução por device (configs em SQL `camera_image_configs`)
- Android NV21 / iOS BGRA8888
- Landscape no jogo; portrait em menus

## Orientação de ecrã
Igual ao legado.
