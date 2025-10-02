<#
.SYNOPSIS
    Generate risky sign-in activity report.
.DESCRIPTION
    Reports on risky sign-ins detected by Azure AD Identity Protection,
    including risk level, risk details, and user information.
.PARAMETER RiskLevel
    Filter by risk level: low, medium, high.
.PARAMETER Days
    Number of days to look back (default: 7).
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-SignInRiskReport.ps1 -RiskLevel high -Days 30 -ExportPath "C:\high-risk-signins.csv"
.EXAMPLE
    .\Get-SignInRiskReport.ps1 -Days 7
.NOTES
    Required Permissions: IdentityRiskyUser.Read.All, IdentityRiskEvent.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('low', 'medium', 'high')]
    [string]$RiskLevel,
    [Parameter(Mandatory = $false)]
    [int]$Days = 7,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating risky sign-in report (last $Days days)..." -ForegroundColor Cyan

    # Calculate date filter
    $startDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $filter = "createdDateTime ge $startDate"

    if ($RiskLevel) {
        $filter += " and riskLevel eq '$RiskLevel'"
    }

    # Get risky sign-ins
    $riskySignIns = Get-MgRiskyUser -Filter $filter -All

    # Get detailed risk detections
    $riskDetections = Get-MgRiskDetection -Filter $filter -All

    # Combine data
    $report = $riskDetections | ForEach-Object {
        $detection = $_

        # Get user info
        try {
            $user = Get-MgUser -UserId $detection.UserId -Property 'displayName,userPrincipalName,userType'
        } catch {
            $user = $null
        }

        [PSCustomObject]@{
            DetectedDate = $detection.DetectedDateTime
            UserPrincipalName = if ($user) { $user.UserPrincipalName } else { $detection.UserPrincipalName }
            DisplayName = if ($user) { $user.DisplayName } else { $detection.UserDisplayName }
            UserType = if ($user) { $user.UserType } else { 'Unknown' }
            RiskLevel = $detection.RiskLevel
            RiskState = $detection.RiskState
            RiskDetail = $detection.RiskDetail
            RiskType = $detection.RiskEventType
            IPAddress = $detection.IpAddress
            Location = $detection.Location.City + ', ' + $detection.Location.CountryOrRegion
            DetectionTimingType = $detection.DetectionTimingType
            Activity = $detection.Activity
            UserId = $detection.UserId
            DetectionId = $detection.Id
        }
    }

    # Statistics
    $totalRisks = $report.Count
    $highRisk = ($report | Where-Object { $_.RiskLevel -eq 'high' }).Count
    $mediumRisk = ($report | Where-Object { $_.RiskLevel -eq 'medium' }).Count
    $lowRisk = ($report | Where-Object { $_.RiskLevel -eq 'low' }).Count
    $uniqueUsers = ($report | Select-Object -Unique UserId).Count

    Write-Host "`n✓ Risky Sign-In Report" -ForegroundColor Green
    Write-Host "`nSummary (Last $Days days):" -ForegroundColor Cyan
    Write-Host "  Total Risk Detections: $totalRisks" -ForegroundColor White
    Write-Host "  High Risk: $highRisk" -ForegroundColor $(if ($highRisk -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Medium Risk: $mediumRisk" -ForegroundColor $(if ($mediumRisk -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "  Low Risk: $lowRisk" -ForegroundColor Cyan
    Write-Host "  Affected Users: $uniqueUsers" -ForegroundColor White

    if ($ExportPath) {
        $report | Sort-Object RiskLevel -Descending | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Sort-Object RiskLevel -Descending | Format-Table DetectedDate, UserPrincipalName, RiskLevel, RiskType, Location, IPAddress -AutoSize
    }

    return $report
}
catch {
    Write-Error "Risky sign-in report failed: $_"
}
