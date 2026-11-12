<#
.SYNOPSIS
  Testa a ligação ao Postgres indicado em $env:DATABASE_URL.

.DESCRIPTION
  Usa o python do old\backend\.venv (psycopg2). Nunca imprime a URL, o utilizador
  nem a password; só o host mascarado, a versão do servidor e as tabelas.

  A variável vem do ambiente. Para a definir só nesta sessão:
    $env:DATABASE_URL = "postgresql://..."
  ou carregue-a de um ficheiro .env (lê apenas a chave DATABASE_URL):
    .\scripts\db-check.ps1 -EnvFile old\backend\.env

.EXAMPLE
  $env:DATABASE_URL = "postgresql://user:pass@host:5432/db?sslmode=require"
  .\scripts\db-check.ps1

.EXAMPLE
  .\scripts\db-check.ps1 -EnvFile old\backend\.env
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  # Ficheiro .env de onde carregar DATABASE_URL quando a variável não existe.
  [string]$EnvFile
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$python = Join-Path $root "old\backend\.venv\Scripts\python.exe"
$script = Join-Path $PSScriptRoot "db-check.py"

if (-not $env:DATABASE_URL -and $EnvFile) {
  $path = if ([System.IO.Path]::IsPathRooted($EnvFile)) { $EnvFile } else { Join-Path $root $EnvFile }
  if (-not (Test-Path $path)) { throw "Ficheiro não encontrado: $path" }
  $line = Get-Content $path | Where-Object { $_ -match '^\s*DATABASE_URL\s*=' } | Select-Object -First 1
  if ($line) {
    $value = ($line -replace '^\s*DATABASE_URL\s*=', '').Trim()
    $env:DATABASE_URL = $value.Trim('"').Trim("'")
  }
}

if (-not $env:DATABASE_URL) {
  Write-Host "DATABASE_URL não definida." -ForegroundColor Yellow
  Write-Host 'Defina-a ($env:DATABASE_URL = "postgresql://...") ou use -EnvFile old\backend\.env'
  exit 2
}

if (-not (Test-Path $python)) {
  throw "python não encontrado em old\backend\.venv (precisa de psycopg2). Instale: python -m venv old\backend\.venv; old\backend\.venv\Scripts\pip install psycopg2-binary"
}

Write-Host "== MS Upper Limbs — db-check ==" -ForegroundColor Cyan
& $python -I $script
exit $LASTEXITCODE
