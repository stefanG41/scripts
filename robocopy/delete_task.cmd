@echo off
setlocal

set "TASK1=Backup_Bilder_Auto"
set "TASK2=Backup_Bilder_Auto_Silent"

echo.
echo ==========================================
echo   Entferne geplante Backup-Aufgaben
echo ==========================================
echo.

:: Task 1
schtasks /Query /TN "%TASK1%" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Loesche Aufgabe "%TASK1%" ...
  schtasks /Delete /TN "%TASK1%" /F >nul
  echo Aufgabe "%TASK1%" geloescht.
) else (
  echo Aufgabe "%TASK1%" wurde nicht gefunden.
)

:: Task 2 (optional, falls Silent-Variante existiert)
schtasks /Query /TN "%TASK2%" >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Loesche Aufgabe "%TASK2%" ...
  schtasks /Delete /TN "%TASK2%" /F >nul
  echo Aufgabe "%TASK2%" geloescht.
) else (
  echo Aufgabe "%TASK2%" wurde nicht gefunden.
)

echo.
echo Fertig. Alle relevanten Backup-Aufgaben wurden entfernt.
echo.
pause
