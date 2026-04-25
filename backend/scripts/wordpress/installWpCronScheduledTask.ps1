param(
  [string]$TaskName = "WP Cron Trigger",
  [string]$BackendPath = "",
  [int]$IntervalMinutes = 5,
  [string]$BaseUrl = "",
  [string]$NodeExe = "C:\Program Files\nodejs\node.exe"
)

if (-not $BackendPath) {
  $BackendPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

if ($IntervalMinutes -lt 1) {
  throw "IntervalMinutes must be at least 1."
}

$scriptPath = Join-Path $BackendPath "scripts\wordpress\triggerWpCron.mjs"

if (-not (Test-Path $scriptPath)) {
  throw "Cron trigger script not found at $scriptPath"
}

if (-not (Test-Path $NodeExe)) {
  throw "Node executable not found at $NodeExe"
}

$arguments = @("`"$scriptPath`"")
if ($BaseUrl) {
  $arguments += "--base-url"
  $arguments += "`"$BaseUrl`""
}

$action = New-ScheduledTaskAction -Execute $NodeExe -Argument ($arguments -join ' ') -WorkingDirectory $BackendPath
$startAt = (Get-Date).AddMinutes(1)
$trigger = New-ScheduledTaskTrigger -Once -At $startAt -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 3650)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
Write-Host "Scheduled task '$TaskName' registered every $IntervalMinutes minutes starting at $($startAt.ToString('yyyy-MM-dd HH:mm'))"
