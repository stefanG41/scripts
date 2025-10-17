@echo off
setlocal
set "TASKNAME=ProfileBackup"
set "SCRIPTPATH=D:\BackupScripts\backup_profile.cmd"

schtasks /query /tn "%TASKNAME%" >nul 2>&1 && (
  echo [INFO] Entferne bestehenden Task "%TASKNAME%"...
  schtasks /delete /tn "%TASKNAME%" /f >nul
)

schtasks /create ^
  /tn "%TASKNAME%" ^
  /sc onstart ^
  /delay 0001:00 ^
  /tr "\"%SCRIPTPATH%\"" ^
  /ru "SYSTEM" ^
  /rl highest ^
  /f

if %errorlevel%==0 (echo [OK] Task "%TASKNAME%" erstellt.) else (echo [FEHLER] Konnte Task nicht erstellen.)
pause
