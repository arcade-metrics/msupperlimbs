<#
.SYNOPSIS
  Guarda, de forma criptografada, a ligação ao banco usada por report.ps1.

.DESCRIPTION
  Pergunta host, banco, utilizador e palavra-passe (esta oculta) e grava a DATABASE_URL
  em %USERPROFILE%\.ciatec\msupperlimbs-report.cred, fora do repositório.
  O ficheiro é cifrado com DPAPI do Windows: só o MESMO utilizador, NESTA máquina, o
  consegue decifrar. Nada é impresso e nada vai para o git.

  Use um utilizador do Postgres SOMENTE LEITURA (ex.: report_ro), não o 'postgres'.

  report.ps1 carrega-o sozinho quando $env:DATABASE_URL não está definida.

.EXAMPLE
  .\scripts\report-login.ps1          # configura / substitui
  .\scripts\report-login.ps1 -Clear   # apaga a credencial guardada
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [switch]$Clear
)

$ErrorActionPreference = "Stop"
$dir = Join-Path $env:USERPROFILE ".ciatec"
$file = Join-Path $dir "msupperlimbs-report.cred"

if ($Clear) {
  if (Test-Path $file) { Remove-Item $file -Force; Write-Host "Credencial apagada." -ForegroundColor Green }
  else { Write-Host "Nenhuma credencial guardada." }
  exit 0
}

$dbHost = Read-Host "Host"
$port = Read-Host "Porta [5432]"
if (-not $port) { $port = "5432" }
$db = Read-Host "Banco"
$user = Read-Host "Utilizador (somente leitura, ex.: report_ro)"
$secure = Read-Host "Palavra-passe" -AsSecureString

if (-not $dbHost -or -not $db -or -not $user -or $secure.Length -eq 0) {
  throw "Host, banco, utilizador e palavra-passe são obrigatórios."
}
if ($user -eq "postgres") {
  Write-Host "Aviso: 'postgres' é o administrador. Prefira um utilizador só com SELECT." -ForegroundColor Yellow
}

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  $url = "postgresql://{0}:{1}@{2}:{3}/{4}?sslmode=require" -f `
    [uri]::EscapeDataString($user), [uri]::EscapeDataString($plain), $dbHost, $port, $db
  $encrypted = ConvertTo-SecureString $url -AsPlainText -Force | ConvertFrom-SecureString
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  $plain = $null; $url = $null
}

New-Item -ItemType Directory -Force $dir | Out-Null
Set-Content -Path $file -Value $encrypted -Encoding ascii
# Só o utilizador atual acede ao ficheiro.
icacls $file /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null

Write-Host "Guardado (cifrado, só este utilizador/máquina): $file" -ForegroundColor Green
Write-Host "Teste: .\scripts\report.ps1 fnose-matches -Format csv"
