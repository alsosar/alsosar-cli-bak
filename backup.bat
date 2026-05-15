@echo off
title asosar-cli-bak - Windows User Backup

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0backup.ps1" %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Backup completed with "errors" (check exit code). Review the backup log for details.
)

echo.
pause
