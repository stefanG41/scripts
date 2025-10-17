param(
  [string]$TaskFolder = "\Robocopy",
  [string]$TaskName   = "Robocopy_UpdateFromGit",
  [string]$RunnerCmd  = "D:\BackupScripts\downloade.cmd",
  [int]$LogonDelaySec = 90,     # Start N Sekunden nach Benutzer-Anmeldung
  [string]$DailyTime  = "12:00" # optionaler Fallback-Lauf einmal täglich
)

$ErrorActionPreference = 'Stop'
Import-Module ScheduledTasks

if (-not (Test-Path $RunnerCmd)) {
  throw "Runner nicht gefunden: $RunnerCmd"
}

# Aktion
$action = New-ScheduledTaskAction -Execute $RunnerCmd

# Trigger 1: beim Anmelden, mit Verzögerung
$tr1 = New-ScheduledTaskTrigger -AtLogOn
$tr1.Delay = "PT${LogonDelaySec}S"   # ISO-8601: PT90S = 90 Sekunden

# Trigger 2 (optional): täglich um Uhrzeit X als Fallback
$tr2 = New-ScheduledTaskTrigger -Daily -At $DailyTime

# Principal: aktueller Benutzer, ohne Passwort, nur wenn angemeldet
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType InteractiveToken -RunLevel LeastPrivilege

# Registrieren (überschreiben, falls vorhanden)
Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder `
  -Action $action -Trigger @($tr1,$tr2) -Principal $principal -Force | Out-Null

Write-Host "Task erstellt: $TaskFolder$TaskName"
Write-Host "  - Start bei Anmeldung (+$LogonDelaySec s)"
Write-Host "  - Zusätzlich täglich um $DailyTime (Fallback)"
