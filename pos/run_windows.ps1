# Launch POS Tawsil Windows app from exe directory (fixes working-directory / Access denied)
# Usage: .\run_windows.ps1 [debug|release]
# - debug: run build\windows\x64\runner\Debug\pos_tawsil.exe (default)
# - release: run build\windows\x64\runner\Release\pos_tawsil.exe (build first if needed)

param(
    [Parameter(Position=0)]
    [ValidateSet('debug', 'release')]
    [string]$Mode = 'debug'
)

$ErrorActionPreference = "Stop"
$posRoot = $PSScriptRoot

if (-not (Test-Path "$posRoot\pubspec.yaml")) {
    Write-Host "Error: Run from pos_tawsil folder." -ForegroundColor Red
    exit 1
}

$exeDir = "$posRoot\build\windows\x64\runner\$Mode"
$exe = "$exeDir\pos_tawsil.exe"

if (-not (Test-Path $exe)) {
    Set-Location $posRoot
    if ($Mode -eq 'release') {
        Write-Host "Building Windows app (release)..." -ForegroundColor Cyan
        flutter build windows
    } else {
        Write-Host "Debug exe not found. Build with: flutter run -d windows" -ForegroundColor Yellow
        Write-Host "Then run this script again, or run the exe from:" -ForegroundColor Yellow
        Write-Host "  $exeDir" -ForegroundColor Gray
        exit 1
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed." -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $exe)) {
    Write-Host "Error: $exe not found." -ForegroundColor Red
    exit 1
}

Write-Host "Running from: $exeDir" -ForegroundColor Cyan
Set-Location $exeDir
& ".\pos_tawsil.exe"
