@echo off
setlocal enabledelayedexpansion

:: === Einstellungen ===
set "SRC=D:\Bilder"
set "DST=E:\backup_bilder"
set "LOGDIR=D:\ROBOCOPY_LOG_FILES"

:: === Log-Ordner anlegen, falls nötig ===
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:: Zeitstempel für Logdatei (robust via PowerShell)
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "TS=%%I"
set "LOG=%LOGDIR%\robocopy_backup_%TS%.log"

:: === E:\ vorhanden? ===
if not exist "E:\" (
  color 0C
  echo.
  echo #########################################################
  echo # FEHLER: Externe Festplatte (E:\) nicht gefunden!      #
  echo #########################################################
  echo.
  echo Bitte anschliessen und erneut versuchen.
  pause
  exit /b 1
)

echo ============================================
echo   *** Backup Bilder Tool (Interaktiv) ***
echo ============================================
echo Quelle: %SRC%
echo Ziel:   %DST%
echo Log:    %LOG%
echo.
echo [1] Nur neue Dateien kopieren (Ergaenzung)
echo [2] Spiegeln (Achtung: loescht im Ziel!)
echo [3] Try Run (nur anzeigen, keine Dateien kopieren)
echo.
echo Wenn innerhalb von 10 Sekunden keine Auswahl erfolgt,
echo wird automatisch [1] ausgefuehrt.
echo.

:: Auswahl mit Timeout (Default = 1)
choice /C 123 /T 10 /D 1 /M "Bitte Auswahl treffen (1, 2 oder 3):"

if errorlevel 3 goto do_tryrun
if errorlevel 2 goto do_mirror
if errorlevel 1 goto do_add

:do_add
echo *** Starte Ergaenzungs-Backup... ***
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /LOG:"%LOG%"
set "RC=%ERRORLEVEL%"
call :parse_summary
goto check_rc

:do_mirror
echo *** Starte Spiegel-Backup (Achtung: Loescht im Ziel!) ***
robocopy "%SRC%" "%DST%" /MIR /R:1 /W:1 /LOG:"%LOG%"
set "RC=%ERRORLEVEL%"
call :parse_summary
goto check_rc

:do_tryrun
echo *** Starte Try Run (Trockenlauf, keine Dateien werden veraendert) ***
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /L /LOG:"%LOG%"
set "RC=%ERRORLEVEL%"
call :parse_summary
goto check_rc

:parse_summary
:: ==== Zusammenfassung aus dem Log ermitteln ====
set "FilesTotal=" & set "FilesCopied=" & set "FilesSkipped=" & set "FilesExtras="
set "DirsTotal="  & set "DirsCopied="  & set "DirsSkipped="  & set "DirsExtras="

:: "Files :" -> Total Copied Skipped Mismatch Failed Extras
for /f "tokens=3-8" %%a in ('findstr /B /C:"Files :" "%LOG%"') do (
  set "FilesTotal=%%a"
  set "FilesCopied=%%b"
  set "FilesSkipped=%%c"
  set "FilesMismatch=%%d"
  set "FilesFailed=%%e"
  set "FilesExtras=%%f"
)

:: "Dirs :" -> Total Copied Skipped Mismatch Failed Extras
for /f "tokens=3-8" %%a in ('findstr /B /C:"Dirs :" "%LOG%"') do (
  set "DirsTotal=%%a"
  set "DirsCopied=%%b"
  set "DirsSkipped=%%c"
  set "DirsMismatch=%%d"
  set "DirsFailed=%%e"
  set "DirsExtras=%%f"
)

echo.
echo ===== Zusammenfassung =====
echo Kopiert:   Dateien: !FilesCopied!   Ordner: !DirsCopied!
echo Ueberspr.: Dateien: !FilesSkipped!  Ordner: !DirsSkipped!
echo Extras:    Dateien: !FilesExtras!   Ordner: !DirsExtras!
echo Gesamt:    Dateien: !FilesTotal!    Ordner: !DirsTotal!
echo ===========================
echo.
exit /b 0

:check_rc
if %RC% LEQ 3 (
  color 0A
  echo Vorgang erfolgreich (Robocopy-Code %RC%).
) else (
  color 0C
  echo Fehler aufgetreten (Robocopy-Code %RC%). Details im Log.
)
echo Log gespeichert: %LOG%
echo.
pause
exit /b %RC%
