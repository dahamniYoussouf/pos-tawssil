# Script PowerShell pour lancer le POS Tawsil avec différents scénarios de test
# Usage: .\run_pos.ps1 [scenario]
# Scénarios: normal, no-network, debug, android, ios, web

param(
    [Parameter(Position=0)]
    [ValidateSet('normal', 'no-network', 'debug', 'android', 'ios', 'web', 'help')]
    [string]$Scenario = 'normal'
)

$ErrorActionPreference = "Stop"

# Couleurs pour les messages
function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

# Afficher l'aide
if ($Scenario -eq 'help') {
    Write-Info "=== POS Tawsil - Script de Lancement ==="
    Write-Host ""
    Write-Host "Usage: .\run_pos.ps1 [scenario]"
    Write-Host ""
    Write-Host "Scénarios disponibles:"
    Write-Host "  normal      - Lancement normal (mode release, web sur port 8081)"
    Write-Host "  no-network  - Simule un problème réseau (pour tester la détection)"
    Write-Host "  debug       - Mode debug avec logs détaillés"
    Write-Host "  android     - Lance sur un appareil/émulateur Android"
    Write-Host "  ios         - Lance sur un appareil/émulateur iOS (macOS uniquement)"
    Write-Host "  web         - Lance en mode web (Chrome)"
    Write-Host ""
    Write-Host "Exemples:"
    Write-Host "  .\run_pos.ps1 normal"
    Write-Host "  .\run_pos.ps1 debug"
    Write-Host "  .\run_pos.ps1 android"
    Write-Host ""
    exit 0
}

# Vérifier que Flutter est installé
Write-Info "Vérification de Flutter..."
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter non trouvé"
    }
    Write-Success "Flutter détecté: $flutterVersion"
} catch {
    Write-Error "Flutter n'est pas installé ou n'est pas dans le PATH"
    Write-Host "Installez Flutter depuis: https://flutter.dev/docs/get-started/install"
    exit 1
}

# Chemin du projet POS
$posPath = $PSScriptRoot
if (-not (Test-Path "$posPath\pubspec.yaml")) {
    Write-Error "Ce script doit être exécuté depuis le dossier pos_tawsil"
    exit 1
}

Set-Location $posPath

# Vérifier les dépendances
Write-Info "Vérification des dépendances Flutter..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors de la récupération des dépendances"
    exit 1
}

# Fonction pour vérifier si un port est utilisé
function Test-Port {
    param($Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

# Fonction pour lancer en mode web
function Start-WebMode {
    param(
        [int]$Port = 8081,
        [switch]$Debug
    )
    
    if (Test-Port -Port $Port) {
        Write-Warning "Le port $Port est déjà utilisé. Arrêt du processus..."
        $process = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | 
                   Select-Object -ExpandProperty OwningProcess -First 1
        if ($process) {
            Stop-Process -Id $process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Info "Lancement du POS en mode web (port $Port)..."
    Write-Info "URL: http://localhost:$Port"
    
    $debugFlag = if ($Debug) { "--debug" } else { "--release" }
    
    $command = "flutter run -d chrome --web-port=$Port $debugFlag"
    Write-Info "Commande: $command"
    
    Invoke-Expression $command
}

# Fonction pour lancer sur Android
function Start-AndroidMode {
    param([switch]$Debug)
    
    Write-Info "Vérification des appareils Android..."
    $devices = flutter devices | Select-String "android"
    
    if (-not $devices) {
        Write-Warning "Aucun appareil Android détecté"
        Write-Info "Options:"
        Write-Info "  1. Connectez un appareil Android via USB (avec USB Debugging activé)"
        Write-Info "  2. Lancez un émulateur Android depuis Android Studio"
        Write-Info "  3. Utilisez 'flutter emulators' pour voir les émulateurs disponibles"
        Write-Info ""
        Write-Info "Voulez-vous lister les émulateurs disponibles? (O/N)"
        $response = Read-Host
        if ($response -eq 'O' -or $response -eq 'o') {
            flutter emulators
        }
        exit 1
    }
    
    Write-Success "Appareil(s) Android détecté(s)"
    $debugFlag = if ($Debug) { "--debug" } else { "--release" }
    
    Write-Info "Lancement sur Android..."
    flutter run -d android $debugFlag
}

# Fonction pour lancer sur iOS
function Start-IOSMode {
    param([switch]$Debug)
    
    if ($IsWindows -or $IsLinux) {
        Write-Error "iOS nécessite macOS et Xcode"
        exit 1
    }
    
    Write-Info "Vérification des appareils iOS..."
    $devices = flutter devices | Select-String "ios"
    
    if (-not $devices) {
        Write-Warning "Aucun appareil iOS détecté"
        Write-Info "Options:"
        Write-Info "  1. Connectez un iPhone/iPad via USB"
        Write-Info "  2. Lancez le simulateur iOS depuis Xcode"
        Write-Info "  3. Utilisez 'flutter emulators' pour voir les simulateurs disponibles"
        exit 1
    }
    
    Write-Success "Appareil(s) iOS détecté(s)"
    $debugFlag = if ($Debug) { "--debug" } else { "--release" }
    
    Write-Info "Lancement sur iOS..."
    flutter run -d ios $debugFlag
}

# Fonction pour simuler un problème réseau
function Start-NoNetworkMode {
    Write-Warning "=== MODE SIMULATION: Problème Réseau ==="
    Write-Info "Ce mode lance l'application pour tester la détection réseau"
    Write-Info "L'application devrait afficher des erreurs de détection réseau"
    Write-Info "Utilisez l'écran de diagnostic pour tester les différents scénarios"
    Write-Host ""
    
    Start-WebMode -Port 8081 -Debug
}

# Traitement selon le scénario
Write-Host ""
Write-Info "=== POS Tawsil - Scénario: $Scenario ==="
Write-Host ""

switch ($Scenario) {
    'normal' {
        Write-Info "Lancement en mode normal (web, release)..."
        Start-WebMode -Port 8081
    }
    
    'no-network' {
        Start-NoNetworkMode
    }
    
    'debug' {
        Write-Info "Lancement en mode debug (web, logs détaillés)..."
        Start-WebMode -Port 8081 -Debug
    }
    
    'android' {
        Start-AndroidMode -Debug
    }
    
    'ios' {
        Start-IOSMode -Debug
    }
    
    'web' {
        Write-Info "Lancement en mode web (Chrome)..."
        Start-WebMode -Port 8081 -Debug
    }
    
    default {
        Write-Error "Scénario inconnu: $Scenario"
        Write-Info "Utilisez '.\run_pos.ps1 help' pour voir les scénarios disponibles"
        exit 1
    }
}

Write-Host ""
Write-Success "Application lancée!"
Write-Info "Pour arrêter, appuyez sur Ctrl+C dans la fenêtre Flutter"
Write-Host ""
