# Deploy — MS Upper Limbs (app)

A API é o [ciatec-core](https://github.com/ciatec-org/ciatec-core); este
repositório só tem o app. O deploy da API é feito no ciatec-core.

## Pré-requisitos

- Flutter stable (`mobile/.fvmrc`)
- Android SDK (o app é Android-first)

## API usada pelo app

Só produção: `https://api.ciatec.org` (`ApiConfig.baseUrl`). Não há API
local nem `--dart-define` para trocar a URL; o app só aceita HTTPS.

Para correr no device: `.\scripts\run.ps1`.

## Release

1. Subir `version` em `mobile/pubspec.yaml` e `AppInfo.version`
   (`mobile/lib/core/config/app_info.dart`) — os dois juntos.
2. Build:

   ```powershell
   cd mobile
   flutter pub get
   flutter build apk --release
   ```

3. Tag `vX.Y.Z` e GitHub Release no merge para `main`.

MediaPipe: modelos `.task` em `android/app/src/main/assets/`.

## Verificação rápida

```powershell
.\scripts\check.ps1
```

`flutter analyze` + `flutter test test/features/` (o mesmo que o CI testa).
