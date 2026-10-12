# ============================================================
# GitHub Streak Bot - Task Scheduler Setup
# ============================================================

$TaskName   = "GitHubStreakBot"
$BatFile    = "c:\github-streak\run_streak.bat"
$RunTime    = "21:00"

Write-Host ""
Write-Host "Setting up GitHub Streak Bot..." -ForegroundColor Cyan
Write-Host "Task Name: $TaskName"
Write-Host "Script:    $BatFile"
Write-Host "Runs At:   $RunTime every day"
Write-Host ""

# Remove old task if exists
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[INFO] Old task removed." -ForegroundColor Yellow
}

# Define Action
$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatFile`"" -WorkingDirectory "c:\github-streak"

# Define Trigger (Daily at 9:00 PM)
$Trigger = New-ScheduledTaskTrigger -Daily -At $RunTime

# Define Principal (Current user)
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

# Define Settings
$Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -StartWhenAvailable

# Register Task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Daily GitHub Streak Auto Commit" | Out-Null

Write-Host "[OK] Task registered successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To test right now:" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host ""
Write-Host "To view logs:" -ForegroundColor Gray
Write-Host "  Get-Content c:\github-streak\bot_run.log -Tail 20"
Write-Host ""
