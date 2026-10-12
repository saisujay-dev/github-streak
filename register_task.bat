@echo off
:: ============================================================
:: Double-click this file to register GitHubStreakBot in Task Scheduler
:: It will request Administrator permission to register the daily task.
:: ============================================================

echo Requesting Administrator privileges to register Scheduled Task...
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File ""c:\github-streak\setup_streak_task.ps1""'"
pause
