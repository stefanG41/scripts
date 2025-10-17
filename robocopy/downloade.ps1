# downloade.ps1 – Synct scripts/robocopy vollständig und legt stabile Wrapper + Task-Skripte an
param(
  [string]$RepoOwner   = "stefanG41",
  [string]$RepoName    = "scripts",
  [string]$Subfolder   = "robocopy",
  [string]$InstallPath = "D:\BackupScripts\robocopy",
  [string]$PromotePath = "D:\BackupScripts",
  [string]$TasksPath   = "D:\BackupScripts\tasks",
  # feste, eindeutige Namen der „oben“ erreichbaren Starter:
  [string]$ProfileWrapperName  = "backup_profile.cmd",
  [string]$PicturesWrapperName = "backup_pictures.cmd"
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir { param($p) if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function Backup-Existing {
  param($Path)
  if (Test-Path $Path) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Move-Item -Path $Path -Destination ($Path + ".bak_" + $stamp)
  }
}

Write-Host ""
Write-Host "=== Lade aktuelle Version von $RepoOwner/$RepoName/$Subfolder ==="

Ensure-Dir (Split-Path $InstallPath -Parent)
Ensure-Dir $PromotePath
Ensure-Dir $TasksPath

# 1) Default-Branch ermitteln
$headers   = @{ 'User-Agent'='PowerShell'; 'Accept'='application/vnd.github+json' }
$apiRepo   = "https://api.github.com/repos/$RepoOwner/$RepoName"
$repoInfo  = Invoke-RestMethod -Uri $apiRepo -Headers $headers
$defaultBranch = $repoInfo.default_branch
Write-Host ("Default Branch: {0}" -f $defaultBranch)

# 2) ZIP laden und ENTIRE Subfolder kopieren
$zipUrl  = "https://api.github.com/repos/$RepoOwner/$RepoName/zipball/$defaultBranch"
$zipPath = Join-Path $env:TEMP ("robocopy_" + [guid]::NewGuid().ToString() + ".zip")
$extDir  = Join-Path $env:TEMP ("robocopy_" + [guid]::NewGuid().ToString())

Write-Host "Lade ZIP..."
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -Headers $headers
Expand-Archive -Path $zipPath -DestinationPath $extDir -Force

$root = Get-ChildItem -Directory $extDir | Select-Object -First 1
if (-not $root) { throw "ZIP-Struktur unerwartet." }
$srcPath = Join-Path $root.FullName $Subfolder
if (-not (Test-Path $srcPath)) { throw ("Unterordner '{0}' nicht gefunden in {1}" -f $Subfolder, $root.FullName) }

# Bestehenden Stand sicher ersetzen (immer überschreiben)
if (Test-Path $InstallPath) { Remove-Item -Path $InstallPath -Recurse -Force }
Copy-Item -Path $srcPath -Destination $InstallPath -Recurse -Force

Remove-Item $zipPath -Force
Remove-Item $extDir -Recurse -Force
Write-Host ("Kompletter Ordner synchronisiert nach: {0}" -f $InstallPath)

# 3) Tatsächliche .bat-Dateien finden
$patternsProfile  = @('*profile*.bat','*profil*.bat')
$patternsPictures = @('*picture*.bat','*bilder*.bat','*photos*.bat','*fotos*.bat')

$profileBat  = Get-ChildItem -Path $InstallPath -Recurse -Include $patternsProfile  -ErrorAction SilentlyContinue | Select-Object -First 1
$picturesBat = Get-ChildItem -Path $InstallPath -Recurse -Include $patternsPictures -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $profileBat)  { Write-Warning "Kein Profil-Backup .bat gefunden." }
if (-not $picturesBat) { Write-Warning "Kein Bilder-Backup .bat gefunden." }

# 4) Wrapper-CMDs mit stabilen Namen erzeugen (immer überschreiben)
$profileWrapperPath  = Join-Path $PromotePath  $ProfileWrapperName
$picturesWrapperPath = Join-Path $PromotePath  $PicturesWrapperName

if ($profileBat) {
  @"
@echo off
REM Wrapper fuer Profil-Backup (stabiler Name)
setlocal
call "$($profileBat.FullName)"
endlocal
"@ | Set-Content -Path $profileWrapperPath -Encoding ASCII -Force
  Write-Host ("Profil-Wrapper erstellt: {0}" -f $profileWrapperPath)
}

if ($picturesBat) {
  @"
@echo off
REM Wrapper fuer Bilder-Backup (stabiler Name)
setlocal
call "$($picturesBat.FullName)"
endlocal
"@ | Set-Content -Path $picturesWrapperPath -Encoding ASCII -Force
  Write-Host ("Bilder-Wrapper erstellt: {0}" -f $picturesWrapperPath)
}

# 5) Zusatzskripte fuer Aufgabenplanung (in Extra-Ordner) erzeugen
#    - Create-Tasks.ps1 / Remove-Tasks.ps1
#    - nutzen die stabilen Wrapper-Dateien oben

$createPs1 = @"
param(
  [string]`$ProfileCmd  = "$profileWrapperPath",
  [string]`$PicturesCmd = "$picturesWrapperPath",
  [string]`$TaskFolder  = "\Robocopy"
)

Import-Module ScheduledTasks

function New-WeeklyTriggerAt([string]`$day, [string]`$time) {
  # z.B. day="THU", time="19:00"
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek `$day -At `$time
}

function Ensure-TaskFolder([string]`$folder) {
  try { `$null = Get-ScheduledTask -TaskPath `$folder -TaskName "*" -ErrorAction Stop }
  catch {
    # Windows legt Ordner automatisch an, wenn Task mit TaskPath erstellt wird.
  }
}

Ensure-TaskFolder -folder `$TaskFolder

# Principal: ohne Passwort, nur wenn User angemeldet (InteractiveToken)
`$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType InteractiveToken -RunLevel LeastPrivilege

# Aktionen
if (Test-Path `$ProfileCmd) {
  `$a1 = New-ScheduledTaskAction -Execute `$ProfileCmd
  Register-ScheduledTask -TaskName "Robocopy_Profile_Backup" -TaskPath `$TaskFolder -Action `$a1 `
    -Trigger (New-WeeklyTriggerAt -day "THU" -time "19:00") -Principal `$principal -Force | Out-Null
  Write-Host "Task erstellt: $TaskFolder\Robocopy_Profile_Backup"
}

if (Test-Path `$PicturesCmd) {
  `$a2 = New-ScheduledTaskAction -Execute `$PicturesCmd
  Register-ScheduledTask -TaskName "Robocopy_Pictures_Backup" -TaskPath `$TaskFolder -Action `$a2 `
    -Trigger (New-WeeklyTriggerAt -day "THU" -time "19:15") -Principal `$principal -Force | Out-Null
  Write-Host "Task erstellt: $TaskFolder\Robocopy_Pictures_Backup"
}
"@

$removePs1 = @"
param(
  [string]`$TaskFolder = "\Robocopy"
)

Import-Module ScheduledTasks

foreach (`$name in "Robocopy_Profile_Backup","Robocopy_Pictures_Backup") {
  try {
    Unregister-ScheduledTask -TaskName `$name -TaskPath `$TaskFolder -Confirm:`$false -ErrorAction Stop
    Write-Host "Task entfernt: $TaskFolder\`$name"
  } catch {
    Write-Warning "Task nicht gefunden oder konnte nicht entfernt werden: $TaskFolder\`$name"
  }
}
"@

$createCmd = @"
@echo off
setlocal
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-Tasks.ps1"
if errorlevel 1 (
  echo Fehler beim Erstellen der Tasks.
  exit /b 1
)
echo Tasks erstellt.
pause
endlocal
"@

$removeCmd = @"
@echo off
setlocal
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Remove-Tasks.ps1"
if errorlevel 1 (
  echo Fehler beim Entfernen der Tasks.
  exit /b 1
)
echo Tasks entfernt.
pause
endlocal
"@

$createPs1  | Set-Content -Path (Join-Path $TasksPath "Create-Tasks.ps1") -Encoding ASCII -Force
$removePs1  | Set-Content -Path (Join-Path $TasksPath "Remove-Tasks.ps1") -Encoding ASCII -Force
$createCmd  | Set-Content -Path (Join-Path $TasksPath "Create-Tasks.cmd") -Encoding ASCII -Force
$removeCmd  | Set-Content -Path (Join-Path $TasksPath "Remove-Tasks.cmd") -Encoding ASCII -Force

Write-Host ("Zusatzskripte aktualisiert in: {0}" -f $TasksPath)

# 6) Commit-Info (informativ)
try {
  $apiCommit = "https://api.github.com/repos/$RepoOwner/$RepoName/commits/$defaultBranch"
  $c = Invoke-RestMethod -Uri $apiCommit -Headers $headers
  Write-Host ("Stand: {0} - {1}" -f $c.commit.author.date, $c.sha.Substring(0,7))
} catch {
  Write-Warning ("Konnte Commit-Info nicht laden: {0}" -f $_.Exception.Message)
}

Write-Host ""
Write-Host ("Fertig. Wrapper: {0}, {1}" -f $profileWrapperPath, $picturesWrapperPath)
Write-Host ("Tasks-Skripte: {0}" -f $TasksPath)
