<#
.SYNOPSIS
    Report on Data Loss Prevention (DLP) policies and incidents.
.DESCRIPTION
    Generates report on DLP policies, rules, and policy tip incidents
    to assess data protection coverage and effectiveness.
.PARAMETER IncludeIncidents
    Include recent DLP policy matches/incidents.
.PARAMETER Days
    Number of days to look back for incidents (default: 7).
.PARAMETER PolicyName
    Filter by specific policy name.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-DLPPolicyReport.ps1 -IncludeIncidents -Days 30 -ExportPath "C:\dlp-report.csv"
.EXAMPLE
    .\Get-DLPPolicyReport.ps1 -PolicyName "Credit Card Protection"
.NOTES
    Required Permissions: InformationProtectionPolicy.Read.All, SecurityEvents.Read.All
    Requires Microsoft 365 E5 or Compliance license
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeIncidents,
    [Parameter(Mandatory = $false)]
    [int]$Days = 7,
    [Parameter(Mandatory = $false)]
    [string]$PolicyName,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating DLP policy report..." -ForegroundColor Cyan

    # Get DLP policies (via Information Protection)
    Write-Host "Retrieving DLP policies..." -ForegroundColor Cyan

    # Note: DLP policies are part of Microsoft Purview
    # Graph API access is limited - may require Security & Compliance PowerShell
    $policies = Get-MgSecurityInformationProtectionLabelPolicySetting

    if ($PolicyName) {
        $policies = $policies | Where-Object { $_.DisplayName -like "*$PolicyName*" }
    }

    $report = @()

    foreach ($policy in $policies) {
        $policyInfo = [PSCustomObject]@{
            PolicyName = $policy.DisplayName
            Description = $policy.Description
            IsEnabled = $policy.IsEnabled
            Mode = if ($policy.IsEnabled) { "Enforce" } else { "Test" }
            Priority = $policy.Priority
            CreatedDateTime = $policy.CreatedDateTime
            LastModifiedDateTime = $policy.LastModifiedDateTime
        }

        $report += $policyInfo
    }

    # Get incidents if requested
    $incidentReport = @()

    if ($IncludeIncidents) {
        Write-Host "Retrieving DLP incidents (last $Days days)..." -ForegroundColor Cyan

        $startDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $filter = "createdDateTime ge $startDate"

        try {
            # Get security alerts that may include DLP incidents
            $alerts = Get-MgSecurityAlert -Filter $filter -All

            $dlpAlerts = $alerts | Where-Object {
                $_.Category -like "*DLP*" -or $_.Title -like "*Data Loss*" -or $_.Title -like "*sensitive*"
            }

            foreach ($alert in $dlpAlerts) {
                $incidentReport += [PSCustomObject]@{
                    IncidentDate = $alert.CreatedDateTime
                    Severity = $alert.Severity
                    Title = $alert.Title
                    Category = $alert.Category
                    Status = $alert.Status
                    User = $alert.UserStates[0].UserPrincipalName
                    FileName = $alert.FileStates[0].Name
                    AlertId = $alert.Id
                }
            }
        }
        catch {
            Write-Warning "Could not retrieve DLP incidents. This may require Security & Compliance PowerShell module."
        }
    }

    # Statistics
    $totalPolicies = $report.Count
    $enabledPolicies = ($report | Where-Object { $_.IsEnabled }).Count
    $totalIncidents = $incidentReport.Count

    Write-Host "`n=== DLP Policy Report ===" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total DLP Policies: $totalPolicies" -ForegroundColor White
    Write-Host "  Enabled (Enforce): $enabledPolicies" -ForegroundColor Green
    Write-Host "  Disabled (Test): $($totalPolicies - $enabledPolicies)" -ForegroundColor Yellow

    if ($IncludeIncidents) {
        Write-Host "  DLP Incidents (Last $Days days): $totalIncidents" -ForegroundColor $(if ($totalIncidents -gt 0) { 'Red' } else { 'Green' })

        if ($totalIncidents -gt 0) {
            $highSeverity = ($incidentReport | Where-Object { $_.Severity -eq 'high' }).Count
            $mediumSeverity = ($incidentReport | Where-Object { $_.Severity -eq 'medium' }).Count
            $lowSeverity = ($incidentReport | Where-Object { $_.Severity -eq 'low' }).Count

            Write-Host "    High Severity: $highSeverity" -ForegroundColor Red
            Write-Host "    Medium Severity: $mediumSeverity" -ForegroundColor Yellow
            Write-Host "    Low Severity: $lowSeverity" -ForegroundColor Cyan
        }
    }

    if ($ExportPath) {
        # Export policies
        $policiesPath = $ExportPath -replace '\.csv$', '-policies.csv'
        $report | Export-Csv -Path $policiesPath -NoTypeInformation
        Write-Host "`n✓ Policies exported to: $policiesPath" -ForegroundColor Green

        # Export incidents if included
        if ($IncludeIncidents -and $incidentReport.Count -gt 0) {
            $incidentsPath = $ExportPath -replace '\.csv$', '-incidents.csv'
            $incidentReport | Export-Csv -Path $incidentsPath -NoTypeInformation
            Write-Host "✓ Incidents exported to: $incidentsPath" -ForegroundColor Green
        }
    }
    else {
        Write-Host "`nDLP Policies:" -ForegroundColor Cyan
        $report | Format-Table PolicyName, IsEnabled, Mode, Priority -AutoSize

        if ($IncludeIncidents -and $incidentReport.Count -gt 0) {
            Write-Host "`nRecent DLP Incidents:" -ForegroundColor Cyan
            $incidentReport | Select-Object -First 10 | Format-Table IncidentDate, Severity, Title, User, FileName -AutoSize
        }
    }

    Write-Host "`nNote: For complete DLP reporting, use Security & Compliance PowerShell:" -ForegroundColor Yellow
    Write-Host "  Connect-IPPSSession" -ForegroundColor White
    Write-Host "  Get-DlpCompliancePolicy" -ForegroundColor White
    Write-Host "  Get-DlpIncidentDetail" -ForegroundColor White

    return @{
        Policies = $report
        Incidents = $incidentReport
    }
}
catch {
    Write-Error "DLP policy report failed: $_"
}
