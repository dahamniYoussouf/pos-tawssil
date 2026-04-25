param(
  [string]$TaskName = "WP Product Category Menu Sync",
  [string]$BackendPath = "",
  [string]$Time = "03:00",
  [string]$NodeExe = "C:\Program Files\nodejs\node.exe"
)

if (-not $BackendPath) {
  $BackendPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$scriptPath = Join-Path $BackendPath "scripts\wordpress\syncProductCategoryMenu.mjs"

if (-not (Test-Path $scriptPath)) {
  throw "Sync script not found at $scriptPath"
}

$action = New-ScheduledTaskAction -Execute $NodeExe -Argument "`"$scriptPath`"" -WorkingDirectory $BackendPath
$trigger = New-ScheduledTaskTrigger -Daily -At $Time
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
Write-Host "Scheduled task '$TaskName' registered for $Time"
