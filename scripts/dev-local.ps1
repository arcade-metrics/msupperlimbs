<#
.SYNOPSIS
  Sobe a API local e corre flutter run para testar o app.

.EXAMPLE
  .\scripts\dev-local.ps1

.EXAMPLE
  .\scripts\dev-local.ps1 -Device 192.168.0.253:45645

.EXAMPLE
  .\scripts\dev-local.ps1 -Emulator
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [string]$Device,
  [switch]$Emulator,
  [switch]$ApiOnly,
  [switch]$FlutterOnly,
  [int]$Port = 8000
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend"
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

function Test-ApiHealth([int]$P) {
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$P/health" -UseBasicParsing -TimeoutSec 2
    return $r.StatusCode -eq 200
  } catch {
    return $false
  }
}

function Ensure-Backend {
  $py = Join-Path $backend ".venv\Scripts\python.exe"
  if (-not (Test-Path $py)) {
    Write-Host "A criar venv backend..." -ForegroundColor Yellow
    Push-Location $backend
    try {
      py -3.12 -m venv .venv
      & $py -m pip install -r requirements.txt
    } finally {
      Pop-Location
    }
  }

  $envFile = Join-Path $backend ".env"
  if (-not (Test-Path $envFile)) {
    $example = Join-Path $backend ".env.example"
    if (Test-Path $example) {
      Copy-Item $example $envFile
      Write-Host "Criado backend\.env a partir de .env.example" -ForegroundColor Yellow
    }
  }

  return $py
}

function Start-ApiIfNeeded([string]$Py, [int]$P) {
  if (Test-ApiHealth -P $P) {
    Write-Host "API já a correr em :$P" -ForegroundColor DarkGray
    return
  }

  Write-Host "A subir API (uvicorn :$P)..." -ForegroundColor Cyan
  $uvicorn = Join-Path $backend ".venv\Scripts\uvicorn.exe"
  if (-not (Test-Path $uvicorn)) {
    throw "uvicorn não encontrado em $uvicorn — corre pip install -r requirements.txt no backend."
  }

  $arg = "Set-Location '$backend'; & '$uvicorn' app.main:app --host 0.0.0.0 --port $P --reload"
  Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit", "-NoProfile", "-Command", $arg
  ) | Out-Null

  $deadline = (Get-Date).AddSeconds(30)
  while ((Get-Date) -lt $deadline) {
    if (Test-ApiHealth -P $P) {
      Write-Host "API OK — http://127.0.0.1:$P/health" -ForegroundColor Green
      return
    }
    Start-Sleep -Milliseconds 500
  }
  throw "API não respondeu em http://127.0.0.1:$P/health (ver janela do uvicorn)."
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

if (-not $FlutterOnly) {
  $py = Ensure-Backend
  Start-ApiIfNeeded -Py $py -P $Port
}

if ($ApiOnly) {
  Write-Host "Só API. Ctrl+C na janela do uvicorn para parar." -ForegroundColor DarkGray
  exit 0
}

if ($Emulator) {
  $apiBase = "http://10.0.2.2:$Port"
} else {
  $lanIp = Get-LanIp
  $apiBase = "http://${lanIp}:$Port"
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
