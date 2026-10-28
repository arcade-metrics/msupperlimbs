#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Write-Host "== MS Upper Limbs check ==" -ForegroundColor Cyan

# Backend tests
$backend = Join-Path $root "backend"
Push-Location $backend
try {
    $py = Join-Path $backend ".venv\Scripts\python.exe"
    if (-not (Test-Path $py)) {
        Write-Host "Creating venv..." -ForegroundColor Yellow
        py -3.12 -m venv .venv
        $py = Join-Path $backend ".venv\Scripts\python.exe"
        & $py -m pip install -r requirements.txt
    }
    Write-Host "pytest..." -ForegroundColor Cyan
    & $py -m pytest -q
    if ($LASTEXITCODE -ne 0) { throw "pytest failed" }
}
finally {
    Pop-Location
}

# Flutter Rapid domain tests
$mobile = Join-Path $root "mobile"
Push-Location $mobile
try {
    Write-Host "flutter test (rapid)..." -ForegroundColor Cyan
    flutter test test/features/rapid/
    if ($LASTEXITCODE -ne 0) { throw "flutter test failed" }
}
finally {
    Pop-Location
}

Write-Host "OK — all checks passed" -ForegroundColor Green
