# ADB Wireless

Quando o utilizador pedir para **parear adb**, **ligar ADB wireless**, **conectar o telemóvel**, **scrcpy**, "espelhar ecrã" ou similar, usar `scripts/adb-wireless.ps1`.

O utilizador só precisa fornecer o **IP:porta** e o **código** do ecrã "Parear com código".

```powershell
cd D:\ciatec\projects\msupperlimbs\msupperlimbs
.\scripts\adb-wireless.ps1 -Pair IP:PORTA -Code CODIGO -Scrcpy
```

Já pareado, só espelhar: `.\scripts\adb-wireless.ps1 -Scrcpy`

## Notas

- O código de pareamento expira depressa; se falhar, pedir um novo.
- Não inventar portas; usar as do telemóvel. Só pedir outro IP:porta se o connect falhar.
- Config local (último IP): `scripts/adb-wireless.config.json` (gitignored, não ler).
- `adb` em `%LOCALAPPDATA%\Android\Sdk\platform-tools\`
- Se faltar scrcpy: `winget install --id Genymobile.scrcpy -e`
