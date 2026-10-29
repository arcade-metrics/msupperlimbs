# Deploy — MS Upper Limbs (app)

A API é o [ciatec-core](https://github.com/ciatec-org/ciatec-core); este
repositório só tem o app. O deploy da API é feito no ciatec-core.

## Pré-requisitos

- Flutter stable (`mobile/.fvmrc`)
- Android SDK (o app é Android-first)
- Para testar localmente: o ciatec-core a correr (`src/api`, porta 8000)

## API usada pelo app

| Ambiente | Como |
|----------|------|
| Produção | por omissão: `https://api.ciatec.org` (`ApiConfig.baseUrl`) |
| Local | `.\scripts\dev-local.ps1` → `http://<IP-do-PC>:8000` (ou `10.0.2.2` no emulador) |
| Outra | `--dart-define=API_BASE_URL=https://…` |

Para testar o refresh de token, use `JWT_EXPIRES_IN=60` no `.env` da API do
ciatec-core local.

## Release

1. Subir `version` em `mobile/pubspec.yaml` e `AppInfo.version`
   (`mobile/lib/core/config/app_info.dart`) — os dois juntos.
2. Build:

   ```powershell
   cd mobile
   flutter pub get
   flutter build apk --release
   ```

   Sem `--dart-define`, o build aponta para produção.
3. Tag `vX.Y.Z` e GitHub Release no merge para `main`.

MediaPipe: modelos `.task` em `android/app/src/main/assets/`.

## Verificação rápida

```powershell
.\scripts\check.ps1
```

`flutter analyze` + `flutter test test/features/` (o mesmo que o CI testa).
