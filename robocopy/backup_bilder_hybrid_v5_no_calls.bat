@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ================== EINSTELLUNGEN ==================
set "SRC=D:\Bilder"
set "DST=E:\backup_bilder"
set "LOGDIR=D:\ROBOCOPY_LOG_FILES"
set "FLAGFILE=%LOGDIR%\last_run_date.txt"
set "DEBUG=0"

:: ================== START ==================
:: Ermitteln, ob manueller Modus gewünscht ist
if /i "%~1"=="manual" goto MENU

:: ================== AUTO-MODUS ==================
:AUTO
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%I"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "TS=%%I"
if not defined TODAY set "TODAY=%date%"
if not defined TS set "TS=%date%_%time%"
set "TS=%TS::=-%"
set "TS=%TS: =0%"
set "LOG=%LOGDIR%\robocopy_backup_%TS%.log"

echo.
echo === Robocopy Auto-Backup startet: %TS% ===
echo Quelle: "%SRC%"
echo Ziel:   "%DST%"
echo Log:    "%LOG%"
echo TODAY:  %TODAY%
echo.

if exist "%FLAGFILE%" (
  set /p LASTRUN=<"%FLAGFILE%"
  echo LASTRUN: !LASTRUN!
  if /i "!LASTRUN!"=="%TODAY%" (
    echo Bereits heute ausgefuehrt. Beende jetzt.
    echo [%TS%] Bereits heute ausgefuehrt.>>"%LOG%"
    set "RC=0"
    goto END_OK
  )
)

:: === Warte bis zu 120s auf E:\  (mit Popup) ===
set "MAXWAIT=120"
set "COUNT=0"
if not exist "E:\" (
  powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $ws.Popup('Backup startet. Bitte HDD E: einschalten/verbinden. Es wird bis zu 2 Minuten gewartet...',5,'Bilder-Backup',64)" >nul 2>&1
)

:WAITLOOP_AUTO
if exist "E:\" goto DRIVE_READY_AUTO
set /a COUNT+=1
if %COUNT% GEQ %MAXWAIT% (
  echo Zeitueberschreitung: E:\ nicht gefunden.
  powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $ws.Popup('FEHLER: Keine HDD E: gefunden. Kein Backup durchgefuehrt!',10,'Bilder-Backup',16)" >nul 2>&1
  set "RC=1"
  goto END_ERR
)
timeout /t 1 /nobreak >nul
goto WAITLOOP_AUTO

:DRIVE_READY_AUTO
echo E:\ erkannt.
echo Starte Ergaenzungs-Backup...
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /TEE /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"

if %RC% LEQ 3 (
  echo [%TS%] OK. Robocopy-Code %RC%.>>"%LOG%"
  >"%FLAGFILE%" echo %TODAY%
  goto END_OK
) else (
  echo [%TS%] FEHLER. Robocopy-Code %RC%.>>"%LOG%"
  goto END_ERR
)

:: ================== INTERAKTIV ==================
:MENU
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%I"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "TS=%%I"
if not defined TODAY set "TODAY=%date%"
if not defined TS set "TS=%date%_%time%"
set "TS=%TS::=-%"
set "TS=%TS: =0%"
set "LOG=%LOGDIR%\robocopy_backup_%TS%.log"

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
echo Wenn innerhalb von 10 Sekunden keine Auswahl erfolgt,
echo wird automatisch [1] ausgefuehrt.
echo.

:: === Warte bis zu 120s auf E:\  (mit Popup) ===
set "MAXWAIT=120"
set "COUNT=0"
if not exist "E:\" (
  powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $ws.Popup('Bitte HDD E: einschalten/verbinden. Es wird bis zu 2 Minuten gewartet...',5,'Bilder-Backup',64)" >nul 2>&1
)
:WAITLOOP_MAN
if exist "E:\" goto DRIVE_READY_MAN
set /a COUNT+=1
if %COUNT% GEQ %MAXWAIT% (
  echo Zeitueberschreitung: E:\ nicht gefunden.
  powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $ws.Popup('FEHLER: Keine HDD E: gefunden. Kein Backup durchgefuehrt!',10,'Bilder-Backup',16)" >nul 2>&1
  set "RC=1"
  goto END_ERR
)
timeout /t 1 /nobreak >nul
goto WAITLOOP_MAN

:DRIVE_READY_MAN
echo E:\ erkannt.

choice /C 123 /T 10 /D 1 /M "Bitte Auswahl treffen (1, 2 oder 3):"
if errorlevel 3 goto DO_TRY
if errorlevel 2 goto DO_MIR
if errorlevel 1 goto DO_ADD

:DO_ADD
echo Starte Ergaenzungs-Backup...
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /TEE /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
goto SUMMARY_COMMON

:DO_MIR
echo Starte Spiegel-Backup. Achtung: Dateien im Ziel koennen geloescht werden.
robocopy "%SRC%" "%DST%" /MIR /R:1 /W:1 /TEE /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
goto SUMMARY_COMMON

:DO_TRY
echo Starte Try Run (Trockenlauf). Es werden keine Dateien veraendert.
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /L /TEE /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
goto SUMMARY_TRY

:SUMMARY_COMMON
:: Reset Variablen
set "FilesTotal=" & set "FilesCopied=" & set "FilesSkipped=" & set "FilesExtras="
set "DirsTotal="  & set "DirsCopied="  & set "DirsSkipped="  & set "DirsExtras="

:: Englisch
for /f "tokens=3-8" %%a in ('findstr /B /C:"Files :" "%LOG%"') do (
  set "FilesTotal=%%a"
  set "FilesCopied=%%b"
  set "FilesSkipped=%%c"
  set "FilesMismatch=%%d"
  set "FilesFailed=%%e"
  set "FilesExtras=%%f"
)
for /f "tokens=3-8" %%a in ('findstr /B /C:"Dirs :" "%LOG%"') do (
  set "DirsTotal=%%a"
  set "DirsCopied=%%b"
  set "DirsSkipped=%%c"
  set "DirsMismatch=%%d"
  set "DirsFailed=%%e"
  set "DirsExtras=%%f"
)

:: Deutsch (Fallback)
if not defined FilesTotal (
  for /f "tokens=2-7" %%a in ('findstr /R /C:"^[ ]*Dateien:" "%LOG%"') do (
    set "FilesTotal=%%a"
    set "FilesCopied=%%b"
    set "FilesSkipped=%%c"
    set "FilesMismatch=%%d"
    set "FilesFailed=%%e"
    set "FilesExtras=%%f"
  )
)
if not defined DirsTotal (
  for /f "tokens=2-7" %%a in ('findstr /R /C:"^[ ]*Verzeich\.\:" "%LOG%"') do (
    set "DirsTotal=%%a"
    set "DirsCopied=%%b"
    set "DirsSkipped=%%c"
    set "DirsMismatch=%%d"
    set "DirsFailed=%%e"
    set "DirsExtras=%%f"
  )
)

echo.
echo ===== Zusammenfassung =====
echo Kopiert:   Dateien: !FilesCopied!   Ordner: !DirsCopied!
echo Ueberspr.: Dateien: !FilesSkipped!  Ordner: !DirsSkipped!
echo Extras:    Dateien: !FilesExtras!   Ordner: !DirsExtras!
echo Gesamt:    Dateien: !FilesTotal!    Ordner: !DirsTotal!
echo ===========================
echo.
goto AFTER_RUN

:SUMMARY_TRY
:: Reset Variablen
set "FilesTotal=" & set "FilesCopied=" & set "FilesSkipped=" & set "FilesExtras="
set "DirsTotal="  & set "DirsCopied="  & set "DirsSkipped="  & set "DirsExtras="

:: Englisch
for /f "tokens=3-8" %%a in ('findstr /B /C:"Files :" "%LOG%"') do (
  set "FilesTotal=%%a"
  set "FilesCopied=%%b"
  set "FilesSkipped=%%c"
  set "FilesMismatch=%%d"
  set "FilesFailed=%%e"
  set "FilesExtras=%%f"
)
for /f "tokens=3-8" %%a in ('findstr /B /C:"Dirs :" "%LOG%"') do (
  set "DirsTotal=%%a"
  set "DirsCopied=%%b"
  set "DirsSkipped=%%c"
  set "DirsMismatch=%%d"
  set "DirsFailed=%%e"
  set "DirsExtras=%%f"
)

:: Deutsch (Fallback)
if not defined FilesTotal (
  for /f "tokens=2-7" %%a in ('findstr /R /C:"^[ ]*Dateien:" "%LOG%"') do (
    set "FilesTotal=%%a"
    set "FilesCopied=%%b"
    set "FilesSkipped=%%c"
    set "FilesMismatch=%%d"
    set "FilesFailed=%%e"
    set "FilesExtras=%%f"
  )
)
if not defined DirsTotal (
  for /f "tokens=2-7" %%a in ('findstr /R /C:"^[ ]*Verzeich\.\:" "%LOG%"') do (
    set "DirsTotal=%%a"
    set "DirsCopied=%%b"
    set "DirsSkipped=%%c"
    set "DirsMismatch=%%d"
    set "DirsFailed=%%e"
    set "DirsExtras=%%f"
  )
)

echo.
echo ===== Zusammenfassung (Try Run) =====
echo Wuerde kopieren: Dateien: !FilesCopied!   Ordner: !DirsCopied!
echo Wuerde ueberspr.: Dateien: !FilesSkipped!  Ordner: !DirsSkipped!
echo Extras erkannt:   Dateien: !FilesExtras!   Ordner: !DirsExtras!
echo Gesamt gescannt:  Dateien: !FilesTotal!    Ordner: !DirsTotal!
echo =====================================
echo.
goto AFTER_RUN

:AFTER_RUN
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

:END_OK
echo.
echo Fertig. Erfolgscode (0..3). RC=%RC%
if "%DEBUG%"=="1" pause
exit /b 0

:END_ERR
echo.
echo FEHLER. RC=%RC%  (Details ggf. im Log: "%LOG%")
if "%DEBUG%"=="1" pause
exit /b %RC%
