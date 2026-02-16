# Script PowerShell pour lancer le backend, le dashboard et l'application Flutter en mode web

Write-Host "🚀 Démarrage de tous les services..." -ForegroundColor Green
Write-Host ""

# Fonction pour vérifier si un port est utilisé
function Test-Port {
    param($Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

# Vérifier les ports
Write-Host "📋 Vérification des ports..." -ForegroundColor Yellow

if (Test-Port -Port 8000) {
    Write-Host "⚠️  Port 8000 est déjà utilisé" -ForegroundColor Red
} else {
    Write-Host "✅ Port 8000 disponible" -ForegroundColor Green
}

if (Test-Port -Port 3000) {
    Write-Host "⚠️  Port 3000 est déjà utilisé" -ForegroundColor Red
} else {
    Write-Host "✅ Port 3000 disponible" -ForegroundColor Green
}

Write-Host ""

# Chemin du projet racine
$rootPath = Split-Path -Parent $PSScriptRoot
$backendPath = Join-Path $rootPath "tawssilbackyou"
$dashboardPath = Join-Path $rootPath "tawssilfrontyou" "tawsil-admin"
$flutterPath = $PSScriptRoot

# Démarrer le backend
Write-Host "🔧 Démarrage du backend (port 8000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; `$env:PORT=8000; npm start" -WindowStyle Normal

# Attendre quelques secondes pour que le backend démarre
Start-Sleep -Seconds 3

# Démarrer le dashboard admin (Next.js)
Write-Host "📊 Démarrage du dashboard admin Next.js (port 3000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$dashboardPath'; `$env:PORT=3000; npm run dev" -WindowStyle Normal

# Attendre quelques secondes pour que le dashboard démarre
Start-Sleep -Seconds 3

# Démarrer l'application Flutter en mode web
Write-Host "📱 Démarrage de l'application Flutter en mode web..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$flutterPath'; flutter run -d chrome --web-port=8080" -WindowStyle Normal

Write-Host ""
Write-Host "✅ Tous les services ont été lancés!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 URLs:" -ForegroundColor Yellow
Write-Host "  - Backend API: http://localhost:8000" -ForegroundColor White
Write-Host "  - Dashboard Admin: http://localhost:3000" -ForegroundColor White
Write-Host "  - App Flutter Web: http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "💡 Appuyez sur Ctrl+C dans chaque fenêtre pour arrêter les services" -ForegroundColor Gray
