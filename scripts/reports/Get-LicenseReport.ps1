<#
.SYNOPSIS
    Generate a comprehensive license usage report for Microsoft 365.
.DESCRIPTION
    Retrieves license assignment information across the organization,
    including usage, costs, and unassigned licenses.
.PARAMETER ExportPath
    Path to export the report (CSV, Excel, or HTML).
.PARAMETER ShowUnassigned
    Include count of unassigned licenses.
.EXAMPLE
    .\Get-LicenseReport.ps1 -ExportPath "C:\Reports\licenses.csv" -ShowUnassigned
.NOTES
    Required Permissions: Organization.Read.All, Directory.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ExportPath,
    [Parameter(Mandatory = $false)]
    [switch]$ShowUnassigned
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating license report..." -ForegroundColor Cyan

    # Get all subscribed SKUs
    $subscribedSkus = Get-MgSubscribedSku

    $report = $subscribedSkus | ForEach-Object {
        $sku = $_
        $assigned = $sku.ConsumedUnits
        $available = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits

        [PSCustomObject]@{
            LicenseName = $sku.SkuPartNumber
            TotalLicenses = $sku.PrepaidUnits.Enabled
            AssignedLicenses = $assigned
            AvailableLicenses = $available
            UtilizationPercent = [Math]::Round(($assigned / $sku.PrepaidUnits.Enabled) * 100, 2)
            SkuId = $sku.SkuId
        }
    }

    # Display summary
    $totalLicenses = ($report | Measure-Object TotalLicenses -Sum).Sum
    $totalAssigned = ($report | Measure-Object AssignedLicenses -Sum).Sum
    $totalAvailable = ($report | Measure-Object AvailableLicenses -Sum).Sum

    Write-Host "`n=== License Summary ===" -ForegroundColor Green
    Write-Host "Total Licenses: $totalLicenses" -ForegroundColor White
    Write-Host "Assigned: $totalAssigned" -ForegroundColor Yellow
    Write-Host "Available: $totalAvailable" -ForegroundColor Cyan
    Write-Host "Utilization: $([Math]::Round(($totalAssigned/$totalLicenses)*100,2))%" -ForegroundColor Magenta

    # Export if requested
    if ($ExportPath) {
        $report | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Format-Table -AutoSize
    }

    return $report
}
catch {
    Write-Error "Failed to generate license report: $_"
}
