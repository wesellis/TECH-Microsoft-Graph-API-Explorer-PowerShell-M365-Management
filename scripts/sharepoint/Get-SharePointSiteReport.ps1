<#
.SYNOPSIS
    Generate SharePoint site usage and permission report.
.DESCRIPTION
    Reports on SharePoint sites including storage usage, activity,
    owners, and sharing settings. Helps with governance and compliance.
.PARAMETER SiteUrl
    Specific site URL to report on (optional, default: all sites).
.PARAMETER IncludeStorageDetails
    Include detailed storage metrics.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-SharePointSiteReport.ps1 -IncludeStorageDetails -ExportPath "C:\sharepoint-sites.csv"
.EXAMPLE
    .\Get-SharePointSiteReport.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/marketing"
.NOTES
    Required Permissions: Sites.Read.All, Sites.ReadWrite.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeStorageDetails,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Retrieving SharePoint site information..." -ForegroundColor Cyan

    # Get sites
    if ($SiteUrl) {
        # Get specific site
        $sites = @(Get-MgSite -Search ($SiteUrl -replace 'https://', ''))
    } else {
        # Get all sites
        $sites = Get-MgSite -All -Property 'id,displayName,webUrl,createdDateTime,lastModifiedDateTime,siteCollection'
    }

    Write-Host "  Processing $($sites.Count) site(s)..." -ForegroundColor Cyan

    $report = $sites | ForEach-Object {
        $site = $_

        Write-Progress -Activity "Analyzing sites" -Status $site.DisplayName `
            -PercentComplete (([array]::IndexOf($sites, $site) / $sites.Count) * 100)

        $siteInfo = [PSCustomObject]@{
            SiteName = $site.DisplayName
            SiteUrl = $site.WebUrl
            CreatedDate = $site.CreatedDateTime
            LastModified = $site.LastModifiedDateTime
            IsPersonalSite = $site.IsPersonalSite
            SiteId = $site.Id
        }

        # Get storage details if requested
        if ($IncludeStorageDetails) {
            try {
                $drive = Get-MgSiteDrive -SiteId $site.Id -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($drive) {
                    $usedGB = [math]::Round($drive.Quota.Used / 1GB, 2)
                    $totalGB = [math]::Round($drive.Quota.Total / 1GB, 2)
                    $percentUsed = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }

                    $siteInfo | Add-Member -MemberType NoteProperty -Name 'StorageUsedGB' -Value $usedGB
                    $siteInfo | Add-Member -MemberType NoteProperty -Name 'StorageTotalGB' -Value $totalGB
                    $siteInfo | Add-Member -MemberType NoteProperty -Name 'StoragePercentUsed' -Value $percentUsed
                }
            } catch {
                $siteInfo | Add-Member -MemberType NoteProperty -Name 'StorageUsedGB' -Value 0
                $siteInfo | Add-Member -MemberType NoteProperty -Name 'StorageTotalGB' -Value 0
                $siteInfo | Add-Member -MemberType NoteProperty -Name 'StoragePercentUsed' -Value 0
            }
        }

        # Get site owners
        try {
            $owners = Get-MgSitePermission -SiteId $site.Id -ErrorAction SilentlyContinue |
                Where-Object { $_.Roles -contains 'owner' } |
                Select-Object -First 3

            $ownerNames = $owners | ForEach-Object {
                if ($_.GrantedToIdentitiesV2) {
                    $_.GrantedToIdentitiesV2.User.DisplayName
                }
            }

            $siteInfo | Add-Member -MemberType NoteProperty -Name 'Owners' -Value ($ownerNames -join '; ')
        } catch {
            $siteInfo | Add-Member -MemberType NoteProperty -Name 'Owners' -Value 'N/A'
        }

        $siteInfo
    }

    Write-Progress -Activity "Analyzing sites" -Completed

    Write-Host "`n✓ Found $($report.Count) SharePoint sites" -ForegroundColor Green

    # Calculate storage statistics if included
    if ($IncludeStorageDetails) {
        $totalStorageUsed = ($report | Measure-Object -Property StorageUsedGB -Sum).Sum
        $totalStorageAvailable = ($report | Measure-Object -Property StorageTotalGB -Sum).Sum

        Write-Host "`nStorage Summary:" -ForegroundColor Cyan
        Write-Host "  Total Used: $([math]::Round($totalStorageUsed, 2)) GB" -ForegroundColor White
        Write-Host "  Total Available: $([math]::Round($totalStorageAvailable, 2)) GB" -ForegroundColor White
    }

    if ($ExportPath) {
        $report | Sort-Object StorageUsedGB -Descending | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        if ($IncludeStorageDetails) {
            $report | Sort-Object StorageUsedGB -Descending | Format-Table SiteName, StorageUsedGB, StorageTotalGB, Owners -AutoSize
        } else {
            $report | Format-Table SiteName, SiteUrl, CreatedDate, Owners -AutoSize
        }
    }

    return $report
}
catch {
    Write-Error "SharePoint site report failed: $_"
}
