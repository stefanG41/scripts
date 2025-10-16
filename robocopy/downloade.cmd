@echo off
setlocal
REM Ruft die robuste PowerShell-Datei auf
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0downloade.ps1"
set ERR=%ERRORLEVEL%
echo.
if not "%ERR%"=="0" (
  echo Es gab einen Fehler. Code: %ERR%
) else (
  echo Erfolgreich aktualisiert.
)
echo.
pause
endlocal
