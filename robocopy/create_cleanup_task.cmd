@echo off
setlocal

:: Pfad zum Cleanup-Skript
set "SCRIPT=D:\BackupScripts\cleanup_robocopy_logs.cmd"
set "TASKNAME=Backup_Bilder_Cleanup_Logs"

if not exist "%SCRIPT%" (
  echo FEHLER: Cleanup-Skript nicht gefunden: %SCRIPT%
  echo Bitte die Datei an diesen Ort kopieren und erneut ausfuehren.
  exit /b 1
)

echo.
echo Erstelle geplante Aufgabe "%TASKNAME%":
echo  - TAEGLICH um 21:00
echo  - Fuehrt das Cleanup-Skript aus
echo.

:: Vorhandene Aufgabe entfernen, falls sie existiert
schtasks /Query /TN "%TASKNAME%" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Vorhandene Aufgabe gefunden. Loesche alte Version...
  schtasks /Delete /TN "%TASKNAME%" /F >nul
)

:: Aufgabe erstellen - taeglich 21:00, aktuellem Benutzer, hoechste Rechte
set "TR_CMD=cmd.exe /c \"\"%SCRIPT%\"\""

schtasks /Create ^
  /TN "%TASKNAME%" ^
  /SC DAILY ^
  /ST 21:00 ^
  /RL HIGHEST ^
  /RU "%USERNAME%" ^
  /TR "%TR_CMD%" ^
  /F

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo FEHLER: Aufgabe konnte nicht erstellt werden.
  echo Tipp: Dieses Skript mit Rechtsklick "Als Administrator ausfuehren".
  exit /b 1
)

echo.
echo Aufgabe "%TASKNAME%" wurde erstellt (taeglich 21:00).
echo Du kannst die Uhrzeit im Skript oder in der Aufgabenplanung anpassen.
echo.
pause
