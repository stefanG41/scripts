@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === Einstellungen ===
set "LOGDIR=D:\ROBOCOPY_LOG_FILES"
set "MAXFILES=100"

echo =============================================
echo   Robocopy-Log Cleanup (max. %MAXFILES% Files)
echo   Ordner: %LOGDIR%
echo =============================================
echo.

if not exist "%LOGDIR%" (
  echo Log-Ordner nicht vorhanden. Nichts zu tun.
  exit /b 0
)

pushd "%LOGDIR%" || (
  echo Konnte nicht in %LOGDIR% wechseln.
  exit /b 1
)

:: Anzahl .log-Dateien zaehlen
set /a COUNT=0
for %%F in (*.log) do (
  set /a COUNT+=1
)

echo Gefundene Logfiles: %COUNT%

if %COUNT% LEQ %MAXFILES% (
  echo Grenze nicht ueberschritten. Beende.
  popd
  exit /b 0
)

set /a TO_DELETE=%COUNT% - %MAXFILES%
echo Zu loeschende aelteste Dateien: %TO_DELETE%
echo.

:: Aelteste zuerst (nach Datum/Zeit) auflisten und die ersten TO_DELETE loeschen
set /a N=0
for /f "usebackq delims=" %%F in (`dir /b /a:-d /o:d *.log`) do (
  if !N! LSS %TO_DELETE% (
    echo Loesche: "%%F"
    del /q "%%F"
    set /a N+=1
  )
)

echo.
echo Cleanup abgeschlossen. Verbleibende Dateien sollten <= %MAXFILES% sein.
popd
exit /b 0
