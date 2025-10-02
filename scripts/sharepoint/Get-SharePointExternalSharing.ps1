<#
.SYNOPSIS
    Audit external sharing links across SharePoint sites.
.DESCRIPTION
    Reports on all external sharing links (anonymous, guest) across SharePoint
    sites to identify potential security risks and compliance issues.
.PARAMETER SiteUrl
    Specific site to audit (optional, default: all sites).
.PARAMETER IncludeAnonymous
    Include anonymous sharing links in report.
.PARAMETER IncludeGuest
    Include guest user sharing in report.
.PARAMETER ExpiringDays
    Show links expiring in next X days.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-SharePointExternalSharing.ps1 -IncludeAnonymous -ExpiringDays 30 -ExportPath "C:\sharing-audit.csv"
.EXAMPLE
    .\Get-SharePointExternalSharing.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/finance" -IncludeGuest
.NOTES
    Required Permissions: Sites.Read.All, Sites.FullControl.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeAnonymous,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeGuest,
    [Parameter(Mandatory = $false)]
    [int]$ExpiringDays,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Auditing SharePoint external sharing..." -ForegroundColor Cyan

    # Get sites to audit
    if ($SiteUrl) {
        $sitePath = $SiteUrl -replace 'https://', ''
        $sites = @(Get-MgSite -Search $sitePath | Select-Object -First 1)
    }
    else {
        $sites = Get-MgSite -All -Property 'id,displayName,webUrl'
    }

    Write-Host "  Processing $($sites.Count) site(s)..." -ForegroundColor Cyan

    $sharingReport = @()

    foreach ($site in $sites) {
        Write-Progress -Activity "Auditing external sharing" -Status $site.DisplayName `
            -PercentComplete (([array]::IndexOf($sites, $site) / $sites.Count) * 100)

        try {
            # Get site permissions (sharing links)
            $permissions = Get-MgSitePermission -SiteId $site.Id -All

            foreach ($permission in $permissions) {
                $linkType = $permission.Link.Type
                $scope = $permission.Link.Scope

                # Filter based on parameters
                $includeThis = $false

                if ($IncludeAnonymous -and $linkType -eq 'view' -and $scope -eq 'anonymous') {
                    $includeThis = $true
                }

                if ($IncludeGuest -and ($scope -eq 'organization' -or $linkType -eq 'edit')) {
                    $includeThis = $true
                }

                if (-not $IncludeAnonymous -and -not $IncludeGuest) {
                    # Include all external sharing by default
                    $includeThis = $true
                }

                if ($includeThis) {
                    $expirationDate = $permission.ExpirationDateTime
                    $daysUntilExpiry = if ($expirationDate) {
                        [math]::Round(($expirationDate - (Get-Date)).TotalDays, 0)
                    }
                    else {
                        $null
                    }

                    # Filter by expiring days if specified
                    if ($ExpiringDays -and ($null -eq $daysUntilExpiry -or $daysUntilExpiry -gt $ExpiringDays)) {
                        continue
                    }

                    $sharedWith = if ($permission.GrantedToIdentitiesV2) {
                        ($permission.GrantedToIdentitiesV2 | ForEach-Object { $_.User.Email }) -join '; '
                    }
                    else {
                        "Anonymous/Link"
                    }

                    $sharingReport += [PSCustomObject]@{
                        SiteName = $site.DisplayName
                        SiteUrl = $site.WebUrl
                        SharedWith = $sharedWith
                        LinkType = $linkType
                        Scope = $scope
                        HasPassword = $permission.HasPassword
                        ExpirationDate = $expirationDate
                        DaysUntilExpiry = $daysUntilExpiry
                        CreatedDateTime = $permission.GrantedToIdentitiesV2[0].User.CreatedDateTime
                        PermissionId = $permission.Id
                        SiteId = $site.Id
                    }
                }
            }
        }
        catch {
            Write-Warning "Could not audit site $($site.DisplayName): $_"
        }
    }

    Write-Progress -Activity "Auditing external sharing" -Completed

    # Calculate statistics
    $totalShares = $sharingReport.Count
    $anonymousShares = ($sharingReport | Where-Object { $_.Scope -eq 'anonymous' }).Count
    $guestShares = $totalShares - $anonymousShares
    $expiringShares = ($sharingReport | Where-Object { $_.DaysUntilExpiry -and $_.DaysUntilExpiry -le 30 }).Count
    $noExpiryShares = ($sharingReport | Where-Object { $null -eq $_.ExpirationDate }).Count

    Write-Host "`n=== External Sharing Audit Report ===" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total External Shares: $totalShares" -ForegroundColor White
    Write-Host "  Anonymous Links: $anonymousShares" -ForegroundColor $(if ($anonymousShares -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "  Guest User Shares: $guestShares" -ForegroundColor White
    Write-Host "  Expiring Soon (30 days): $expiringShares" -ForegroundColor Yellow
    Write-Host "  No Expiration Set: $noExpiryShares" -ForegroundColor $(if ($noExpiryShares -gt 0) { 'Yellow' } else { 'Green' })

    if ($ExportPath) {
        $sharingReport | Sort-Object DaysUntilExpiry | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    }
    else {
        $sharingReport | Sort-Object DaysUntilExpiry | Select-Object -First 25 |
            Format-Table SiteName, SharedWith, LinkType, DaysUntilExpiry, HasPassword -AutoSize
        Write-Host "`n(Showing first 25 shares. Use -ExportPath for full report)" -ForegroundColor Yellow
    }

    return $sharingReport
}
catch {
    Write-Error "External sharing audit failed: $_"
}
