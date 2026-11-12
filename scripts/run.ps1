<#
.SYNOPSIS
  Corre o app (flutter run) contra a API de produção (https://api.ciatec.org).

.DESCRIPTION
  Usa o device do adb-wireless se estiver ligado; senão o flutter escolhe.
  Avisa se a API não responder ao /health.

.EXAMPLE
  .\scripts\run.ps1

.EXAMPLE
  .\scripts\run.ps1 -Device 192.168.0.253:45645
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [string]$Device
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "mobile"
$adbConfig = Join-Path $PSScriptRoot "adb-wireless.config.json"
$apiBase = "https://api.ciatec.org"

# Evita erro "different roots" (C: vs D:) no build Android
if ($root -match '^[Dd]:') {
  $env:PUB_CACHE = "D:\ciatec\pub-cache"
}

function Test-ApiHealth {
  try {
    $r = Invoke-WebRequest -Uri "$apiBase/health" -UseBasicParsing -TimeoutSec 5
    return $r.StatusCode -eq 200
  } catch {
    return $false
  }
}

function Resolve-FlutterDevice {
  if ($Device) { return $Device }
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

Write-Host "== MS Upper Limbs — run ==" -ForegroundColor Cyan

if (-not (Test-ApiHealth)) {
  Write-Host "Aviso: $apiBase/health não respondeu." -ForegroundColor Yellow
}

$flutterDevice = Resolve-FlutterDevice
Write-Host "API=$apiBase" -ForegroundColor DarkGray
if ($flutterDevice) {
  Write-Host "device=$flutterDevice" -ForegroundColor DarkGray
}

Push-Location $mobile
try {
  $flutterArgs = @("run")
  if ($flutterDevice) {
    $flutterArgs += @("-d", $flutterDevice)
  }
  Write-Host "flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
  & flutter @flutterArgs
  if ($LASTEXITCODE -ne 0) { throw "flutter run falhou (exit $LASTEXITCODE)" }
} finally {
  Pop-Location
}
