@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ================== EINSTELLUNGEN ==================
set "DESTROOT=D:\Backup_Profil"
set "LOGDIR=D:\ROBOCOPY_LOG_FILES\PROFILE"
:: SICHER: Nur ergaenzen, niemals loeschen
set "ROBO_OPTS=/E /XC /XN /XO /R:1 /W:1 /XJ /TEE"
:: Optional: mehr Speed mit /MT:8 (oder 16)

:: ================== PRUEFUNGEN ==================
if not exist "D:\" (
  echo [ERROR] Laufwerk D:\ ist nicht erreichbar. Backup abgebrochen.
  exit /b 1
)
if not exist "%DESTROOT%" mkdir "%DESTROOT%"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:: ================== TIMESTAMP & Wochentag ==================
for /f "tokens=2 delims==." %%a in ('wmic os get LocalDateTime /value') do set "ldt=%%a"
set "YYYY=%ldt:~0,4%" & set "MM=%ldt:~4,2%" & set "DD=%ldt:~6,2%"
set "hh=%ldt:~8,2%"   & set "nn=%ldt:~10,2%"
set "TS=%YYYY%-%MM%-%DD%_%hh%-%nn%"

for /f "tokens=2 delims==" %%a in ('wmic path win32_localtime get dayofweek /value') do set "DOW=%%a"
if "%DOW%"=="0" (set "DW=d7") else set "DW=d%DOW%"
set "DEST=%DESTROOT%\%DW%"
if not exist "%DEST%" mkdir "%DEST%"
set "LOG=%LOGDIR%\profile_backup_%DW%_%TS%.log"

:: ================== SHELL-FOLDER PFADE ==================
set "Desktop=" & set "Documents=" & set "Pictures=" & set "Music=" & set "Videos="
set "Desktop_RAW=" & set "Documents_RAW=" & set "Pictures_RAW=" & set "Music_RAW=" & set "Videos_RAW="

:: OneDrive-Dokumente priorisieren
for /d %%D in ("%USERPROFILE%\OneDrive*") do (
  if exist "%%~fD\Dokumente" set "Documents=%%~fD\Dokumente"
  if not defined Documents if exist "%%~fD\Documents" set "Documents=%%~fD\Documents"
)

:: Registry auslesen (weitere Ordner)
call :get_user_shell "Desktop"      Desktop
call :get_user_shell "My Music"     Music
call :get_user_shell "My Video"     Videos
if not defined Videos call :get_user_shell "My Videos" Videos
call :get_user_shell "My Pictures"  Pictures

:: Fallbacks
if not defined Desktop   if exist "%USERPROFILE%\Desktop"   set "Desktop=%USERPROFILE%\Desktop"
if not defined Documents if exist "%USERPROFILE%\Documents" set "Documents=%USERPROFILE%\Documents"
if not defined Pictures  if exist "%USERPROFILE%\Pictures"  set "Pictures=%USERPROFILE%\Pictures"
if not defined Music     if exist "%USERPROFILE%\Music"     set "Music=%USERPROFILE%\Music"
if not defined Videos    if exist "%USERPROFILE%\Videos"    set "Videos=%USERPROFILE%\Videos"

:: OneDrive-Pictures ggf. lokalisierte Namen
if not defined Pictures (
  for /d %%D in ("%USERPROFILE%\OneDrive*") do (
    if exist "%%~fD\Bilder"   set "Pictures=%%~fD\Bilder"
    if not defined Pictures if exist "%%~fD\Pictures" set "Pictures=%%~fD\Pictures"
  )
)

:: ================== DEBUG-AUSGABE ==================
echo ============================================
echo    PROFIL-BACKUP (SAFE, mit Bilder)
echo ============================================
echo USERPROFILE:   %USERPROFILE%
echo Wochentag:     %DW%   (DOW=%DOW%)
echo Ziel (Basis):  %DESTROOT%
echo Ziel (Tag):    %DEST%
echo Logfile:       %LOG%
echo.
echo Quellen (RAW -> RESOLVED):
echo   Desktop   = "!Desktop_RAW!"   ^> "!Desktop!"
echo   Documents = "!Documents_RAW!" ^> "!Documents!"
echo   Pictures  = "!Pictures_RAW!"  ^> "!Pictures!"
echo   Music     = "!Music_RAW!"     ^> "!Music!"
echo   Videos    = "!Videos_RAW!"    ^> "!Videos!"
echo Robocopy-Optionen: %ROBO_OPTS%
echo ============================================
echo.

:: ================== BACKUP-LAUF ==================
set "OVERALL_RC=0"
call :backup_one "Desktop"   "%Desktop%"
call :backup_one "Documents" "%Documents%"
call :backup_one "Pictures"  "%Pictures%"
call :backup_one "Music"     "%Music%"
call :backup_one "Videos"    "%Videos%"

echo.
echo Backup abgeschlossen. Details: %LOG%
exit /b %OVERALL_RC%

:: --------- Sub: User Shell Folder -> expandierter Pfad ---------
:get_user_shell
set "VALNAME=%~1"
set "OUTVAR=%~2"
set "RAW=" & set "RES="

for /f "skip=2 tokens=2,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "%VALNAME%" 2^>nul') do (
  set "RAW=%%b"
)
if defined RAW (
  call set "RES=%%RAW%%"
  set "%OUTVAR%=%RES%"
  set "%OUTVAR%_RAW=%RAW%"
)
exit /b 0

:: --------- Subroutine: backup_one NAME SRC ---------
:backup_one
set "NAME=%~1"
set "SRC=%~2"

if not defined SRC (
  echo [WARN] %NAME%: Keine Quelle ermittelt. Ueberspringe.
  exit /b 0
)
if not exist "%SRC%" (
  echo [WARN] %NAME%: Quelle existiert nicht: "%SRC%". Ueberspringe.
  exit /b 0
)

:: Preflight: Quelle enthaelt irgendetwas?
set "HASFILES="
for /f "delims=" %%x in ('dir /b /a "%SRC%" 2^>nul') do (
  set "HASFILES=1"
  goto :after_list
)
:after_list

if not defined HASFILES (
  echo [WARN] %NAME%: Quelle scheint leer zu sein. Sicherung uebersprungen.
  exit /b 0
)

echo --- Sichere %NAME% ---
echo Quelle: "%SRC%"
echo Ziel:   "%DEST%\%NAME%"
robocopy "%SRC%" "%DEST%\%NAME%" %ROBO_OPTS% /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
if %RC% GTR 3 (
  echo [ERROR] %NAME% fehlgeschlagen. Robocopy-Code %RC%. Details: %LOG%
  set "OVERALL_RC=%RC%"
) else (
  echo [OK] %NAME% abgeschlossen. (RC=%RC%)
)
echo.
exit /b 0
