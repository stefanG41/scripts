@echo off
setlocal
REM downloade.cmd - holt den neuesten Stand aus github.com/stefanG41/scripts/robocopy
REM Zielordner: D:\BackupScripts\robocopy  |  Promoted BATs nach: D:\BackupScripts

set "REPO_OWNER=stefanG41"
set "REPO_NAME=scripts"
set "SUBFOLDER=robocopy"
set "INSTALL_PATH=D:\BackupScripts\robocopy"
set "PROMOTE_PATH=D:\BackupScripts"

REM Optional: feste BAT-Dateinamen setzen (sonst Auto-Erkennung):
REM set "PROFILE_BAT=backup_profile_weekly_SAFE_v3_exclude_pictures.bat"
REM set "PICTURES_BAT=backup_pictures_weekly_SAFE_v1.bat"

set "PS1=%TEMP%\Get-Latest-RobocopyScripts_%RANDOM%.ps1"

REM PowerShell-Skript in eine temporäre Datei schreiben:
> "%PS1%" (
  echo $ErrorActionPreference = 'Stop'
  echo param(^
  echo   [string]$RepoOwner   = '%REPO_OWNER%',^
  echo   [string]$RepoName    = '%REPO_NAME%',^
  echo   [string]$Subfolder   = '%SUBFOLDER%',^
  echo   [string]$InstallPath = '%INSTALL_PATH%',^
  echo   [string]$PromotePath = '%PROMOTE_PATH%',^
  echo   [string]$ProfileBatName = '%PROFILE_BAT%',^
  echo   [string]$PicturesBatName = '%PICTURES_BAT%'^
  echo ^)
  echo function Ensure-Dir { param($p) if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p ^| Out-Null } }
  echo function Backup-Existing { param($Path) if (Test-Path $Path) { $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'; Move-Item $Path "$Path.bak_$stamp" } }
  echo function Get-DefaultBranch(^$o,^$r^) { ^
  echo   ^$h=@{ 'User-Agent'='PowerShell'; 'Accept'='application/vnd.github+json' }; ^
  echo   (Invoke-RestMethod -Uri "https://api.github.com/repos/^$o/^$r" -Headers ^$h).default_branch ^
  echo }
  echo function Promote-Bat { param([string]^$SourceBat,[string]^$TargetDir) Ensure-Dir ^$TargetDir; ^
  echo   ^$dest = Join-Path ^$TargetDir (Split-Path ^$SourceBat -Leaf); Copy-Item ^$SourceBat ^$dest -Force; ^$dest }
  echo function Find-Bat { param([string]^$Base,[string[]]^$Patterns) ^
  echo   ^$r=@(); foreach(^$p in ^$Patterns){ ^$r += Get-ChildItem -Path ^$Base -Filter ^$p -Recurse -ErrorAction SilentlyContinue }
  echo   ^$r ^| Sort-Object Name ^| Select-Object -Unique
  echo }
  echo Ensure-Dir (Split-Path ^$InstallPath -Parent)
  echo ^$branch = Get-DefaultBranch -o ^$RepoOwner -r ^$RepoName
  echo ^$zipUrl  = "https://api.github.com/repos/^$RepoOwner/^$RepoName/zipball/^$branch"
  echo ^$zipPath = Join-Path ^$env:TEMP ("robocopy_" + [Guid]::NewGuid() + ".zip")
  echo ^$extDir  = Join-Path ^$env:TEMP ("robocopy_" + [Guid]::NewGuid())
  echo Invoke-WebRequest -Uri ^$zipUrl -OutFile ^$zipPath -Headers @{ 'User-Agent'='PowerShell' ; 'Accept'='application/vnd.github+json' }
  echo Expand-Archive -Path ^$zipPath -DestinationPath ^$extDir -Force
  echo ^$root = Get-ChildItem -Directory ^$extDir ^| Select-Object -First 1
  echo if (-not ^$root) { throw 'ZIP-Struktur unerwartet' }
  echo ^$srcPath = Join-Path ^$root.FullName ^$Subfolder
  echo if (-not (Test-Path ^$srcPath)) { throw "Unterordner '^$Subfolder' nicht im ZIP gefunden." }
  echo Backup-Existing -Path ^$InstallPath
  echo Copy-Item -Path ^$srcPath -Destination ^$InstallPath -Recurse
  echo Remove-Item ^$zipPath -Force; Remove-Item ^$extDir -Recurse -Force
  echo Write-Host "Neuester Stand nach: ^$InstallPath"
  echo ^# Profil- und Bilder-BATs nach oben kopieren:
  echo ^$profileBat=$null; ^$picturesBat=$null
  echo if (^$ProfileBatName) { ^$profileBat = Get-ChildItem ^$InstallPath -Filter ^$ProfileBatName -Recurse -ErrorAction SilentlyContinue ^| Select-Object -First 1 }
  echo if (^$PicturesBatName){ ^$picturesBat = Get-ChildItem ^$InstallPath -Filter ^$PicturesBatName -Recurse -ErrorAction SilentlyContinue ^| Select-Object -First 1 }
  echo if (-not ^$profileBat)  { ^$profileBat  = Find-Bat -Base ^$InstallPath -Patterns @(^"*profile*^.bat^",^"*profil*^.bat^") ^| Select-Object -First 1 }
  echo if (-not ^$picturesBat) { ^$picturesBat = Find-Bat -Base ^$InstallPath -Patterns @(^"*picture*^.bat^",^"*bilder*^.bat^",^"*photos*^.bat^",^"*fotos*^.bat^") ^| Select-Object -First 1 }
  echo if (^$profileBat)  { ^$p = Promote-Bat -SourceBat ^$profileBat.FullName -TargetDir ^$PromotePath;  Write-Host "Profil-Backup bereit: ^$p" } else { Write-Warning "Keine Profil-Backup .bat gefunden." }
  echo if (^$picturesBat) { ^$p = Promote-Bat -SourceBat ^$picturesBat.FullName -TargetDir ^$PromotePath; Write-Host "Bilder-Backup bereit: ^$p" } else { Write-Warning "Keine Bilder-Backup .bat gefunden." }
  echo try { ^
  echo   ^$c = Invoke-RestMethod -Uri "https://api.github.com/repos/^$RepoOwner/^$RepoName/commits/^$branch" -Headers @{ 'User-Agent'='PowerShell'; 'Accept'='application/vnd.github+json' }; ^
  echo   Write-Host ("Stand: {0} – {1}" -f (^$c.commit.author.date), ^$c.sha.Substring(0,7)) ^
  echo } catch { }
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "ERR=%ERRORLEVEL%"
del "%PS1%" >nul 2>&1
if not "%ERR%"=="0" (
  echo Es ist ein Fehler aufgetreten. Fehlercode %ERR%.
  pause
  exit /b %ERR%
)

echo.
echo Fertig. Die Skripte liegen unter: %INSTALL_PATH%
echo Die Haupt-BATs (Profil/Bilder) wurden nach: %PROMOTE_PATH% kopiert, falls gefunden.
echo.
pause
endlocal
