<#
.SYNOPSIS
    Retrieve Microsoft Secure Score report.
.DESCRIPTION
    Gets current Secure Score, maximum score, and improvement actions
    to enhance tenant security posture.
.PARAMETER ShowActions
    Display recommended improvement actions.
.PARAMETER ActionState
    Filter actions by state: active, completed, or all.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-SecurityScoreReport.ps1 -ShowActions -ActionState active
.EXAMPLE
    .\Get-SecurityScoreReport.ps1 -ExportPath "C:\secure-score.csv"
.NOTES
    Required Permissions: SecurityEvents.Read.All, SecurityActions.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$ShowActions,
    [Parameter(Mandatory = $false)]
    [ValidateSet('active', 'completed', 'all')]
    [string]$ActionState = 'active',
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Retrieving Microsoft Secure Score..." -ForegroundColor Cyan

    # Get current secure score
    $secureScore = Get-MgSecuritySecureScore -Top 1 | Select-Object -First 1

    if (-not $secureScore) {
        throw "Could not retrieve Secure Score. Verify permissions."
    }

    $currentScore = $secureScore.CurrentScore
    $maxScore = $secureScore.MaxScore
    $percentageScore = [math]::Round(($currentScore / $maxScore) * 100, 2)

    Write-Host "`n=== Microsoft Secure Score ===" -ForegroundColor Cyan
    Write-Host "Current Score: $currentScore / $maxScore ($percentageScore%)" -ForegroundColor $(if ($percentageScore -ge 80) { 'Green' } elseif ($percentageScore -ge 60) { 'Yellow' } else { 'Red' })
    Write-Host "Active Users: $($secureScore.ActiveUserCount)" -ForegroundColor White
    Write-Host "Licensed Users: $($secureScore.LicensedUserCount)" -ForegroundColor White
    Write-Host "Enabled Services: $($secureScore.EnabledServices -join ', ')" -ForegroundColor White

    # Get improvement actions if requested
    if ($ShowActions) {
        Write-Host "`nRetrieving improvement actions..." -ForegroundColor Cyan

        $controlProfiles = Get-MgSecuritySecureScoreControlProfile -All

        if ($ActionState -ne 'all') {
            $controlProfiles = $controlProfiles | Where-Object {
                $_.ImplementationStatus -eq $ActionState
            }
        }

        $actions = $controlProfiles | ForEach-Object {
            [PSCustomObject]@{
                Title = $_.Title
                Category = $_.Category
                ControlType = $_.ControlType
                ActionType = $_.ActionType
                MaxScore = $_.MaxScore
                Rank = $_.Rank
                ImplementationStatus = $_.ImplementationStatus
                Remediation = $_.Remediation
                RemediationImpact = $_.RemediationImpact
                ThreatsAddressed = ($_.Threats -join ', ')
                Tier = $_.Tier
                ControlId = $_.Id
            }
        } | Sort-Object Rank, MaxScore -Descending

        Write-Host "`n✓ Found $($actions.Count) improvement actions" -ForegroundColor Green

        if ($ExportPath) {
            # Combine score and actions
            $fullReport = [PSCustomObject]@{
                CurrentScore = $currentScore
                MaxScore = $maxScore
                PercentageScore = $percentageScore
                ActiveUsers = $secureScore.ActiveUserCount
                LicensedUsers = $secureScore.LicensedUserCount
                Actions = $actions
            }

            $actions | Export-Csv -Path $ExportPath -NoTypeInformation
            Write-Host "✓ Report exported to: $ExportPath" -ForegroundColor Green
        } else {
            $actions | Select-Object -First 20 | Format-Table Title, MaxScore, ImplementationStatus, Category -AutoSize
            Write-Host "`n(Showing top 20 actions. Use -ExportPath for full list)" -ForegroundColor Yellow
        }

        return $actions
    }
    else {
        return $secureScore
    }
}
catch {
    Write-Error "Secure Score report failed: $_"
}
