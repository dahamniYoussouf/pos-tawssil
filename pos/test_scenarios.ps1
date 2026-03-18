# Script pour tester différents scénarios réseau avec le POS
# Simule différents cas réels pour tester la détection réseau et les imprimantes

param(
    [Parameter(Position=0)]
    [ValidateSet('all', 'network-detection', 'printer-scan', 'ip-test', 'diagnostics', 'help')]
    [string]$Test = 'help'
)

$ErrorActionPreference = "Continue"

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
if ($Test -eq 'help') {
    Write-Info "=== POS Tawsil - Tests de Scénarios ==="
    Write-Host ""
    Write-Host "Ce script aide à tester différents scénarios réseau avec le POS"
    Write-Host ""
    Write-Host "Usage: .\test_scenarios.ps1 [test]"
    Write-Host ""
    Write-Host "Tests disponibles:"
    Write-Host "  all              - Exécute tous les tests"
    Write-Host "  network-detection - Teste la détection réseau"
    Write-Host "  printer-scan      - Teste le scan d'imprimantes"
    Write-Host "  ip-test          - Teste une IP d'imprimante spécifique"
    Write-Host "  diagnostics      - Affiche les informations de diagnostic"
    Write-Host ""
    Write-Host "Exemples:"
    Write-Host "  .\test_scenarios.ps1 network-detection"
    Write-Host "  .\test_scenarios.ps1 ip-test"
    Write-Host ""
    exit 0
}

# Vérifier que Flutter est installé
Write-Info "Vérification de Flutter..."
try {
    $null = flutter --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter non trouvé"
    }
    Write-Success "Flutter détecté"
} catch {
    Write-Error "Flutter n'est pas installé"
    exit 1
}

# Chemin du projet
$posPath = $PSScriptRoot
Set-Location $posPath

# Test de détection réseau
function Test-NetworkDetection {
    Write-Info "=== Test de Détection Réseau ==="
    Write-Host ""
    
    Write-Info "1. Vérification des interfaces réseau..."
    $interfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" }
    
    if ($interfaces) {
        Write-Success "Interfaces réseau trouvées:"
        foreach ($iface in $interfaces) {
            Write-Host "  - $($iface.IPAddress) ($($iface.InterfaceAlias))"
        }
    } else {
        Write-Warning "Aucune interface réseau trouvée (hors loopback)"
    }
    
    Write-Host ""
    Write-Info "2. Test de connectivité..."
    $connectivity = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($connectivity) {
        Write-Success "Connectivité Internet: OK"
    } else {
        Write-Warning "Connectivité Internet: Échec"
    }
    
    Write-Host ""
    Write-Info "3. Test de détection réseau local..."
    $localNetwork = $interfaces | Where-Object { $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*" }
    if ($localNetwork) {
        $networkBase = ($localNetwork[0].IPAddress -split '\.')[0..2] -join '.'
        Write-Success "Réseau local détecté: $networkBase.x"
    } else {
        Write-Warning "Aucun réseau local détecté"
    }
    
    Write-Host ""
}

# Test de scan d'imprimantes
function Test-PrinterScan {
    Write-Info "=== Test de Scan d'Imprimantes ==="
    Write-Host ""
    
    Write-Info "Pour tester le scan d'imprimantes:"
    Write-Host "1. Lancez le POS avec: .\run_pos.ps1 debug"
    Write-Host "2. Allez dans 'Imprimantes' > 'Diagnostic'"
    Write-Host "3. Utilisez les boutons de test pour vérifier chaque composant"
    Write-Host ""
    
    # Vérifier si des ports d'imprimantes sont ouverts
    Write-Info "Vérification des ports d'imprimantes communs..."
    $commonPorts = @(9100, 9101, 631, 515, 80)
    $networkBase = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "192.168.*" } | Select-Object -First 1).IPAddress
    if ($networkBase) {
        $base = ($networkBase -split '\.')[0..2] -join '.'
        Write-Info "Scan du réseau $base.x pour les ports d'imprimantes..."
        Write-Host "  (Ceci peut prendre quelques secondes...)"
        Write-Host ""
        
        $found = 0
        for ($i = 1; $i -le 10; $i++) {
            $ip = "$base.$i"
            foreach ($port in $commonPorts) {
                $result = Test-NetConnection -ComputerName $ip -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                if ($result) {
                    Write-Success "  Imprimante potentielle trouvée: $ip:$port"
                    $found++
                }
            }
        }
        
        if ($found -eq 0) {
            Write-Warning "Aucune imprimante trouvée sur les 10 premières adresses"
            Write-Info "  Cela ne signifie pas qu'il n'y a pas d'imprimantes"
            Write-Info "  Utilisez 'Tester IP' dans l'application pour tester une IP spécifique"
        }
    } else {
        Write-Warning "Impossible de détecter le réseau local pour le scan"
    }
    
    Write-Host ""
}

# Test d'une IP spécifique
function Test-SpecificIP {
    Write-Info "=== Test d'IP d'Imprimante ==="
    Write-Host ""
    
    Write-Info "Entrez l'adresse IP de l'imprimante à tester:"
    $ip = Read-Host "IP"
    
    if (-not $ip) {
        Write-Error "IP non fournie"
        return
    }
    
    # Valider le format IP
    $ipPattern = '^(\d{1,3}\.){3}\d{1,3}$'
    if ($ip -notmatch $ipPattern) {
        Write-Error "Format d'IP invalide"
        return
    }
    
    Write-Info "Test de l'IP: $ip"
    Write-Host ""
    
    $ports = @(9100, 9101, 631, 515, 80, 443)
    $found = @()
    
    foreach ($port in $ports) {
        Write-Host "  Test du port $port..." -NoNewline
        $result = Test-NetConnection -ComputerName $ip -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($result) {
            Write-Host " ✓" -ForegroundColor Green
            $found += @{Port = $port; Status = "Ouvert"}
        } else {
            Write-Host " ✗" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    if ($found.Count -gt 0) {
        Write-Success "Ports ouverts trouvés:"
        foreach ($item in $found) {
            $protocol = switch ($item.Port) {
                9100 { "RAW (ESC/POS)" }
                9101 { "RAW (alternatif)" }
                631 { "IPP" }
                515 { "LPD" }
                80 { "HTTP (interface web)" }
                443 { "HTTPS" }
                default { "Inconnu" }
            }
            Write-Host "  - Port $($item.Port): $protocol"
        }
        Write-Host ""
        Write-Info "Pour l'impression ESC/POS, utilisez généralement le port 9100"
    } else {
        Write-Warning "Aucun port ouvert trouvé sur $ip"
        Write-Info "Vérifiez que:"
        Write-Info "  1. L'imprimante est allumée"
        Write-Info "  2. L'imprimante est sur le même réseau"
        Write-Info "  3. Le firewall n'bloque pas les connexions"
    }
    
    Write-Host ""
}

# Afficher les diagnostics
function Show-Diagnostics {
    Write-Info "=== Diagnostics Système ==="
    Write-Host ""
    
    Write-Info "Informations réseau:"
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        Write-Host "  Interface: $($adapter.Name)"
        $ips = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
        foreach ($ip in $ips) {
            Write-Host "    IP: $($ip.IPAddress) / $($ip.PrefixLength)"
        }
    }
    
    Write-Host ""
    Write-Info "Connectivité:"
    $wifi = Get-NetAdapter | Where-Object { $_.Name -like "*Wi-Fi*" -or $_.Name -like "*WLAN*" }
    if ($wifi) {
        Write-Success "WiFi: $($wifi.Status)"
    } else {
        Write-Warning "WiFi: Non détecté"
    }
    
    Write-Host ""
    Write-Info "Ports d'imprimantes communs:"
    $commonPorts = @(9100, 9101, 631, 515, 80)
    foreach ($port in $commonPorts) {
        $listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($listening) {
            Write-Host "  Port $port: ÉCOUTE (service actif)"
        }
    }
    
    Write-Host ""
}

# Exécuter les tests selon le paramètre
switch ($Test) {
    'all' {
        Test-NetworkDetection
        Test-PrinterScan
        Show-Diagnostics
    }
    
    'network-detection' {
        Test-NetworkDetection
    }
    
    'printer-scan' {
        Test-PrinterScan
    }
    
    'ip-test' {
        Test-SpecificIP
    }
    
    'diagnostics' {
        Show-Diagnostics
    }
    
    default {
        Write-Error "Test inconnu: $Test"
        Write-Info "Utilisez '.\test_scenarios.ps1 help' pour voir les tests disponibles"
    }
}

Write-Host ""
Write-Success "Tests terminés!"
Write-Host ""
