@echo off
setlocal

:: Name des geplanten Tasks
set "TASKNAME=ProfileBackup"

:: Pfad zu deinem Profil-Backup-Skript
set "SCRIPTPATH=D:\BackupScripts\backup_profile_weekly_SAFE_v5_with_pictures.bat"

:: Task löschen, falls er schon existiert
schtasks /query /tn "%TASKNAME%" >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] Bestehender Task gefunden. Entferne alten Task...
    schtasks /delete /tn "%TASKNAME%" /f >nul
)

:: Task erstellen – nur beim Systemstart, einmal täglich
schtasks /create ^
  /tn "%TASKNAME%" ^
  /tr "\"%SCRIPTPATH%\"" ^
  /sc onstart ^
  /ru "SYSTEM" ^
  /rl highest ^
  /f

if %errorlevel%==0 (
    echo [OK] Task "%TASKNAME%" wurde erfolgreich erstellt.
) else (
    echo [FEHLER] Task konnte nicht erstellt werden.
)
pause
