<#
.SYNOPSIS
  Corre o app (flutter run) contra o ciatec-core.

.DESCRIPTION
  Por omissão aponta para um ciatec-core local na porta 8000, pelo IP da
  máquina na LAN (device físico) ou 10.0.2.2 (emulador). O ciatec-core local
  sobe-se no repositório dele; este script só avisa se não estiver a responder.

.EXAMPLE
  .\scripts\dev-local.ps1

.EXAMPLE
  .\scripts\dev-local.ps1 -Device 192.168.0.253:45645

.EXAMPLE
  .\scripts\dev-local.ps1 -Emulator

.EXAMPLE
  .\scripts\dev-local.ps1 -ApiBaseUrl https://api.ciatec.org
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [string]$Device,
  [switch]$Emulator,
  # URL completa da API; sem ela, ciatec-core local na porta -Port.
  [string]$ApiBaseUrl,
  [int]$Port = 8000,
  # Mantido para os comandos antigos: o script já só corre o Flutter.
  [switch]$FlutterOnly
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "mobile"
$adbConfig = Join-Path $PSScriptRoot "adb-wireless.config.json"

# Evita erro "different roots" (C: vs D:) no build Android
if ($root -match '^[Dd]:') {
  $env:PUB_CACHE = "D:\ciatec\pub-cache"
}

function Get-LanIp {
  if (Test-Path $adbConfig) {
    $phoneIp = (Get-Content $adbConfig -Raw | ConvertFrom-Json).ip
    if ($phoneIp -match '^(\d+\.\d+\.\d+)\.') {
      $prefix = $Matches[1]
      $same = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -like "$prefix.*" -and $_.IPAddress -notlike '127.*' } |
        Select-Object -First 1 -ExpandProperty IPAddress
      if ($same) { return $same }
    }
  }

  $addr = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
      $_.IPAddress -notlike '127.*' -and
      $_.IPAddress -notlike '169.254.*' -and
      $_.PrefixOrigin -ne 'WellKnown'
    } |
    Sort-Object { if ($_.IPAddress -like '192.168.*') { 0 } else { 1 } } |
    Select-Object -First 1 -ExpandProperty IPAddress

  if (-not $addr) { throw "Não foi possível obter o IP local da máquina." }
  return $addr
}

function Test-ApiHealth([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri "$Url/health" -UseBasicParsing -TimeoutSec 2
    return $r.StatusCode -eq 200
  } catch {
    return $false
  }
}

function Resolve-FlutterDevice {
  if ($Device) { return $Device }
  if ($Emulator) { return $null }

  if (Test-Path $adbConfig) {
    $ep = (Get-Content $adbConfig -Raw | ConvertFrom-Json).connectEndpoint
    if ($ep) {
      $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
      if (Test-Path $adb) {
        $devs = & $adb devices 2>&1 | Out-String
        if ($devs -match [regex]::Escape($ep)) { return $ep }
      }
    }
  }
  return $null
}

Write-Host "== MS Upper Limbs — dev local ==" -ForegroundColor Cyan

if ($ApiBaseUrl) {
  $apiBase = $ApiBaseUrl.TrimEnd('/')
  $healthUrl = $apiBase
} else {
  $healthUrl = "http://127.0.0.1:$Port"
  if ($Emulator) {
    $apiBase = "http://10.0.2.2:$Port"
  } else {
    $apiBase = "http://$(Get-LanIp):$Port"
  }
}

if (-not (Test-ApiHealth -Url $healthUrl)) {
  Write-Host "Aviso: $healthUrl/health não respondeu. Sobe o ciatec-core (src/api, porta $Port) antes de jogar." -ForegroundColor Yellow
}

$flutterDevice = Resolve-FlutterDevice
Write-Host "API_BASE_URL=$apiBase" -ForegroundColor DarkGray
if ($flutterDevice) {
  Write-Host "device=$flutterDevice" -ForegroundColor DarkGray
}

Push-Location $mobile
try {
  $flutterArgs = @("run", "--dart-define=API_BASE_URL=$apiBase")
  if ($flutterDevice) {
    $flutterArgs += @("-d", $flutterDevice)
  }
  Write-Host "flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
  & flutter @flutterArgs
  if ($LASTEXITCODE -ne 0) { throw "flutter run falhou (exit $LASTEXITCODE)" }
} finally {
  Pop-Location
}
