# Script PowerShell pour lancer toutes les applications Tawssil
# Backend, Frontend Admin, Admin Dashboard Flutter, POS Flutter, et Landing Page

Write-Host "Demarrage de tous les services Tawssil..." -ForegroundColor Green
Write-Host ""

# Fonction pour vérifier si un port est utilisé
function Test-Port {
    param($Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

# Chemin du projet racine
$rootPath = $PSScriptRoot
$backendPath = Join-Path $rootPath "tawssilbackyou"
$adminFrontendPath = Join-Path (Join-Path $rootPath "tawssilfrontyou") "tawsil-admin"
$adminDashboardPath = Join-Path $rootPath "admin_dashboard"
$posAppPath = Join-Path $rootPath "pos_tawsil"
$landingPath = Join-Path $rootPath "tawssil-landing"

# Vérifier les ports
Write-Host "Verification des ports..." -ForegroundColor Yellow

$ports = @{
    8000 = "Backend API"
    3001 = "Admin Frontend (Next.js)"
    8080 = "Admin Dashboard Flutter (Web)"
    8081 = "POS Flutter (Web)"
    8082 = "Landing Page"
}

foreach ($port in $ports.Keys) {
    if (Test-Port -Port $port) {
        Write-Host "ATTENTION: Port $port ($($ports[$port])) est deja utilise" -ForegroundColor Red
    } else {
        Write-Host "OK: Port $port ($($ports[$port])) disponible" -ForegroundColor Green
    }
}

Write-Host ""

# 1. Démarrer le backend
Write-Host "Demarrage du backend (port 8000)..." -ForegroundColor Cyan
if (Test-Path $backendPath) {
    $backendCmd = "cd '$backendPath'; `$env:PORT=8000; Write-Host 'Backend API - Port 8000' -ForegroundColor Cyan; npm start"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd -WindowStyle Normal
    Start-Sleep -Seconds 2
} else {
    Write-Host "ATTENTION: Backend path not found: $backendPath" -ForegroundColor Red
}

# 2. Démarrer le dashboard admin Next.js
Write-Host "Demarrage du dashboard admin Next.js (port 3001)..." -ForegroundColor Cyan
if (Test-Path $adminFrontendPath) {
    $adminCmd = "cd '$adminFrontendPath'; Write-Host 'Admin Frontend (Next.js) - Port 3001' -ForegroundColor Cyan; npm run dev"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $adminCmd -WindowStyle Normal
    Start-Sleep -Seconds 2
} else {
    Write-Host "ATTENTION: Admin frontend path not found: $adminFrontendPath" -ForegroundColor Red
}

# 3. Démarrer l'application Flutter Admin Dashboard en mode web
Write-Host "Demarrage de l'application Flutter Admin Dashboard (port 8080)..." -ForegroundColor Cyan
if (Test-Path $adminDashboardPath) {
    $adminFlutterCmd = "cd '$adminDashboardPath'; Write-Host 'Admin Dashboard Flutter - Port 8080' -ForegroundColor Cyan; flutter run -d chrome --web-port=8080"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $adminFlutterCmd -WindowStyle Normal
    Start-Sleep -Seconds 3
} else {
    Write-Host "ATTENTION: Admin dashboard path not found: $adminDashboardPath" -ForegroundColor Red
}

# 4. Démarrer l'application Flutter POS en mode web
Write-Host "Demarrage de l'application Flutter POS (port 8081)..." -ForegroundColor Cyan
if (Test-Path $posAppPath) {
    $posCmd = "cd '$posAppPath'; Write-Host 'POS Flutter App - Port 8081' -ForegroundColor Cyan; flutter run -d chrome --web-port=8081"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $posCmd -WindowStyle Normal
    Start-Sleep -Seconds 3
} else {
    Write-Host "ATTENTION: POS app path not found: $posAppPath" -ForegroundColor Red
}

# 5. Démarrer la landing page avec un serveur HTTP simple
Write-Host "Demarrage de la landing page (port 8082)..." -ForegroundColor Cyan
if (Test-Path $landingPath) {
    # Vérifier si Python est disponible pour servir la page
    $pythonAvailable = $false
    try {
        $null = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $pythonAvailable = $true
        }
    } catch {
        # Python not available
    }
    
    if ($pythonAvailable) {
        $landingCmd = "cd '$landingPath'; Write-Host 'Landing Page - Port 8082' -ForegroundColor Cyan; python -m http.server 8082"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $landingCmd -WindowStyle Normal
    } else {
        # Utiliser Node.js http-server si disponible
        $nodeAvailable = $false
        try {
            $null = node --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $nodeAvailable = $true
            }
        } catch {
            # Node not available
        }
        
        if ($nodeAvailable) {
            $landingCmd = "cd '$landingPath'; Write-Host 'Landing Page - Port 8082' -ForegroundColor Cyan; npx --yes http-server -p 8082 -c-1"
            Start-Process powershell -ArgumentList "-NoExit", "-Command", $landingCmd -WindowStyle Normal
        } else {
            Write-Host "ATTENTION: Python ou Node.js non disponible. La landing page peut etre ouverte directement dans le navigateur." -ForegroundColor Yellow
            $landingUrl = "file:///$($landingPath.Replace('\', '/'))/index.html"
            Write-Host "   Ouvrez: $landingUrl" -ForegroundColor Gray
        }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Host "ATTENTION: Landing page path not found: $landingPath" -ForegroundColor Red
}

Write-Host ""
Write-Host "Tous les services ont ete lances!" -ForegroundColor Green
Write-Host ""
Write-Host "URLs des applications:" -ForegroundColor Yellow
Write-Host "  - Backend API:           http://localhost:8000" -ForegroundColor White
Write-Host "  - Admin Frontend:        http://localhost:3001" -ForegroundColor White
Write-Host "  - Admin Dashboard:       http://localhost:8080" -ForegroundColor White
Write-Host "  - POS Flutter App:       http://localhost:8081" -ForegroundColor White
Write-Host "  - Landing Page:          http://localhost:8082" -ForegroundColor White
Write-Host ""
Write-Host "Appuyez sur Ctrl+C dans chaque fenetre pour arreter les services" -ForegroundColor Gray
Write-Host ""
