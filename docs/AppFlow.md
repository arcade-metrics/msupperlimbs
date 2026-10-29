# AppFlow (regras preservadas — stack atualizada)

Adaptado de `old/.../doc/AppFlow.md`. Firebase → ciatec-core. ML Kit → MediaPipe.

## Autenticação

1. Registo: email, senha (8+ caracteres, 1 maiúscula, 1 número) e nome
2. Login: email/senha → access + refresh do ciatec-core
3. Arranque: refresh do token guardado → `/home`; settings nascem do preset
   no primeiro `GET`; pendentes de upload são reenviados

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
Do `calibration_start` até `game_start`, um único relógio (`offsetMs` desde o
início da execução) sincroniza:
- landmarks (pose)
- sensores (accel ± gyro + ângulo)
- eventos de trigger (`stability_ok/lost`, `phase`, `nose_aligned`, `target_calibrated`, `countdown_start`, `game_start`)

Persistência: execução `device-body-setup/v1` em `/calibrations` (5 etapas
tipadas + sensores, pose e eventos em chunks); a partida liga via
`calibration_run_id`.

### Persistência (jogo)
`/sessions/matches` → context → pose e eventos (`phase`, `spark`, `hit`) em
chunks → metrics → finish com `Idempotency-Key`.

## Rapid — navegação

```
/home → /rapid-intro → /rapid-settings → /rapid-mode →
/rapid-game → /rapid-feedback → /rapid-gameover
```

Hands via MediaPipe; taps + pulse visualization; chunks de pose e eventos
`phase`/`tap`/`pulse_tick`.

## Câmera

- Resolução baixa fixa (`ResolutionPreset.low`), imagem reduzida para inferência
- Android NV21 / iOS BGRA8888
- Landscape no jogo; portrait em menus

## Orientação de ecrã
Igual ao legado.
