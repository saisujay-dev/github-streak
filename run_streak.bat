@echo off
:: ============================================================
::  GitHub Streak Bot — Daily Runner
::  Called by Windows Task Scheduler every day at 9:00 PM
::  DO NOT move this file without updating setup_streak_task.ps1
:: ============================================================

setlocal EnableDelayedExpansion

:: ── Paths ────────────────────────────────────────────────────────────────
set "BOT_DIR=c:\github-streak"
set "BOT_SCRIPT=%BOT_DIR%\streak_bot.py"
set "LOGFILE=%BOT_DIR%\runner.log"

:: ── Timestamp ────────────────────────────────────────────────────────────
for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "TIMESTAMP=%%I"

echo. >> "%LOGFILE%"
echo ================================================ >> "%LOGFILE%"
echo  Runner started: %TIMESTAMP% >> "%LOGFILE%"
echo ================================================ >> "%LOGFILE%"

:: ── Verify Python ────────────────────────────────────────────────────────
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found in PATH >> "%LOGFILE%"
    echo [ERROR] Python not found in PATH
    exit /b 1
)

:: ── Run the bot ──────────────────────────────────────────────────────────
cd /d "%BOT_DIR%"
python "%BOT_SCRIPT%" >> "%LOGFILE%" 2>&1

if errorlevel 1 (
    echo [ERROR] streak_bot.py exited with error. Check bot_run.log >> "%LOGFILE%"
    exit /b 1
)

echo [DONE] Streak bot finished at %TIMESTAMP% >> "%LOGFILE%"
exit /b 0
