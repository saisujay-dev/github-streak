# ============================================================
#  GitHub Streak Bot — Task Scheduler Setup
#
#  INSTRUCTIONS:
#  1. First create an empty GitHub repo named "github-streak"
#     (or any name you like) at https://github.com/new
#  2. Run: git remote add origin https://github.com/YOUR_USERNAME/github-streak.git
#     inside c:\github-streak  (or use the HTTPS URL below)
#  3. Run THIS script as Administrator (right-click > Run as Administrator)
# ============================================================

$TaskName   = "GitHubStreakBot"
$BatFile    = "c:\github-streak\run_streak.bat"
$RunTime    = "21:00"   # 9:00 PM — change if needed

Write-Host ""
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host "   GitHub Streak Bot — Setup" -ForegroundColor Cyan
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host "  Task Name : $TaskName"
Write-Host "  Script    : $BatFile"
Write-Host "  Runs At   : $RunTime every day"
Write-Host ""

# ── Remove old task if exists ────────────────────────────────────────────
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "  [INFO] Old task removed." -ForegroundColor Yellow
}

# ── Define the action ────────────────────────────────────────────────────
$Action = New-ScheduledTaskAction `
    -Execute    "cmd.exe" `
    -Argument   "/c `"$BatFile`"" `
    -WorkingDirectory "c:\github-streak"

# ── Daily trigger ─────────────────────────────────────────────────────────
$Trigger = New-ScheduledTaskTrigger -Daily -At $RunTime

# ── Principal: run as current user, highest privileges ───────────────────
$Principal = New-ScheduledTaskPrincipal `
    -UserId   $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

# ── Settings ──────────────────────────────────────────────────────────────
$Settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit       (New-TimeSpan -Minutes 10) `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -WakeToRun:$false

# ── Register ──────────────────────────────────────────────────────────────
Register-ScheduledTask `
    -TaskName   $TaskName `
    -Action     $Action `
    -Trigger    $Trigger `
    -Principal  $Principal `
    -Settings   $Settings `
    -Description "Commits to GitHub streak repo every day at $RunTime" | Out-Null

Write-Host "  [OK] Task registered successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  ── Quick commands ──────────────────────────────────" -ForegroundColor Gray
Write-Host "  Test now  : Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "  View logs : notepad c:\github-streak\bot_run.log"
Write-Host "  Remove    : Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
Write-Host "  Task GUI  : taskschd.msc > Task Scheduler Library"
Write-Host ""
