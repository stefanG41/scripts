@echo off
set "TASKNAME=ProfileBackup"
echo [INFO] Versuche, den Task "%TASKNAME%" zu löschen...
schtasks /delete /tn "%TASKNAME%" /f
pause
