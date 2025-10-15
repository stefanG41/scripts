@echo off
setlocal

:: Pfad, wo die Auto-Batch liegen soll
set "SCRIPT_DIR=D:\BackupScripts"
set "SCRIPT=%SCRIPT_DIR%\backup_bilder_auto.bat"

:: Ordner anlegen, falls nicht vorhanden
if not exist "%SCRIPT_DIR%" mkdir "%SCRIPT_DIR%"

echo.
echo === Hinweis ===
echo Lege die Datei "backup_bilder_auto.bat" nach %SCRIPT_DIR%
echo und fuehre dann dieses Skript erneut aus, falls sie noch nicht dort liegt.
echo.

:: Task ggf. vorher loeschen
schtasks /Query /TN "Backup_Bilder_Auto" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Vorhandene Aufgabe gefunden. Loesche alte Version...
  schtasks /Delete /TN "Backup_Bilder_Auto" /F >nul
)

:: Task erstellen:
:: - ONSTART  = beim Systemstart ausfuehren
:: - RU       = aktueller Benutzer (sichtbar unter %USERNAME%)
:: - RL       = hoechste Rechte
:: - TR       = cmd.exe /c "D:\BackupScripts\backup_bilder_auto.bat"
set "TR_CMD=cmd.exe /c \"\"%SCRIPT%\"\""

schtasks /Create ^
  /TN "Backup_Bilder_Auto" ^
  /SC ONSTART ^
  /RU "%USERNAME%" ^
  /RL HIGHEST ^
  /TR "%TR_CMD%" ^
  /F

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo FEHLER: Die Aufgabe konnte nicht erstellt werden.
  echo Starte dieses Skript ggf. mit Rechtsklick "Als Administrator ausfuehren".
  exit /b 1
)

echo.
echo Aufgabe "Backup_Bilder_Auto" wurde erstellt.
echo Sie laeuft beim Systemstart automatisch (max. 1x pro Tag dank Datum-Check).
echo.
pause
