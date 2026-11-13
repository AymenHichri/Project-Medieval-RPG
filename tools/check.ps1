# Full project check (Windows PowerShell): source-asset checksums, import + parse check, tests.
#   $env:GODOT = "C:\path\to\Godot_console.exe"; .\tools\check.ps1 [--filter=<test substring>]
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $TestArgs)
$ErrorActionPreference = "Continue"
Set-Location (Join-Path $PSScriptRoot "..")
$Project = (Get-Location).Path
$Godot = if ($env:GODOT) { $env:GODOT } else { "C:\Users\AymenH\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
$Python = if ($env:PYTHON) { $env:PYTHON } else { "python" }
$status = 0

Write-Host "== 1/4 source assets unchanged"
& $Python -I tools/verify_source_assets.py
if ($LASTEXITCODE -ne 0) { $status = 1 }

Write-Host "== 2/4 dfgui 2x copies"
if (-not (Test-Path "assets/vendor/dfgui/2x")) {
    & $Godot --headless --path $Project -s res://tools/upscale_ui.gd
    if ($LASTEXITCODE -ne 0) { $status = 1 }
}

Write-Host "== 3/4 import + parse check"
$importLog = & $Godot --headless --path $Project --import 2>&1 | Out-String
$parseErrors = $importLog -split "`n" | Select-String -Pattern "SCRIPT ERROR|Parse Error|Failed to load script"
if ($parseErrors) { $parseErrors | ForEach-Object { Write-Host $_ }; Write-Host "parse errors found during import"; $status = 1 }

Write-Host "== 4/4 tests"
& $Godot --headless --path $Project -s res://tests/test_runner.gd -- @TestArgs
if ($LASTEXITCODE -ne 0) { $status = 1 }

if ($status -eq 0) { Write-Host "CHECK PASSED" } else { Write-Host "CHECK FAILED" }
exit $status
