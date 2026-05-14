@echo off
title asosar-winbak - Windows User Backup

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0backup.ps1" %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo Some folders had errors. Check the log for details.
)

echo.
pause
