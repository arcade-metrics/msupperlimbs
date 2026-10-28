<#
.SYNOPSIS
  Pareia / liga Android via ADB Wireless e opcionalmente abre o scrcpy.

.EXAMPLE
  .\scripts\adb-wireless.ps1 -Pair 192.168.0.253:42711 -Code 233322 -Scrcpy

.EXAMPLE
  .\scripts\adb-wireless.ps1 -Scrcpy   # religa o último e espelha
#>
[CmdletBinding()]
param(
  [Alias("PairHost")]
  [string]$Pair,

  [string]$Code,

  [Alias("ConnectHost")]
  [string]$Connect,

  [switch]$Scrcpy,
  [switch]$Status,
  [switch]$Disconnect
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir "adb-wireless.config.json"

function Get-AdbPath {
  $candidates = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
  )
  foreach ($p in $candidates) {
    if ($p -and (Test-Path $p)) { return $p }
  }
  $fromPath = Get-Command adb -ErrorAction SilentlyContinue
  if ($fromPath) { return $fromPath.Source }
  throw "adb.exe não encontrado."
}

function Get-ScrcpyPath {
  $fromPath = Get-Command scrcpy -ErrorAction SilentlyContinue
  if ($fromPath) { return $fromPath.Source }

  $wingetRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
  if (Test-Path $wingetRoot) {
    $found = Get-ChildItem -Path $wingetRoot -Filter "scrcpy.exe" -Recurse -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($found) { return $found.FullName }
  }

  throw @"
scrcpy não encontrado. Instala e abre um terminal novo:
  winget install --id Genymobile.scrcpy -e
"@
}

function Read-Config {
  if (Test-Path $ConfigPath) {
    return Get-Content $ConfigPath -Raw | ConvertFrom-Json
  }
  return $null
}

function Save-Config([string]$Ip, [string]$ConnectEndpoint) {
  $obj = [ordered]@{
    ip              = $Ip
    connectEndpoint = $ConnectEndpoint
    updatedAt       = (Get-Date).ToString("o")
  }
  ($obj | ConvertTo-Json) | Set-Content -Path $ConfigPath -Encoding UTF8
  Write-Host "Guardado: $ConnectEndpoint" -ForegroundColor DarkGray
}

function Find-ConnectEndpoint([string]$Adb, [string]$Ip) {
  Start-Sleep -Seconds 1
  $services = & $Adb mdns services 2>&1 | Out-String
  Write-Host $services -ForegroundColor DarkGray

  # Preferir linhas _adb-tls-connect_ com este IP
  $connectLines = $services -split "`r?`n" | Where-Object { $_ -match '_adb-tls-connect' -and $_ -match [regex]::Escape($Ip) }
  foreach ($line in $connectLines) {
    $m = [regex]::Match($line, [regex]::Escape($Ip) + ':\d+')
    if ($m.Success) { return $m.Value }
  }

  $matches = [regex]::Matches($services, [regex]::Escape($Ip) + ':\d+')
  foreach ($m in $matches) { return $m.Value }

  $any = [regex]::Match($services, '(\d+\.\d+\.\d+\.\d+:\d+)')
  if ($any.Success) { return $any.Groups[1].Value }

  return $null
}

function Clear-MdnsDuplicates([string]$Adb, [string]$KeepEndpoint) {
  $lines = & $Adb devices 2>&1 | Out-String
  foreach ($line in ($lines -split "`r?`n")) {
    if ($line -notmatch '^\s*(\S+)\s+device') { continue }
    $serial = $Matches[1]
    if ($serial -eq "List" -or $serial -eq $KeepEndpoint) { continue }
    if ($serial -match '_adb-tls-connect|_adb-tls-pairing|\._tcp') {
      Write-Host "A remover duplicado mDNS: $serial" -ForegroundColor DarkGray
      & $Adb disconnect $serial 2>&1 | Out-Null
    }
  }
}

function Start-ScrcpyMirror([string]$Adb, [string]$Endpoint) {
  Clear-MdnsDuplicates -Adb $Adb -KeepEndpoint $Endpoint
  $scrcpy = Get-ScrcpyPath
  Write-Host "A abrir scrcpy ($Endpoint) ..." -ForegroundColor Cyan
  Start-Process -FilePath $scrcpy -ArgumentList @("-s", $Endpoint)
}

$adb = Get-AdbPath
Write-Host "adb: $adb" -ForegroundColor DarkGray

if ($Status) { & $adb devices -l; exit 0 }
if ($Disconnect) { & $adb disconnect; exit 0 }

# Reinicia o daemon (kill pode falhar se ainda não existir — ignorar)
cmd /c "`"$adb`" kill-server" 2>$null | Out-Null
Start-Sleep -Milliseconds 500
$start = cmd /c "`"$adb`" start-server" 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host $start -ForegroundColor Yellow
}

$ErrorActionPreference = "Stop"
$endpoint = $null

if ($Pair -and $Code) {
  if ($Pair -notmatch '^\d+\.\d+\.\d+\.\d+:\d+$') {
    throw "Usa o IP:porta do telemóvel, ex: -Pair 192.168.0.253:42711 -Code 233322"
  }

  Write-Host "A parear $Pair ..." -ForegroundColor Cyan
  & $adb pair $Pair $Code 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "Pareamento falhou. Gera um código novo e mantém o ecrã aberto."
  }

  $ip = ($Pair -split ":")[0]
  $endpoint = $Connect
  if (-not $endpoint) {
    Write-Host "A descobrir porta de ligação (mDNS)..." -ForegroundColor Cyan
    $endpoint = Find-ConnectEndpoint -Adb $adb -Ip $ip
  }
  if (-not $endpoint) {
    Write-Host "mDNS não encontrou; a tentar o mesmo endereço do pareamento..." -ForegroundColor Yellow
    $endpoint = $Pair
  }

  Write-Host "A ligar $endpoint ..." -ForegroundColor Cyan
  & $adb connect $endpoint 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw @"
connect falhou.
Fecha o diálogo do código. Na página 'Depuração sem fios' deve aparecer outro IP:porta.
Corre: .\scripts\adb-wireless.ps1 -Connect ESSE_IP:PORTA -Scrcpy
"@
  }
  Save-Config -Ip $ip -ConnectEndpoint $endpoint
} elseif ($Connect) {
  $endpoint = $Connect
  Write-Host "A ligar $endpoint ..." -ForegroundColor Cyan
  & $adb connect $endpoint 2>&1 | Out-Host
  Save-Config -Ip (($endpoint -split ":")[0]) -ConnectEndpoint $endpoint
} else {
  $cfg = Read-Config
  if (-not $cfg -or -not $cfg.connectEndpoint) {
    throw "Primeira vez: .\scripts\adb-wireless.ps1 -Pair IP:PORTA -Code CODIGO -Scrcpy"
  }
  $endpoint = $cfg.connectEndpoint
  Write-Host "A religar $endpoint ..." -ForegroundColor Cyan
  & $adb connect $endpoint 2>&1 | Out-Host
}

Write-Host ""
& $adb devices -l

if ($Scrcpy) {
  if (-not $endpoint) {
    $cfg = Read-Config
    $endpoint = $cfg.connectEndpoint
  }
  Start-ScrcpyMirror -Adb $adb -Endpoint $endpoint
} else {
  Write-Host "Espelhar: .\scripts\adb-wireless.ps1 -Scrcpy" -ForegroundColor DarkGray
}
