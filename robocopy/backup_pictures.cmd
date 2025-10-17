@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ===== Einstellungen =====
set "DESTROOT=D:\Backup_Profil"
set "LOGDIR=D:\ROBOCOPY_LOG_FILES\PICTURES"
set "ROBO_OPTS=/E /XC /XN /XO /R:1 /W:1 /XJ /TEE"
:: Optional: /MT:8

:: ===== Prüfungen =====
if not exist "D:\" (
  echo [ERROR] Laufwerk D:\ nicht erreichbar. Abbruch.
  exit /b 1
)
if not exist "%DESTROOT%" mkdir "%DESTROOT%"
if not exist "%LOGDIR%"   mkdir "%LOGDIR%"

:: ===== Timestamp & Wochentag =====
for /f "tokens=2 delims==." %%a in ('wmic os get LocalDateTime /value') do set "ldt=%%a"
set "YYYY=%ldt:~0,4%" & set "MM=%ldt:~4,2%" & set "DD=%ldt:~6,2%"
set "hh=%ldt:~8,2%"   & set "nn=%ldt:~10,2%"
set "TS=%YYYY%-%MM%-%DD%_%hh%-%nn%"

for /f "tokens=2 delims==" %%a in ('wmic path win32_localtime get dayofweek /value') do set "DOW=%%a"
if "%DOW%"=="0" (set "DW=d7") else set "DW=d%DOW%"
set "DEST=%DESTROOT%\%DW%"
if not exist "%DEST%" mkdir "%DEST%"
set "LOG=%LOGDIR%\pictures_backup_%DW%_%TS%.log"

:: ===== Pictures-Pfad finden (User Shell Folders + OneDrive Fallbacks) =====
set "Pictures=" & set "Pictures_RAW="
call :get_user_shell "My Pictures" Pictures
if not defined Pictures (
  for /d %%D in ("%USERPROFILE%\OneDrive*") do (
    if exist "%%~fD\Bilder"   set "Pictures=%%~fD\Bilder"
    if not defined Pictures if exist "%%~fD\Pictures" set "Pictures=%%~fD\Pictures"
  )
)
if not defined Pictures if exist "%USERPROFILE%\Pictures" set "Pictures=%USERPROFILE%\Pictures"

:: ===== Debug =====
echo ============================================
echo   BILDER-BACKUP (SAFE, additiv)
echo ============================================
echo USERPROFILE:   %USERPROFILE%
echo Wochentag:     %DW%   (DOW=%DOW%)
echo Ziel (Tag):    %DEST%
echo Logfile:       %LOG%
echo.
echo Pictures = "!Pictures_RAW!"  ^>  "!Pictures!"
echo Optionen: %ROBO_OPTS%
echo ============================================
echo.

:: ===== Lauf =====
set "SRC=%Pictures%"
set "SRC=!SRC:"=!"
for /f "tokens=1 delims=>(" %%X in ("!SRC!") do set "SRC=%%~X"

if not defined SRC (
  echo [WARN] Pictures: Keine Quelle ermittelt. Ende.
  exit /b 0
)
if not exist "!SRC!" (
  echo [WARN] Pictures: Quelle existiert nicht: "!SRC!". Ende.
  exit /b 0
)

set "HASFILES="
for /f "delims=" %%x in ('dir /b /a "!SRC!" 2^>nul') do (set "HASFILES=1" & goto :after_list)
:after_list
if not defined HASFILES (
  echo [WARN] Pictures: Quelle wirkt leer. Ende.
  exit /b 0
)

echo --- Sichere Pictures ---
echo Quelle: "!SRC!"
echo Ziel:   "%DEST%\Pictures"
robocopy "!SRC!" "%DEST%\Pictures" %ROBO_OPTS% /LOG+:"%LOG%"
echo Fertig. Details: %LOG%
exit /b 0

:get_user_shell
set "VALNAME=%~1"
set "OUTVAR=%~2"
set "RAW=" & set "RES="
for /f "skip=2 tokens=2,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "%VALNAME%" 2^>nul') do set "RAW=%%b"
if defined RAW (
  call set "RES=%%RAW%%"
  set "%OUTVAR%=%RES%"
  set "%OUTVAR%_RAW=%RAW%"
)
exit /b 0
