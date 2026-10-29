#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Write-Host "== MS Upper Limbs check ==" -ForegroundColor Cyan

# Analyzer (warnings and errors; the existing infos do not fail it) and the
# feature unit tests that CI runs.
$mobile = Join-Path $root "mobile"
Push-Location $mobile
try {
    Write-Host "flutter analyze..." -ForegroundColor Cyan
    flutter analyze --no-fatal-infos
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed" }
    Write-Host "flutter test (features)..." -ForegroundColor Cyan
    flutter test test/features/
    if ($LASTEXITCODE -ne 0) { throw "flutter test failed" }
}
finally {
    Pop-Location
}

Write-Host "OK — all checks passed" -ForegroundColor Green
