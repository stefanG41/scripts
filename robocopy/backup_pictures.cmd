@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ================== EINSTELLUNGEN ==================
set "SRC=D:\Bilder"
set "DST=E:\backup_bilder"
set "LOGDIR=D:\ROBOCOPY_LOG_FILES\PICTURES"
set "FLAGFILE=%LOGDIR%\last_run_date.txt"
set "DEBUG=0"

:: ================== MODUSWAHL ==================
if /i "%~1"=="/auto" (
  goto AUTO
) else (
  goto MENU
)

:: ===================================================
:: ==============   GEMEINSAME FUNKTIONEN  ===========
:: ===================================================
:SET_TIMESTAMP
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%I"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "TS=%%I"
if not defined TODAY set "TODAY=%date%"
if not defined TS set "TS=%date%_%time%"
set "TS=%TS::=-%"
set "TS=%TS: =0%"
set "LOG=%LOGDIR%\robocopy_backup_%TS%.log"
exit /b 0

:ERROR_POPUP
:: Übergabe: %~1 = Meldungstext in einfachen Quotes:  'Text...'
powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $ws.Popup(%~1,10,'Bilder-Backup',16)" >nul 2>&1
exit /b 0

:CHECK_DEST
:: Prüft Laufwerk E:\ und Ordner E:\backup_bilder
set "DRIVE=%DST:~0,2%"
if not exist "%DRIVE%\" (
  echo [FEHLER] Laufwerk %DRIVE% nicht gefunden!
  call :ERROR_POPUP " 'FEHLER: Kein Laufwerk %DRIVE% erkannt. Bitte externe Festplatte anschließen!' "
  exit /b 1
)
if not exist "%DST%" (
  echo [FEHLER] Zielordner "%DST%" nicht gefunden!
  call :ERROR_POPUP " 'FEHLER: Der Ordner ""%DST%"" existiert nicht. Bitte richtige HDD anschließen!' "
  exit /b 1
)

:: Optionaler Schreibtest (aktivieren: 'rem' entfernen)
:: >"%DST%\.__write_test__" echo OK >nul 2>&1
:: if errorlevel 1 (
::   echo [FEHLER] Keine Schreibrechte in "%DST%".
::   call :ERROR_POPUP " 'FEHLER: Keine Schreibrechte in ""%DST%"".' "
::   exit /b 1
:: ) else (
::   del /q "%DST%\.__write_test__" >nul 2>&1
:: )

exit /b 0

:: ===================================================
:: ================== AUTO-MODUS =====================
:: ===================================================
:AUTO
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
call :SET_TIMESTAMP

echo.
echo === Robocopy Auto-Backup startet: %TS% ===
echo Quelle: "%SRC%"
echo Ziel:   "%DST%"
echo Log:    "%LOG%"
echo TODAY:  %TODAY%
echo.

:: Nur 1x pro Tag ausführen
if exist "%FLAGFILE%" (
  set /p LASTRUN=<"%FLAGFILE%"
  if /i "!LASTRUN!"=="%TODAY%" (
    echo Bereits heute ausgefuehrt. Beende jetzt.
    echo [%TS%] Bereits heute ausgefuehrt.>>"%LOG%"
    set "RC=0"
    goto END_OK
  )
)

:: Ziel strikt prüfen (Laufwerk + Ordner) → bei Fehler sofort abbrechen
call :CHECK_DEST
if errorlevel 1 (
  set "RC=1"
  goto END_ERR
)

:: Ergänzungs-Backup (Option 1)
echo Starte Ergaenzungs-Backup...
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /XJ /TEE /MT:16 /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"

if %RC% LEQ 3 (
  echo [%TS%] OK. Robocopy-Code %RC%.>>"%LOG%"
  >"%FLAGFILE%" echo %TODAY%
  goto END_OK
) else (
  echo [%TS%] FEHLER. Robocopy-Code %RC%.>>"%LOG%"
  goto END_ERR
)

:: ===================================================
:: ==============   INTERAKTIVER MODUS  ==============
:: ===================================================
:MENU
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
call :SET_TIMESTAMP

echo ============================================
echo   *** Backup Bilder Tool (Interaktiv) ***
echo ============================================
echo Quelle: %SRC%
echo Ziel:   %DST%
echo Log:    %LOG%
echo.
echo [1] Nur neue Dateien kopieren (Ergaenzung)
echo [2] Spiegeln (loescht ggf. im Ziel)
echo [3] Try Run (nur anzeigen, kein Kopieren)
echo.
choice /C 123 /T 10 /D 1 /M "Bitte Auswahl treffen (1, 2 oder 3):"

if errorlevel 3 goto DO_TRY
if errorlevel 2 goto DO_MIR
if errorlevel 1 goto DO_ADD

:DO_ADD
call :CHECK_DEST
if errorlevel 1 (
  set "RC=1"
  goto END_ERR
)
echo Starte Ergaenzungs-Backup...
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /XJ /TEE /MT:16 /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
goto SUMMARY

:DO_MIR
call :CHECK_DEST
if errorlevel 1 (
  set "RC=1"
  goto END_ERR
)
echo Starte Spiegel-Backup. Achtung: Dateien im Ziel koennen geloescht werden.
robocopy "%SRC%" "%DST%" /MIR /R:1 /W:1 /XJ /TEE /MT:16 /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
goto SUMMARY

:DO_TRY
call :CHECK_DEST
if errorlevel 1 (
  set "RC=1"
  goto END_ERR
)
echo Starte Try Run (Trockenlauf). Es werden keine Dateien veraendert.
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /L /R:1 /W:1 /XJ /TEE /MT:16 /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
goto SUMMARY

:SUMMARY
echo.
if %RC% LEQ 3 (
  color 0A
  echo Vorgang erfolgreich. RC=%RC%
) else (
  color 0C
  echo Fehler aufgetreten. RC=%RC%
)
echo Log gespeichert: %LOG%
echo.
if "%DEBUG%"=="1" pause
exit /b %RC%

:: ===================================================
:: ===================== ENDE ========================
:: ===================================================
:END_OK
echo Fertig. Erfolgscode (0..3). RC=%RC%
if "%DEBUG%"=="1" pause
exit /b 0

:END_ERR
echo FEHLER. RC=%RC% (Details ggf. im Log: "%LOG%")
if "%DEBUG%"=="1" pause
exit /b %RC%
