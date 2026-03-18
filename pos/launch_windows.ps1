# Comprehensive Windows Launch Script for POS Tawsil
# Handles all error cases and provides detailed diagnostics
# Usage: .\launch_windows.ps1 [debug|release|build-only]

param(
    [Parameter(Position=0)]
    [ValidateSet('debug', 'release', 'build-only', 'clean-build')]
    [string]$Mode = 'debug'
)

$ErrorActionPreference = "Continue"
$posRoot = $PSScriptRoot

# Colors
function Write-Step { param([string]$msg) Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-Success { param([string]$msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Warning { param([string]$msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Error { param([string]$msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "  $msg" -ForegroundColor Gray }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  POS Tawsil - Windows Launcher" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Verify we're in the right directory
Write-Step "Step 1: Verifying project structure..."
if (-not (Test-Path "$posRoot\pubspec.yaml")) {
    Write-Error "pubspec.yaml not found. Run this script from pos_tawsil folder."
    exit 1
}
Write-Success "Project structure verified"

# Step 2: Check Flutter installation
Write-Step "Step 2: Checking Flutter installation..."
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter command failed"
    }
    Write-Success "Flutter found: $flutterVersion"
} catch {
    Write-Error "Flutter not found or not in PATH"
    Write-Info "Install Flutter from: https://flutter.dev/docs/get-started/install"
    Write-Info "Or add Flutter to your PATH environment variable"
    exit 1
}

# Step 3: Check Flutter doctor
Write-Step "Step 3: Running Flutter doctor..."
Set-Location $posRoot
flutter doctor --version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Flutter doctor reported issues. Continuing anyway..."
} else {
    Write-Success "Flutter environment OK"
}

# Step 4: Get dependencies
Write-Step "Step 4: Getting Flutter dependencies..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to get dependencies"
    Write-Info "Try running: flutter pub get"
    exit 1
}
Write-Success "Dependencies resolved"

# Step 5: Clean build if requested
if ($Mode -eq 'clean-build') {
    Write-Step "Step 5: Cleaning previous builds..."
    flutter clean
    flutter pub get
    Write-Success "Build cleaned"
}

# Step 6: Build or locate executable
$exeDir = "$posRoot\build\windows\x64\runner\$Mode"
$exe = "$exeDir\pos_tawsil.exe"

if (-not (Test-Path $exe)) {
    Write-Step "Step 6: Building Windows app ($Mode mode)..."
    
    if ($Mode -eq 'release') {
        Write-Info "Building release version..."
        flutter build windows --release
    } else {
        Write-Info "Building debug version..."
        flutter build windows --debug
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed!"
        Write-Info "Common issues:"
        Write-Info "  1. Missing Visual Studio Build Tools"
        Write-Info "  2. Missing Windows SDK"
        Write-Info "  3. Antivirus blocking build process"
        Write-Info "  4. Insufficient disk space"
        Write-Info ""
        Write-Info "Try: flutter doctor -v"
        exit 1
    }
    Write-Success "Build completed"
} else {
    Write-Step "Step 6: Executable found"
    Write-Success "Found: $exe"
}

# Step 7: Verify executable exists
if (-not (Test-Path $exe)) {
    Write-Error "Executable not found: $exe"
    Write-Info "Expected location: $exeDir"
    Write-Info "Try building manually: flutter build windows --$Mode"
    exit 1
}

# Step 8: Check for required DLLs and data folder
Write-Step "Step 7: Verifying runtime files..."
$requiredFiles = @(
    "$exeDir\flutter_windows.dll",
    "$exeDir\data"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Warning "Some runtime files are missing:"
    foreach ($file in $missingFiles) {
        Write-Info "  - $file"
    }
    Write-Info "Rebuilding..."
    flutter build windows --$Mode
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Rebuild failed"
        exit 1
    }
} else {
    Write-Success "All runtime files present"
}

# Step 9: Check Windows Defender / Antivirus
Write-Step "Step 8: Checking for potential antivirus blocks..."
$defenderPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
if (Test-Path $defenderPath) {
    Write-Info "Windows Defender detected"
    Write-Info "If app fails to launch, add exclusion for:"
    Write-Info "  $posRoot\build"
}

# Step 10: Launch the application
if ($Mode -eq 'build-only') {
    Write-Success "`nBuild completed. Executable location:"
    Write-Info "$exe"
    Write-Info "`nTo run the app, execute:"
    Write-Info "  .\launch_windows.ps1 debug"
    Write-Info "  OR"
    Write-Info "  cd `"$exeDir`""
    Write-Info "  .\pos_tawsil.exe"
    exit 0
}

Write-Step "Step 9: Launching application..."
Write-Info "Executable: $exe"
Write-Info "Working directory: $exeDir"
Write-Host "`n" -NoNewline

# Change to exe directory and run
Set-Location $exeDir

try {
    & ".\pos_tawsil.exe"
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -ne 0) {
        Write-Error "`nApplication exited with code: $exitCode"
        Write-Info "Common exit codes:"
        Write-Info "  259 = STILL_ACTIVE (process still running or blocked)"
        Write-Info "  3221225786 = Legacy console mode issue"
        Write-Info "  1 = General error"
        Write-Info ""
        Write-Info "Check TROUBLESHOOTING_WINDOWS.md for solutions"
        exit $exitCode
    }
} catch {
    Write-Error "Failed to launch application: $_"
    Write-Info "Error details:"
    Write-Info $_.Exception.Message
    Write-Info ""
    Write-Info "Try:"
    Write-Info "  1. Run as Administrator (right-click → Run as administrator)"
    Write-Info "  2. Check Windows Defender exclusions"
    Write-Info "  3. Check TROUBLESHOOTING_WINDOWS.md"
    exit 1
}

Write-Success "`nApplication launched successfully!"
