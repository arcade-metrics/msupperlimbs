<#
.SYNOPSIS
  Consultas e relatórios SOMENTE LEITURA do MS Upper Limbs (fora do app).

.DESCRIPTION
  Corre tools\reports\report.py com o venv de tools\.venv (criado na primeira vez).
  A ligação vem de $env:DATABASE_URL; a URL nunca é impressa. Tudo é só leitura:
  SQL validado, sessão/transação READ ONLY e ROLLBACK no fim.
  Os resultados vão para output\ (ignorada pelo git: contém dados de participantes).

  Para definir a variável só nesta sessão:
    $env:DATABASE_URL = "postgresql://utilizador_readonly:...@host:5432/db?sslmode=require"
  ou carregue-a de um ficheiro .env (lê apenas a chave DATABASE_URL):
    .\scripts\report.ps1 list -EnvFile caminho\do\.env

.EXAMPLE
  .\scripts\report.ps1 list

.EXAMPLE
  .\scripts\report.ps1 fnose-matches -Format xlsx

.EXAMPLE
  .\scripts\report.ps1 fnose-match -MatchId b186394f-d16e-469e-9cee-d25dd6c9597e -Format xlsx

.EXAMPLE
  .\scripts\report.ps1 fnose-match-2-eventos -MatchId b186394f-d16e-469e-9cee-d25dd6c9597e -Format csv
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  # 'list' ou o nome de um relatório / consulta (ex.: fnose-matches, fnose-match).
  [Parameter(Mandatory, Position = 0)]
  [string]$Name,

  # UUID da partida (relatórios fnose-match*).
  [string]$MatchId,

  [ValidateSet("xlsx", "csv", "json")]
  [string]$Format = "xlsx",

  # Pasta de saída (padrão: output\matches\<match_id>\ nas consultas de partida, senão output\).
  [string]$Out,

  # Máximo de frames de pose na exportação (padrão: todos).
  [int]$FrameLimit,

  # Ficheiro .env de onde carregar DATABASE_URL quando a variável não existe.
  [string]$EnvFile
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root "tools"
$venv = Join-Path $tools ".venv"
$python = Join-Path $venv "Scripts\python.exe"
$script = Join-Path $tools "reports\report.py"
$reqs = Join-Path $tools "reports\requirements.txt"

if (-not (Test-Path $python)) {
  Write-Host "Criando tools\.venv (primeira vez)..." -ForegroundColor Cyan
  & python -m venv $venv
  if ($LASTEXITCODE -ne 0) { throw "Não foi possível criar o venv (python no PATH?)." }
  & $python -m pip install --quiet -r $reqs
  if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar as dependências de $reqs." }
}

# Credencial guardada por report-login.ps1 (cifrada com DPAPI; só vive neste processo).
$saved = Join-Path $env:USERPROFILE ".ciatec\msupperlimbs-report.cred"
if (-not $env:DATABASE_URL -and -not $EnvFile -and (Test-Path $saved)) {
  $bstr = [IntPtr]::Zero
  try {
    $secure = ConvertTo-SecureString (Get-Content $saved -Raw).Trim()
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $env:DATABASE_URL = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  catch {
    Write-Host "Credencial guardada ilegível (outro utilizador/máquina?). Refaça: .\scripts\report-login.ps1" -ForegroundColor Yellow
  }
  finally {
    if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
  }
}

if (-not $env:DATABASE_URL -and $EnvFile) {
  $path = if ([System.IO.Path]::IsPathRooted($EnvFile)) { $EnvFile } else { Join-Path $root $EnvFile }
  if (-not (Test-Path $path)) { throw "Ficheiro não encontrado: $path" }
  $line = Get-Content $path | Where-Object { $_ -match '^\s*DATABASE_URL\s*=' } | Select-Object -First 1
  if ($line) {
    $value = ($line -replace '^\s*DATABASE_URL\s*=', '').Trim()
    $env:DATABASE_URL = $value.Trim('"').Trim("'")
  }
}

if ($Name -eq "list") {
  & $python -I $script list
  exit $LASTEXITCODE
}

if (-not $env:DATABASE_URL) {
  Write-Host "DATABASE_URL não definida." -ForegroundColor Yellow
  Write-Host 'Configure uma vez com .\scripts\report-login.ps1 (recomendado), ou defina $env:DATABASE_URL, ou use -EnvFile <caminho>'
  exit 2
}

$argsList = @("run", $Name, "--format", $Format)
if ($MatchId) { $argsList += @("--match-id", $MatchId) }
if ($Out) { $argsList += @("--out", $Out) }
if ($PSBoundParameters.ContainsKey("FrameLimit")) { $argsList += @("--frame-limit", $FrameLimit) }

Write-Host "== MS Upper Limbs — report (somente leitura) ==" -ForegroundColor Cyan
& $python -I $script @argsList
exit $LASTEXITCODE
