# MS Upper Limbs

App de avaliação de membros superiores (Rapid e FNose): Flutter + MediaPipe,
com a API do [ciatec-core](https://github.com/ciatec-org/ciatec-core).

Legado em `old/` (somente referência, fora do git). Documentação em `docs/`.
O backend FastAPI próprio da v2 foi removido na v3 (fica na tag `v2.0.0`).

## Estrutura

```
mobile/    # Flutter
docs/      # Arquitetura, fluxos, deploy, inventário do legado
scripts/   # dev local, verificação, ADB wireless
```

## API

Por omissão o app usa `https://api.ciatec.org/api/v1`. O contrato
(login, settings, calibração, partidas, telemetria) está em
`docs/games/msupperlimbs/MSUPPERLIMBS-API.md` no ciatec-core.
Deploy e release: [docs/DEPLOY.md](docs/DEPLOY.md).

Verificação: `.\scripts\check.ps1` (`flutter analyze` + `flutter test test/features/`)

## Dev local (Flutter contra o ciatec-core)

Com o ciatec-core a correr localmente (`src/api`, porta 8000):

```powershell
.\scripts\dev-local.ps1
```

Usa o IP da máquina na LAN (`API_BASE_URL`) e, se existir, o device do `adb-wireless`.  
Emulador: `.\scripts\dev-local.ps1 -Emulator`  
Outra API: `.\scripts\dev-local.ps1 -ApiBaseUrl https://api.ciatec.org`

## Idiomas (i18n)

pt / en via `flutter gen-l10n` (`mobile/lib/l10n/`).  
Seletor no AppBar (login e home). Preferência guardada em `SharedPreferences`.

## ADB Wireless + scrcpy

No telemóvel: **Parear com código** → copia `IP:porta` e o código.

```powershell
cd D:\ciatec\projects\msupperlimbs\msupperlimbs
.\scripts\adb-wireless.ps1 -Pair 192.168.0.253:42711 -Code 233322 -Scrcpy
```

O script pareia, liga, limpa duplicados mDNS e abre o espelho.  
Religar + espelhar: `.\scripts\adb-wireless.ps1 -Scrcpy`  
Só religar: `.\scripts\adb-wireless.ps1`

Se faltar o scrcpy: `winget install --id Genymobile.scrcpy -e`  
No chat: **parear adb**

## MediaPipe (Android)

Modelos em `mobile/android/app/src/main/assets/`:
- `hand_landmarker.task`
- `pose_landmarker_lite.task`

No app: Home → **MediaPipe Debug** (device/emulador Android com câmera).

Se o build Android falhar com “different roots” (C: vs D:), use pub-cache no mesmo disco do projeto:

```powershell
$env:PUB_CACHE = "D:\ciatec\pub-cache"
flutter pub get
flutter run
```
