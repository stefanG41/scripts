@echo off
setlocal

:: Pfad zum Hybrid-Skript (v5 ohne CALLs)
set "SCRIPT=D:\BackupScripts\backup_bilder_hybrid_v5_no_calls.bat"
set "TASKNAME=Backup_Bilder_Auto"

if not exist "%SCRIPT%" (
  echo FEHLER: Skript nicht gefunden: %SCRIPT%
  echo Bitte die Datei an diesen Ort kopieren und erneut ausfuehren.
  exit /b 1
)

echo.
echo (1) Erstelle sichtbare, interaktive Aufgabe fuer den aktuellen Benutzer.
echo     - Start beim Systemstart
echo     - 1 Minute Verzoegerung nach dem Boot
echo     - Popups sind sichtbar (wenn Benutzer angemeldet ist)
echo.

:: Alte Aufgabe entfernen, falls vorhanden
schtasks /Query /TN "%TASKNAME%" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Vorhandene Aufgabe "%TASKNAME%" gefunden. Loesche alte Version...
  schtasks /Delete /TN "%TASKNAME%" /F >nul
)

:: Aufgabe erstellen (sichtbar/interaktiv fuer aktuellen Benutzer)
:: Hinweis: /DELAY funktioniert bei ONSTART ab Windows 8/10; Format HH:MM
set "TR_CMD=cmd.exe /c \"\"%SCRIPT%\"\""

schtasks /Create ^
  /TN "%TASKNAME%" ^
  /SC ONSTART ^
  /DELAY 0001:00 ^
  /RL HIGHEST ^
  /RU "%USERNAME%" ^
  /IT ^
  /TR "%TR_CMD%" ^
  /F

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo FEHLER: Aufgabe konnte nicht erstellt werden.
  echo Tipp: Dieses Skript mit Rechtsklick "Als Administrator ausfuehren".
  exit /b 1
)

echo.
echo Aufgabe "%TASKNAME%" wurde erstellt.
echo Sie startet beim Systemboot (verzoegert um 1 Minute) und zeigt Popups an.
echo.
pause

:: ===== OPTIONAL: Leise/SYSTEM-Variante anlegen (auskommentiert) =====
:: Zum Erstellen einer lautlosen SYSTEM-Aufgabe (ohne Popups) die folgenden Zeilen entkommentieren:
::
:: set "TASKNAME_SILENT=Backup_Bilder_Auto_Silent"
:: schtasks /Query /TN "%TASKNAME_SILENT%" >nul 2>&1
:: if %ERRORLEVEL%==0 schtasks /Delete /TN "%TASKNAME_SILENT%" /F >nul
:: schtasks /Create ^
::   /TN "%TASKNAME_SILENT%" ^
::   /SC ONSTART ^
::   /DELAY 0001:00 ^
::   /RL HIGHEST ^
::   /RU "SYSTEM" ^
::   /TR "%TR_CMD%" ^
::   /F
:: echo Lautlose SYSTEM-Aufgabe "%TASKNAME_SILENT%" wurde erstellt.
