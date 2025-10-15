@echo off
setlocal enabledelayedexpansion

:: === Einstellungen ===
set "SRC=D:\Bilder"
set "DST=E:\backup_bilder"
set "LOGDIR=D:\ROBOCOPY_LOG_FILES"
set "FLAGFILE=%LOGDIR%\last_run_date.txt"

:: === Log-Ordner anlegen, falls nötig ===
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:: === Heutiges Datum (YYYY-MM-DD) robust via PowerShell ===
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%I"
:: Zeitstempel für Logdatei
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "TS=%%I"
set "LOG=%LOGDIR%\robocopy_backup_%TS%.log"

:: === 1× pro Tag: wurde heute schon gelaufen? ===
if exist "%FLAGFILE%" (
  set /p LASTRUN=<"%FLAGFILE%"
  if /i "%LASTRUN%"=="%TODAY%" (
    echo [%TS%] Bereits heute ausgefuehrt. Beende.
    exit /b 0
  )
)

:: === E:\ vorhanden? ===
if not exist "E:\" (
  echo [%TS%] FEHLER: Externe Festplatte E:\ nicht gefunden. Beende.>>"%LOG%"
  exit /b 1
)

:: === Backup (nur Ergänzungen) ===
echo *** Starte Ergaenzungs-Backup am %TS% ***>>"%LOG%"
robocopy "%SRC%" "%DST%" /E /XC /XN /XO /R:1 /W:1 /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"

:: === Robocopy-Exitcode bewerten (<=3 = OK) ===
if %RC% LEQ 3 (
  echo [%TS%] OK (Robocopy-Code %RC%).>>"%LOG%"
  >"%FLAGFILE%" echo %TODAY%
  exit /b 0
) else (
  echo [%TS%] FEHLER (Robocopy-Code %RC%).>>"%LOG%"
  exit /b %RC%
)
