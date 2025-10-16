# downloade.ps1 – lädt den Ordner scripts/robocopy aus GitHub und „promoted“ Profil-/Bilder-BATs
param(
  [string]$RepoOwner   = "stefanG41",
  [string]$RepoName    = "scripts",
  [string]$Subfolder   = "robocopy",
  [string]$InstallPath = "D:\BackupScripts\robocopy",
  [string]$PromotePath = "D:\BackupScripts"
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

# Default-Branch ermitteln
$headers   = @{ 'User-Agent'='PowerShell'; 'Accept'='application/vnd.github+json' }
$apiRepo   = "https://api.github.com/repos/$RepoOwner/$RepoName"
$repoInfo  = Invoke-RestMethod -Uri $apiRepo -Headers $headers
$defaultBranch = $repoInfo.default_branch
Write-Host ("Default Branch: {0}" -f $defaultBranch)

# ZIP laden und entpacken
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

# Bestehenden Stand sichern, neuen kopieren
Backup-Existing -Path $InstallPath
Copy-Item -Path $srcPath -Destination $InstallPath -Recurse -Force
Remove-Item $zipPath -Force
Remove-Item $extDir -Recurse -Force
Write-Host ("Aktuelle Version kopiert nach: {0}" -f $InstallPath)

# Profil- und Bilder-BATs erkennen & hochkopieren
$patternsProfile  = @('*profile*.bat','*profil*.bat')
$patternsPictures = @('*picture*.bat','*bilder*.bat','*photos*.bat','*fotos*.bat')

$profile  = Get-ChildItem -Path $InstallPath -Recurse -Include $patternsProfile  -ErrorAction SilentlyContinue | Select-Object -First 1
$pictures = Get-ChildItem -Path $InstallPath -Recurse -Include $patternsPictures -ErrorAction SilentlyContinue | Select-Object -First 1

if ($profile) {
  Ensure-Dir $PromotePath
  Copy-Item -Path $profile.FullName -Destination (Join-Path $PromotePath (Split-Path $profile.FullName -Leaf)) -Force
  Write-Host ("Profil-Backup bereitgestellt: {0}" -f $profile.Name)
} else {
  Write-Warning "Kein Profil-Backup gefunden."
}

if ($pictures) {
  Ensure-Dir $PromotePath
  Copy-Item -Path $pictures.FullName -Destination (Join-Path $PromotePath (Split-Path $pictures.FullName -Leaf)) -Force
  Write-Host ("Bilder-Backup bereitgestellt: {0}" -f $pictures.Name)
} else {
  Write-Warning "Kein Bilder-Backup gefunden."
}

# kurze Versionsinfo
try {
  $apiCommit = "https://api.github.com/repos/$RepoOwner/$RepoName/commits/$defaultBranch"
  $c = Invoke-RestMethod -Uri $apiCommit -Headers $headers
  Write-Host ("Stand: {0} - {1}" -f $c.commit.author.date, $c.sha.Substring(0,7))
}
catch {
  Write-Warning ("Konnte Commit-Info nicht laden: {0}" -f $_.Exception.Message)
}

Write-Host ""
Write-Host ("Fertig. Falls vorhanden, liegen Profil- und Bilder-Backup-BATs jetzt in: {0}" -f $PromotePath)
