@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ===== Einstellungen =====
set "DESTROOT=D:\Backup_Profil"
set "LOGDIR=D:\ROBOCOPY_LOG_FILES\PROFILE"
:: Sicher: nur ergänzen, nie löschen
set "ROBO_OPTS=/E /XC /XN /XO /R:1 /W:1 /XJ /TEE"
:: Optional Speed: /MT:8  (bei Bedarf anhängen)

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
set "LOG=%LOGDIR%\profile_backup_%DW%_%TS%.log"

:: ===== Quellpfade bestimmen =====
set "Desktop=" & set "Documents=" & set "Music=" & set "Videos="
set "Desktop_RAW=" & set "Documents_RAW=" & set "Music_RAW=" & set "Videos_RAW="
set "Desktop_SRC_NOTE="

:: --- Documents: OneDrive bevorzugen (lokalisiert / englisch) ---
for /d %%D in ("%USERPROFILE%\OneDrive*") do (
  if exist "%%~fD\Dokumente" set "Documents=%%~fD\Dokumente"
  if not defined Documents if exist "%%~fD\Documents" set "Documents=%%~fD\Documents"
)
call :get_user_shell "Personal" Documents
if not defined Documents if exist "%USERPROFILE%\Documents" set "Documents=%USERPROFILE%\Documents"

:: --- Desktop: User Shell Folders -> GUID -> Fallback -> OneDriveRoot\Desktop ---
call :get_user_shell "Desktop" Desktop
set "Desktop_SRC_NOTE=User Shell Folders"
if not defined Desktop (
  call :get_user_shell "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" Desktop
  if defined Desktop set "Desktop_SRC_NOTE=KnownFolder GUID"
)
if not defined Desktop if exist "%USERPROFILE%\Desktop" (
  set "Desktop=%USERPROFILE%\Desktop"
  set "Desktop_SRC_NOTE=Fallback USERPROFILE\Desktop"
)
if defined Desktop (
  set "DCHK=!Desktop!"
  for /d %%R in ("%USERPROFILE%\OneDrive*") do (
    if /I "!DCHK!"=="%%~fR" (
      if exist "%%~fR\Desktop" set "Desktop=%%~fR\Desktop"
      set "Desktop_SRC_NOTE=OneDriveRoot->Desktop"
    )
  )
)
if not defined Desktop (
  for /d %%R in ("%USERPROFILE%\OneDrive*") do (
    if exist "%%~fR\Desktop" set "Desktop=%%~fR\Desktop" & set "Desktop_SRC_NOTE=OneDriveRoot\Desktop"
  )
)

:: --- Music / Videos ---
call :get_user_shell "My Music"  Music
call :get_user_shell "My Video"  Videos
if not defined Videos call :get_user_shell "My Videos" Videos
if not defined Music  if exist "%USERPROFILE%\Music"  set "Music=%USERPROFILE%\Music"
if not defined Videos if exist "%USERPROFILE%\Videos" set "Videos=%USERPROFILE%\Videos"

:: ===== Debug-Header =====
echo ============================================
echo   PROFIL-BACKUP (SAFE, additiv)
echo ============================================
echo USERPROFILE:   %USERPROFILE%
echo Wochentag:     %DW%   (DOW=%DOW%)
echo Ziel (Basis):  %DESTROOT%
echo Ziel (Tag):    %DEST%
echo Logfile:       %LOG%
echo.
echo Quellen (RAW -> RESOLVED):
echo   Desktop   = "!Desktop_RAW!"   ^> "!Desktop!"   (Quelle: !Desktop_SRC_NOTE!)
echo   Documents = "!Documents_RAW!" ^> "!Documents!"
echo   Music     = "!Music_RAW!"     ^> "!Music!"
echo   Videos    = "!Videos_RAW!"    ^> "!Videos!"
echo Robocopy-Optionen: %ROBO_OPTS%
echo ============================================
echo.

:: ===== Backup-Lauf =====
set "OVERALL_RC=0"
call :backup_one "Desktop"   "%Desktop%"
call :backup_one "Documents" "%Documents%"
call :backup_one "Music"     "%Music%"
call :backup_one "Videos"    "%Videos%"

echo.
echo Fertig. Details: %LOG%
exit /b %OVERALL_RC%

:: === Sub: User Shell Folder -> expandierter Pfad ===
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

:: === Sub: backup_one NAME SRC (mit Preflight + Pfad-Reinigung) ===
:backup_one
set "NAME=%~1"
set "SRC=%~2"

:: Pfad säubern (Anführungszeichen / versehentliche " > " Reste)
set "SRC=!SRC:"=!"
for /f "tokens=1 delims=>(" %%X in ("!SRC!") do set "SRC=%%~X"

if not defined SRC (
  echo [WARN] %NAME%: Keine Quelle ermittelt. Ueberspringe.
  exit /b 0
)
if not exist "!SRC!" (
  echo [WARN] %NAME%: Quelle existiert nicht: "!SRC!". Ueberspringe.
  exit /b 0
)

:: Preflight: Quelle enthält etwas?
set "HASFILES="
for /f "delims=" %%x in ('dir /b /a "!SRC!" 2^>nul') do (set "HASFILES=1" & goto :after_list)
:after_list
if not defined HASFILES (
  echo [WARN] %NAME%: Quelle wirkt leer. Ueberspringe.
  exit /b 0
)

echo --- Sichere %NAME% ---
echo Quelle: "!SRC!"
echo Ziel:   "%DEST%\%NAME%"
robocopy "!SRC!" "%DEST%\%NAME%" %ROBO_OPTS% /LOG+:"%LOG%"
set "RC=%ERRORLEVEL%"
if %RC% GTR 3 (
  echo [ERROR] %NAME% fehlgeschlagen. RC=%RC%  (siehe %LOG%)
  set "OVERALL_RC=%RC%"
) else (
  echo [OK] %NAME% abgeschlossen. (RC=%RC%)
)
echo.
exit /b 0
