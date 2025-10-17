param(
  [string]$RepoOwner   = "stefanG41",
  [string]$RepoName    = "scripts",
  [string]$Subfolder   = "robocopy",
  [string]$InstallPath = "D:\BackupScripts\robocopy",
  [string]$PromotePath = "D:\BackupScripts",
  [string]$TasksPath   = "D:\BackupScripts\tasks",
  [string]$ProfileWrapperName  = "backup_profile.cmd",
  [string]$PicturesWrapperName = "backup_pictures.cmd"
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir { param($p) if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function Read-Text($p)  { if (Test-Path $p) { Get-Content -Path $p -Raw -ErrorAction SilentlyContinue } else { "" } }
function Write-Text($p,$txt) { $dir = Split-Path $p; if ($dir) { Ensure-Dir $dir }; Set-Content -Path $p -Value $txt -Encoding ASCII -Force }

Write-Host ""
Write-Host "=== Sync Git $RepoOwner/$RepoName/$Subfolder ==="

Ensure-Dir (Split-Path $InstallPath -Parent)
Ensure-Dir $PromotePath
Ensure-Dir $TasksPath

# 1) Aktuelle Commit-SHA holen
$headers   = @{ 'User-Agent'='PowerShell'; 'Accept'='application/vnd.github+json' }
$apiRepo   = "https://api.github.com/repos/$RepoOwner/$RepoName"
$repoInfo  = Invoke-RestMethod -Uri $apiRepo -Headers $headers
$defaultBranch = $repoInfo.default_branch

$apiCommit = "https://api.github.com/repos/$RepoOwner/$RepoName/commits/$defaultBranch"
$commitInfo = Invoke-RestMethod -Uri $apiCommit -Headers $headers
$latestSha  = $commitInfo.sha.Substring(0,40)

# 2) Lokale Version lesen
$versionFile = Join-Path $InstallPath ".version"
$localSha    = Read-Text $versionFile
if ($localSha -ne "") { $localSha = $localSha.Trim() }

Write-Host ("Remote SHA: {0}" -f $latestSha)
Write-Host ("Local  SHA: {0}" -f ($localSha -ne "" ? $localSha : "<none>"))

# 3) Nur laden, wenn sich was geändert hat
$needDownload = $true
if ($localSha -eq $latestSha -and (Test-Path $InstallPath)) {
  $needDownload = $false
  Write-Host "Keine Änderungen auf GitHub – Skip Download."
}

if ($needDownload) {
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

  if (Test-Path $InstallPath) { Remove-Item -Path $InstallPath -Recurse -Force }
  Copy-Item -Path $srcPath -Destination $InstallPath -Recurse -Force

  # Temp aufräumen
  Remove-Item $zipPath -Force
  Remove-Item $extDir -Recurse -Force

  # MOTW entfernen
  try {
    Get-ChildItem -Path $InstallPath -Recurse -File -ErrorAction SilentlyContinue |
      ForEach-Object { Unblock-File -Path $_.FullName -ErrorAction SilentlyContinue }
    Write-Host "Unblock-File für alle synchronisierten Dateien ausgeführt."
  } catch { Write-Warning ("Unblock-File Fehler: {0}" -f $_.Exception.Message) }

  # neue Version schreiben
  Write-Text $versionFile $latestSha
  Write-Host ("Ordner synchronisiert nach: {0}" -f $InstallPath)
}

# 4) Wrapper (stabile Namen) aktualisieren
$patternsProfile  = @('*profile*.bat','*profil*.bat')
$patternsPictures = @('*picture*.bat','*bilder*.bat','*photos*.bat','*fotos*.bat')

$profileBat  = Get-ChildItem -Path $InstallPath -Recurse -Include $patternsProfile  -ErrorAction SilentlyContinue | Select-Object -First 1
$picturesBat = Get-ChildItem -Path $InstallPath -Recurse -Include $patternsPictures -ErrorAction SilentlyContinue | Select-Object -First 1

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
  Write-Host ("Profil-Wrapper: {0}" -f $profileWrapperPath)
}

if ($picturesBat) {
@"
@echo off
REM Wrapper fuer Bilder-Backup (stabiler Name)
setlocal
call "$($picturesBat.FullName)"
endlocal
"@ | Set-Content -Path $picturesWrapperPath -Encoding ASCII -Force
  Write-Host ("Bilder-Wrapper: {0}" -f $picturesWrapperPath)
}

# 5) (Optional) Commit-Info
Write-Host ("Stand: {0} - {1}" -f $commitInfo.commit.author.date, $latestSha.Substring(0,7))

Write-Host "Fertig."
