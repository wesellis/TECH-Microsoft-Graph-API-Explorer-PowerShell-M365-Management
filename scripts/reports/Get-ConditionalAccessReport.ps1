<#
.SYNOPSIS
    Report on Conditional Access policies configuration.
.DESCRIPTION
    Lists all Conditional Access policies with their conditions,
    controls, and state. Useful for security auditing.
.PARAMETER State
    Filter by policy state: enabled, disabled, or enabledForReportingButNotEnforced.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-ConditionalAccessReport.ps1 -State enabled -ExportPath "C:\ca-policies.csv"
.EXAMPLE
    .\Get-ConditionalAccessReport.ps1
.NOTES
    Required Permissions: Policy.Read.All, Directory.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('enabled', 'disabled', 'enabledForReportingButNotEnforced')]
    [string]$State,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Retrieving Conditional Access policies..." -ForegroundColor Cyan

    # Get CA policies
    $policies = Get-MgIdentityConditionalAccessPolicy -All

    if ($State) {
        $policies = $policies | Where-Object { $_.State -eq $State }
    }

    # Format report
    $report = $policies | ForEach-Object {
        $policy = $_

        # Extract conditions
        $includedUsers = if ($policy.Conditions.Users.IncludeUsers) { $policy.Conditions.Users.IncludeUsers -join '; ' } else { 'None' }
        $excludedUsers = if ($policy.Conditions.Users.ExcludeUsers) { $policy.Conditions.Users.ExcludeUsers -join '; ' } else { 'None' }
        $includedApps = if ($policy.Conditions.Applications.IncludeApplications) { $policy.Conditions.Applications.IncludeApplications -join '; ' } else { 'None' }
        $platforms = if ($policy.Conditions.Platforms.IncludePlatforms) { $policy.Conditions.Platforms.IncludePlatforms -join '; ' } else { 'Any' }
        $locations = if ($policy.Conditions.Locations.IncludeLocations) { $policy.Conditions.Locations.IncludeLocations -join '; ' } else { 'Any' }

        # Extract grant controls
        $grantControls = if ($policy.GrantControls) {
            $controls = @()
            if ($policy.GrantControls.BuiltInControls) { $controls += $policy.GrantControls.BuiltInControls }
            if ($policy.GrantControls.Operator) { $controls += "Operator: $($policy.GrantControls.Operator)" }
            $controls -join '; '
        } else { 'None' }

        # Extract session controls
        $sessionControls = if ($policy.SessionControls) {
            $controls = @()
            if ($policy.SessionControls.ApplicationEnforcedRestrictions) { $controls += 'AppEnforcedRestrictions' }
            if ($policy.SessionControls.CloudAppSecurity) { $controls += 'CloudAppSecurity' }
            if ($policy.SessionControls.PersistentBrowser) { $controls += 'PersistentBrowser' }
            if ($policy.SessionControls.SignInFrequency) { $controls += "SignInFreq: $($policy.SessionControls.SignInFrequency.Value)$($policy.SessionControls.SignInFrequency.Type)" }
            $controls -join '; '
        } else { 'None' }

        [PSCustomObject]@{
            PolicyName = $policy.DisplayName
            State = $policy.State
            CreatedDate = $policy.CreatedDateTime
            ModifiedDate = $policy.ModifiedDateTime
            IncludedUsers = $includedUsers
            ExcludedUsers = $excludedUsers
            IncludedApps = $includedApps
            Platforms = $platforms
            Locations = $locations
            GrantControls = $grantControls
            SessionControls = $sessionControls
            PolicyId = $policy.Id
        }
    }

    Write-Host "`n✓ Found $($report.Count) Conditional Access policies" -ForegroundColor Green

    # Statistics
    $enabled = ($report | Where-Object { $_.State -eq 'enabled' }).Count
    $disabled = ($report | Where-Object { $_.State -eq 'disabled' }).Count
    $reportOnly = ($report | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }).Count

    Write-Host "`nPolicy States:" -ForegroundColor Cyan
    Write-Host "  Enabled: $enabled" -ForegroundColor Green
    Write-Host "  Disabled: $disabled" -ForegroundColor Yellow
    Write-Host "  Report-Only: $reportOnly" -ForegroundColor Cyan

    if ($ExportPath) {
        $report | Sort-Object State, PolicyName | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Sort-Object State, PolicyName | Format-Table PolicyName, State, GrantControls, IncludedUsers -AutoSize
    }

    return $report
}
catch {
    Write-Error "Conditional Access report failed: $_"
}
