<#
.SYNOPSIS
    Create scheduled task for automated Graph API operations.
.DESCRIPTION
    Creates Windows scheduled tasks to run Graph API scripts on a schedule.
    Supports daily, weekly, or custom schedules with credential management.
.PARAMETER ScriptPath
    Full path to the PowerShell script to run.
.PARAMETER TaskName
    Name for the scheduled task.
.PARAMETER Schedule
    Schedule type: Daily, Weekly, Monthly, or Custom.
.PARAMETER Time
    Time to run the task (format: HH:mm, e.g., "09:00").
.PARAMETER Days
    For Weekly schedule: days of week (Monday, Tuesday, etc.).
.PARAMETER ScriptArguments
    Arguments to pass to the script.
.PARAMETER RunAsUser
    User account to run task as (default: current user).
.PARAMETER Description
    Task description.
.EXAMPLE
    .\New-ScheduledGraphTask.ps1 -ScriptPath "C:\Scripts\Get-InactiveUsers.ps1" -TaskName "Daily-Inactive-Users-Report" -Schedule Daily -Time "08:00"
.EXAMPLE
    .\New-ScheduledGraphTask.ps1 -ScriptPath "C:\Scripts\Backup-TeamsConfig.ps1" -TaskName "Weekly-Teams-Backup" -Schedule Weekly -Days "Monday","Friday" -Time "18:00"
.NOTES
    Requires local admin rights to create scheduled tasks.
    Script must handle Graph authentication (use certificate auth for unattended).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ScriptPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TaskName,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Daily', 'Weekly', 'Monthly', 'Custom')]
    [string]$Schedule,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$Time,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]
    [string[]]$Days,
    [Parameter(Mandatory = $false)]
    [string]$ScriptArguments,
    [Parameter(Mandatory = $false)]
    [string]$RunAsUser = $env:USERNAME,
    [Parameter(Mandatory = $false)]
    [string]$Description = "Automated Graph API task"
)

try {
    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "This script requires administrator privileges to create scheduled tasks."
    }

    Write-Host "Creating scheduled task: $TaskName" -ForegroundColor Cyan
    Write-Host "  Script: $ScriptPath" -ForegroundColor White
    Write-Host "  Schedule: $Schedule at $Time" -ForegroundColor White

    if ($PSCmdlet.ShouldProcess($TaskName, "Create scheduled task")) {
        # Build action (what to run)
        $actionArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        if ($ScriptArguments) {
            $actionArgs += " $ScriptArguments"
        }

        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $actionArgs

        # Build trigger (when to run)
        $trigger = switch ($Schedule) {
            'Daily' {
                New-ScheduledTaskTrigger -Daily -At $Time
            }
            'Weekly' {
                if (-not $Days) {
                    throw "Days parameter required for Weekly schedule"
                }
                New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Days -At $Time
            }
            'Monthly' {
                New-ScheduledTaskTrigger -At $Time -Monthly -DaysOfMonth 1
            }
            'Custom' {
                # Allow user to customize further
                Write-Host "  Note: Custom schedule requires manual trigger configuration" -ForegroundColor Yellow
                New-ScheduledTaskTrigger -Once -At $Time
            }
        }

        # Build principal (who runs it)
        $principal = New-ScheduledTaskPrincipal -UserId $RunAsUser -LogonType S4U -RunLevel Highest

        # Build settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
            -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2)

        # Register task
        $task = Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
            -Principal $principal -Settings $settings -Description $Description -Force

        Write-Host "`n✓ Scheduled task created successfully!" -ForegroundColor Green
        Write-Host "  Task Name: $TaskName" -ForegroundColor Cyan
        Write-Host "  Next Run: $(Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo | Select-Object -ExpandProperty NextRunTime)" -ForegroundColor Cyan

        Write-Host "`nImportant Notes:" -ForegroundColor Yellow
        Write-Host "  - Ensure the script can authenticate non-interactively (use certificate auth)" -ForegroundColor White
        Write-Host "  - Test the script manually before relying on scheduled execution" -ForegroundColor White
        Write-Host "  - View task history in Task Scheduler for troubleshooting" -ForegroundColor White

        Write-Host "`nTo manage this task:" -ForegroundColor Cyan
        Write-Host "  View: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
        Write-Host "  Run: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
        Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White

        return $task
    }
}
catch {
    Write-Error "Failed to create scheduled task: $_"
}
