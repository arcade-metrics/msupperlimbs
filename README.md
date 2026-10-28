# MS Upper Limbs

Reescrita do app de avaliação de membros superiores: Flutter + API FastAPI + PostgreSQL + MediaPipe.

Legado em `old/` (somente referência). Documentação em `docs/`.

## Estrutura

```
mobile/    # Flutter
backend/   # FastAPI
docs/      # Inventário, schema, fluxos
old/       # App antigo (Firebase)
```

## Fases

| Fase | Status | Conteúdo |
|------|--------|----------|
| 0 | feita | Inventário em `docs/` |
| 1 | feita | Bootstrap mobile + backend |
| 2 | feita | Auth JWT email/senha + home |
| 3 | feita | Câmera + MediaPipe (Android debug) |
| 4 | pendente | FNose |
| 5 | feita | Rapid (settings → jogo → SQL matches) |
| 6 | feita | Hardening (testes, deploy, migração opcional) |

## Backend (Postgres local)

Requer **Python 3.12** e Postgres com a base `teamap_db`.

```powershell
cd backend
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env   # já aponta para postgres:1234@localhost/teamap_db
alembic upgrade head     # cria/atualiza tabelas (users, rapid_settings, …)
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Health: http://localhost:8000/health  
Docs: http://localhost:8000/docs  
Deploy: [docs/DEPLOY.md](docs/DEPLOY.md)

Verificação: `.\scripts\check.ps1` (pytest + flutter test Rapid)

## Dev local (API + Flutter)

Sobe a API (se ainda não estiver) e corre o app no device:

```powershell
.\scripts\dev-local.ps1
```

Usa o IP da máquina na LAN (`API_BASE_URL`) e, se existir, o device do `adb-wireless`.  
Emulador: `.\scripts\dev-local.ps1 -Emulator`  
Só API / só Flutter: `-ApiOnly` / `-FlutterOnly`

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
