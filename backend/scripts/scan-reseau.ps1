# Scan du reseau 192.168.1.x - trouve les appareils et les imprimantes (port 9100)
# Lancez dans PowerShell : .\scripts\scan-reseau.ps1

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Reseau local (votre PC) ===" -ForegroundColor Cyan
$pc = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
if ($pc) { Write-Host "  PC: $($pc.IPAddress) sur $($pc.InterfaceAlias)" } else { Write-Host "  (indetermine)" }

Write-Host "`n=== Appareils repondant au ping (192.168.1.1 a .100) ===" -ForegroundColor Cyan
$ping = New-Object System.Net.NetworkInformation.Ping
$found = @()
1..100 | ForEach-Object {
  $ip = "192.168.1.$_"
  try {
    $r = $ping.Send($ip, 350)
    if ($r.Status -eq 'Success') { $found += $ip }
  } catch {}
}
$found | ForEach-Object { Write-Host "  $_" }

Write-Host "`n=== Test port 9100 sur les IP qui repondent au ping ===" -ForegroundColor Cyan
$printers = @()
foreach ($ip in $found) {
  $t = $null
  try {
    $t = New-Object System.Net.Sockets.TcpClient
    $async = $t.BeginConnect($ip, 9100, $null, $null)
    $ok = $async.AsyncWaitHandle.WaitOne(600, $false)
    if ($ok -and $t.Connected) {
      Write-Host "  $ip :9100 OUVERT (imprimante possible)" -ForegroundColor Green
      $printers += $ip
      $t.Close()
    }
  } catch {}
  finally { if ($t) { try { $t.Close() } catch {} } }
}

# Si aucune imprime trouvee, scan direct du port 9100 (imprimantes qui ne pingent pas)
if ($printers.Count -eq 0) {
  Write-Host "`n=== Scan port 9100 sur 192.168.1.2 a .150 (sans ping) ===" -ForegroundColor Cyan
  2..150 | ForEach-Object {
    $ip = "192.168.1.$_"
    if ($found -contains $ip) { return }
    $t = $null
    try {
      $t = New-Object System.Net.Sockets.TcpClient
      $c = $t.BeginConnect($ip, 9100, $null, $null)
      if ($c.AsyncWaitHandle.WaitOne(200, $false) -and $t.Connected) {
        Write-Host "  $ip :9100 OUVERT (imprimante possible)" -ForegroundColor Green
        $printers += $ip
        $t.Close()
      }
    } catch {}
    if ($t) { try { $t.Close() } catch {} }
  }
}

Write-Host "`n=== Cache ARP (appareils vus par le PC) ===" -ForegroundColor Cyan
arp -a | Select-String "192.168.1."

Write-Host "`n=== Resume ===" -ForegroundColor Yellow
if ($printers.Count -gt 0) {
  Write-Host "  Imprimante(s) detectee(s) : $($printers -join ', ')" -ForegroundColor Green
  Write-Host "  -> Dans l'admin : Restaurants > [votre resto] > Imprimantes > IP = $($printers[0]) , port 9100"
} else {
  Write-Host "  Aucun port 9100 ouvert. Si l'imprimante est bien en 192.168.1.x :" -ForegroundColor Yellow
  Write-Host "  - Activer 'Raw TCP' / 'Port 9100' / 'Port d'impression reseau' dans le menu de l'imprimante"
  Write-Host "  - Verifier l'IP reelle : http://192.168.1.1 (appareils connectes) ou page config imprimante"
}
Write-Host "  Liste complete des appareils : http://192.168.1.1 -> appareils connectes / DHCP"
