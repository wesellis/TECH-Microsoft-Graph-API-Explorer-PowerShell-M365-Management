<#
.SYNOPSIS
    Find inactive users who haven't signed in recently.
.DESCRIPTION
    Identifies users who haven't signed in within specified number of days.
    Useful for license reclamation and security audits.
.PARAMETER Days
    Number of days of inactivity. Default is 90.
.PARAMETER ExportPath
    Export report to CSV.
.PARAMETER DisableAccounts
    Automatically disable inactive accounts (use with caution!).
.EXAMPLE
    .\Get-InactiveUsers.ps1 -Days 90 -ExportPath "C:\Reports\inactive.csv"
.NOTES
    Required Permissions: User.Read.All, AuditLog.Read.All, User.ReadWrite.All (if disabling)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Days = 90,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath,
    [Parameter(Mandatory = $false)]
    [switch]$DisableAccounts
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Finding users inactive for $Days+ days..." -ForegroundColor Cyan

    $cutoffDate = (Get-Date).AddDays(-$Days)

    # Get all users with sign-in activity
    $users = Get-MgUser -All -Property 'id,displayName,userPrincipalName,accountEnabled,signInActivity,userType' |
        Where-Object { $_.UserType -eq 'Member' }

    $inactiveUsers = $users | Where-Object {
        $lastSignIn = $_.SignInActivity.LastSignInDateTime
        (-not $lastSignIn) -or ([datetime]$lastSignIn -lt $cutoffDate)
    } | Select-Object `
        DisplayName,
        UserPrincipalName,
        AccountEnabled,
        @{N='LastSignIn';E={
            if ($_.SignInActivity.LastSignInDateTime) {
                $_.SignInActivity.LastSignInDateTime
            } else {
                'Never'
            }
        }},
        @{N='DaysInactive';E={
            if ($_.SignInActivity.LastSignInDateTime) {
                ((Get-Date) - [datetime]$_.SignInActivity.LastSignInDateTime).Days
            } else {
                'Never'
            }
        }}

    Write-Host "`n✓ Found $($inactiveUsers.Count) inactive users" -ForegroundColor Yellow

    if ($DisableAccounts -and $inactiveUsers.Count -gt 0) {
        Write-Warning "Disabling $($inactiveUsers.Count) inactive accounts..."
        $inactiveUsers | ForEach-Object {
            if ($_.AccountEnabled) {
                Update-MgUser -UserId $_.UserPrincipalName -AccountEnabled:$false
                Write-Host "  Disabled: $($_.DisplayName)" -ForegroundColor Red
            }
        }
    }

    if ($ExportPath) {
        $inactiveUsers | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $inactiveUsers | Format-Table -AutoSize
    }

    return $inactiveUsers
}
catch {
    Write-Error "Failed to find inactive users: $_"
}
