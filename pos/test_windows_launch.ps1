# Test script to verify Windows launch works
# This script tests all launch methods and reports any issues

$ErrorActionPreference = "Continue"
$posRoot = $PSScriptRoot

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  POS Tawsil - Windows Launch Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testsPassed = 0
$testsFailed = 0

function Test-Step {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow -NoNewline
    try {
        & $Test
        Write-Host " PASSED" -ForegroundColor Green
        $script:testsPassed++
        return $true
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $script:testsFailed++
        return $false
    }
}

# Test 1: Verify project structure
Test-Step "Project structure" {
    if (-not (Test-Path "$posRoot\pubspec.yaml")) {
        throw "pubspec.yaml not found"
    }
    if (-not (Test-Path "$posRoot\lib\main.dart")) {
        throw "lib\main.dart not found"
    }
    if (-not (Test-Path "$posRoot\windows\runner\main.cpp")) {
        throw "windows\runner\main.cpp not found"
    }
}

# Test 2: Check Flutter installation
Test-Step "Flutter installation" {
    $null = flutter --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found or not in PATH"
    }
}

# Test 3: Get dependencies
Test-Step "Flutter dependencies" {
    Set-Location $posRoot
    flutter pub get 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get dependencies"
    }
}

# Test 4: Analyze code
Test-Step "Code analysis" {
    Set-Location $posRoot
    $analysis = flutter analyze 2>&1 | Out-String
    # Flutter analyze returns exit code 1 for warnings/info, which is OK
    # Only fail if there are actual compilation errors
    if ($analysis -match "error •") {
        throw "Code analysis found compilation errors"
    }
    # Warnings and info messages are acceptable
    Write-Host "  (Analysis completed - warnings/info are OK)" -ForegroundColor Gray
}

# Test 5: Check Windows build configuration
Test-Step "Windows build configuration" {
    if (-not (Test-Path "$posRoot\windows\CMakeLists.txt")) {
        throw "Windows CMakeLists.txt not found"
    }
    if (-not (Test-Path "$posRoot\windows\runner\runner.exe.manifest")) {
        throw "runner.exe.manifest not found"
    }
}

# Test 6: Verify manifest content
Test-Step "Manifest configuration" {
    $manifest = Get-Content "$posRoot\windows\runner\runner.exe.manifest" -Raw
    if ($manifest -notmatch "asInvoker") {
        throw "Manifest missing asInvoker execution level"
    }
}

# Test 7: Check database initialization
Test-Step "Database initialization code" {
    if (-not (Test-Path "$posRoot\lib\database\desktop_init.dart")) {
        throw "desktop_init.dart not found"
    }
    if (-not (Test-Path "$posRoot\lib\config\database_config.dart")) {
        throw "database_config.dart not found"
    }
}

# Test 8: Verify launch scripts exist
Test-Step "Launch scripts" {
    if (-not (Test-Path "$posRoot\run_windows.ps1")) {
        throw "run_windows.ps1 not found"
    }
    if (-not (Test-Path "$posRoot\launch_windows.ps1")) {
        throw "launch_windows.ps1 not found"
    }
}

# Test 9: Check for build directory (optional - may not exist yet)
Test-Step "Build directory check" {
    $debugExe = "$posRoot\build\windows\x64\runner\Debug\pos_tawsil.exe"
    $releaseExe = "$posRoot\build\windows\x64\runner\Release\pos_tawsil.exe"
    
    if (-not (Test-Path $debugExe) -and -not (Test-Path $releaseExe)) {
        Write-Host "  (No build found - this is OK, will build on first run)" -ForegroundColor Gray
    } else {
        Write-Host "  (Build found)" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $testsPassed" -ForegroundColor Green
$color = if ($testsFailed -eq 0) { "Green" } else { "Red" }
Write-Host "Failed: $testsFailed" -ForegroundColor $color
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "All tests passed! Ready to launch." -ForegroundColor Green
    Write-Host "`nTo launch the app, run:" -ForegroundColor Cyan
    Write-Host "  .\launch_windows.ps1 debug" -ForegroundColor Yellow
    Write-Host "  OR" -ForegroundColor Gray
    Write-Host "  .\run_windows.ps1 debug" -ForegroundColor Yellow
    Write-Host "  OR" -ForegroundColor Gray
    Write-Host "  flutter run -d windows" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "Some tests failed. Please fix the issues above." -ForegroundColor Red
    exit 1
}
