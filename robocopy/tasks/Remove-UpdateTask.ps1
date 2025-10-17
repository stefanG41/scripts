param(
  [string]$TaskFolder = "\Robocopy",
  [string]$TaskName   = "Robocopy_UpdateFromGit"
)
$ErrorActionPreference = 'Stop'
Import-Module ScheduledTasks
try {
  Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskFolder -Confirm:$false -ErrorAction Stop
  Write-Host "Task entfernt: $TaskFolder$TaskName"
} catch {
  Write-Warning "Task nicht gefunden oder konnte nicht entfernt werden: $TaskFolder$TaskName"
}
