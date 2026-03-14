# Verifier si une IP est une imprimante reseau (port 9100, 80, 631, etc.)
# Usage: .\verifier-imprimante.ps1 192.168.1.14

param([Parameter(Mandatory=$true)][string]$IP = "192.168.1.14")

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Verification imprimante : $IP ===" -ForegroundColor Cyan

# 1. Ping
Write-Host "`n[1] Ping..." -ForegroundColor White
$ping = New-Object System.Net.NetworkInformation.Ping
$r = $ping.Send($IP, 2000)
if ($r.Status -eq 'Success') { Write-Host "    OK (TTL=$($r.Options.Ttl))" -ForegroundColor Green } else { Write-Host "    Echec" -ForegroundColor Red; exit 1 }

# 2. MAC (ARP)
Write-Host "`n[2] Adresse MAC (ARP)..." -ForegroundColor White
$mac = (arp -a | Select-String "$IP\s+([0-9a-f-]+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -join ""
if ($mac) { Write-Host "    $mac" -ForegroundColor Gray } else { Write-Host "    (inconnu)" -ForegroundColor Gray }

# 3. Ports typiques imprimantes
$ports = @(
  @{ Port=9100; Name="RAW (ESC/POS)" }
  @{ Port=9101; Name="RAW (alternative)" }
  @{ Port=631;  Name="IPP" }
  @{ Port=515;  Name="LPD" }
  @{ Port=80;   Name="Web" }
  @{ Port=443;  Name="Web HTTPS" }
)
Write-Host "`n[3] Ports imprimante (timeout 1.5 s)..." -ForegroundColor White
$open = @()
foreach ($p in $ports) {
  $t = $null
  try {
    $t = New-Object System.Net.Sockets.TcpClient
    $c = $t.BeginConnect($IP, $p.Port, $null, $null)
    if ($c.AsyncWaitHandle.WaitOne(1500, $false) -and $t.Connected) {
      Write-Host "    $($p.Port) $($p.Name) : OUVERT" -ForegroundColor Green
      $open += $p.Port
      $t.Close()
    }
  } catch {}
  if ($t) { try { $t.Close() } catch {} }
}
if ($open.Count -eq 0) { Write-Host "    Aucun port imprimante ouvert (9100, 631, 80...)" -ForegroundColor Yellow }

# 4. HTTP (si 80 ouvert, on a deja affiche; sinon tenter quand meme)
if ($open -notcontains 80) {
  Write-Host "`n[4] HTTP (port 80)..." -ForegroundColor White
  try {
    $resp = Invoke-WebRequest -Uri "http://${IP}/" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    Write-Host "    OK - Serveur: $($resp.Headers['Server'])" -ForegroundColor Green
    if ($resp.Content -match 'printer|print|imprimante|epson|star|bixolon|receipt') { Write-Host "    -> Contenu evoque une imprimante" -ForegroundColor Green }
  } catch { Write-Host "    Timeout ou refus (normal si pas de serveur web)" -ForegroundColor Gray }
}

# 5. Verdict
Write-Host "`n=== Verdict ===" -ForegroundColor Cyan
if ($open -contains 9100) {
  Write-Host "  OUI : $IP est tres probablement une imprimante (port 9100 RAW ouvert)." -ForegroundColor Green
  Write-Host "  -> Utilisez IP=$IP, port=9100 dans l'admin Tawsil."
} elseif ($open -contains 631 -or $open -contains 515 -or $open -contains 80) {
  Write-Host "  POSSIBLE : $IP expose des ports courants pour imprimantes (IPP/LPD/Web)." -ForegroundColor Yellow
  Write-Host "  -> Le pilote ESC/POS RAW necessite le port 9100. Verifiez le menu reseau de l'imprimante."
} else {
  Write-Host "  NON CONCLUANT : aucun port d'imprimante detecte sur $IP." -ForegroundColor Yellow
  Write-Host "  L'appareil repond au ping (et est bien sur le reseau) mais n'expose pas 9100, 631, 80." -ForegroundColor Gray
  Write-Host "  -> Si c'est votre imprimante : activer 'Raw TCP' / 'Port 9100' dans son menu reseau." -ForegroundColor Gray
  Write-Host "  -> Pour confirmer l'IP : imprimer une page de config reseau depuis l'imprimante, ou voir http://192.168.1.1 (appareils connectes)." -ForegroundColor Gray
}
