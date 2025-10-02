<#
.SYNOPSIS
    Report on retention policies and labels across Microsoft 365.
.DESCRIPTION
    Generates comprehensive report on retention policies, labels, and their
    application across Exchange, SharePoint, OneDrive, and Teams.
.PARAMETER IncludeLocations
    Show locations where policies are applied.
.PARAMETER IncludeLabels
    Include retention labels in report.
.PARAMETER PolicyName
    Filter by specific policy name.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-RetentionPolicyReport.ps1 -IncludeLocations -ExportPath "C:\retention-policies.csv"
.EXAMPLE
    .\Get-RetentionPolicyReport.ps1 -PolicyName "7-Year-Retention" -IncludeLabels
.NOTES
    Required Permissions: InformationProtectionPolicy.Read.All, SecurityActions.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeLocations,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeLabels,
    [Parameter(Mandatory = $false)]
    [string]$PolicyName,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating retention policy report..." -ForegroundColor Cyan

    # Get retention policies
    $policies = Get-MgSecurityInformationProtectionLabelPolicySetting

    if ($PolicyName) {
        $policies = $policies | Where-Object { $_.DisplayName -like "*$PolicyName*" }
    }

    $report = @()

    foreach ($policy in $policies) {
        Write-Progress -Activity "Analyzing retention policies" -Status $policy.DisplayName `
            -PercentComplete (([array]::IndexOf($policies, $policy) / $policies.Count) * 100)

        $policyInfo = [PSCustomObject]@{
            PolicyName = $policy.DisplayName
            Description = $policy.Description
            IsEnabled = $policy.IsEnabled
            CreatedDateTime = $policy.CreatedDateTime
            LastModifiedDateTime = $policy.LastModifiedDateTime
            Priority = $policy.Priority
        }

        # Add location information if requested
        if ($IncludeLocations) {
            $locations = @()
            if ($policy.ExchangeLocation) { $locations += "Exchange" }
            if ($policy.SharePointLocation) { $locations += "SharePoint" }
            if ($policy.OneDriveLocation) { $locations += "OneDrive" }
            if ($policy.SkypeLocation) { $locations += "Teams/Skype" }

            $policyInfo | Add-Member -MemberType NoteProperty -Name 'AppliedLocations' -Value ($locations -join ', ')
        }

        $report += $policyInfo
    }

    Write-Progress -Activity "Analyzing retention policies" -Completed

    # Get retention labels if requested
    $labelReport = @()

    if ($IncludeLabels) {
        Write-Host "Retrieving retention labels..." -ForegroundColor Cyan

        $labels = Get-MgSecurityInformationProtectionSensitivityLabel -All

        foreach ($label in $labels) {
            $labelReport += [PSCustomObject]@{
                LabelName = $label.Name
                Description = $label.Description
                IsActive = $label.IsActive
                Priority = $label.Priority
                CreatedDateTime = $label.CreatedDateTime
                ParentLabel = $label.ParentId
            }
        }
    }

    # Statistics
    $totalPolicies = $report.Count
    $enabledPolicies = ($report | Where-Object { $_.IsEnabled }).Count
    $totalLabels = $labelReport.Count

    Write-Host "`n=== Retention Policy Report ===" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total Retention Policies: $totalPolicies" -ForegroundColor White
    Write-Host "  Enabled Policies: $enabledPolicies" -ForegroundColor Green
    Write-Host "  Disabled Policies: $($totalPolicies - $enabledPolicies)" -ForegroundColor Yellow

    if ($IncludeLabels) {
        Write-Host "  Total Retention Labels: $totalLabels" -ForegroundColor White
    }

    if ($ExportPath) {
        # Export policies
        $policiesPath = $ExportPath -replace '\.csv$', '-policies.csv'
        $report | Sort-Object Priority | Export-Csv -Path $policiesPath -NoTypeInformation
        Write-Host "`n✓ Policies exported to: $policiesPath" -ForegroundColor Green

        # Export labels if included
        if ($IncludeLabels) {
            $labelsPath = $ExportPath -replace '\.csv$', '-labels.csv'
            $labelReport | Export-Csv -Path $labelsPath -NoTypeInformation
            Write-Host "✓ Labels exported to: $labelsPath" -ForegroundColor Green
        }
    }
    else {
        Write-Host "`nRetention Policies:" -ForegroundColor Cyan
        $report | Format-Table PolicyName, IsEnabled, Priority, AppliedLocations -AutoSize

        if ($IncludeLabels -and $labelReport.Count -gt 0) {
            Write-Host "`nRetention Labels:" -ForegroundColor Cyan
            $labelReport | Select-Object -First 10 | Format-Table LabelName, IsActive, Priority -AutoSize
        }
    }

    return @{
        Policies = $report
        Labels = $labelReport
    }
}
catch {
    Write-Error "Retention policy report failed: $_"
    Write-Host "`nNote: This feature requires Microsoft Purview/Compliance licensing" -ForegroundColor Yellow
}
