# MS Upper Limbs

App Flutter de avaliação de membros superiores (jogos Rapid e FNose) com MediaPipe nativo, falando com a API do ciatec-core. Detalhes: [README.md](README.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Segredos (regra rígida)

- **Nunca ler, editar nem imprimir** qualquer `.env*` (exceto `.env.example`), incluindo os de `old/`. Bloqueado também em `.claude/settings.json`.
- Se o utilizador colar credenciais no chat, não as repetir em ficheiros, commits ou pedidos externos; avisar para rodá-las.

## Estrutura

- `mobile/` — Flutter (Riverpod + go_router). Código em `mobile/lib/{core,features,l10n}`; features: auth, calibration, fnose, home, match, motion, rapid.
- `docs/` — arquitetura, fluxos (AppFlow), deploy, inventário do legado.
- `scripts/` — `check.ps1`, `run.ps1`, `adb-wireless.ps1`, `db-check.ps1`.
- `old/` — legado, **somente leitura**, fora do git. Preservar regras de negócio, não copiar código.

## Comandos

- Verificar (analyze + testes de features, igual ao CI): `.\scripts\check.ps1`
- Correr no device: `.\scripts\run.ps1` (`-Device <id>`). API só de produção: `https://api.ciatec.org`, sem API local.
- i18n: `flutter gen-l10n` (strings em `mobile/lib/l10n/*.arb`, pt e en)
- Se o build Android falhar com "different roots": `$env:PUB_CACHE = "D:\ciatec\pub-cache"`

## Convenções

- PowerShell no Windows; caminhos com `\` em scripts `.ps1`.
- Sem Firebase. Um contrato Dart para landmarks; engine nativa atrás do MethodChannel.
- Todo tempo é `offsetMs` desde `SessionClock.startedAt`.
- Uploads idempotentes; falhas de rede ficam no device e são reenviadas.
- Textos de UI sempre via l10n (pt + en), nunca strings fixas.
- Git: branch `develop`, PRs para `main`; commits no estilo `feat(scope): ...`, `chore: ...`.
- Contrato da API: `docs/games/msupperlimbs/MSUPPERLIMBS-API.md` no repositório ciatec-core.

## ADB wireless

Ver [.claude/rules/adb-wireless.md](.claude/rules/adb-wireless.md).
