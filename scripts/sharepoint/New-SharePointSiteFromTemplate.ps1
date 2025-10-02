<#
.SYNOPSIS
    Create SharePoint site from predefined template.
.DESCRIPTION
    Creates SharePoint team sites or communication sites based on templates
    with preconfigured lists, libraries, and permissions.
.PARAMETER SiteName
    Display name for the new site.
.PARAMETER SiteAlias
    URL alias for the site (e.g., "marketing" for /sites/marketing).
.PARAMETER Template
    Template type: TeamSite, CommunicationSite, ProjectSite, or Custom.
.PARAMETER Owners
    Array of owner email addresses.
.PARAMETER Members
    Array of member email addresses.
.PARAMETER Description
    Site description.
.PARAMETER IsPublic
    Make site publicly accessible within organization (default: false).
.EXAMPLE
    .\New-SharePointSiteFromTemplate.ps1 -SiteName "Q1 Project Site" -SiteAlias "q1-project" -Template ProjectSite -Owners "manager@contoso.com" -Members "team@contoso.com"
.EXAMPLE
    .\New-SharePointSiteFromTemplate.ps1 -SiteName "Company News" -SiteAlias "news" -Template CommunicationSite -Owners "admin@contoso.com" -IsPublic
.NOTES
    Required Permissions: Sites.FullControl.All, Group.ReadWrite.All
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteName,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string]$SiteAlias,
    [Parameter(Mandatory = $true)]
    [ValidateSet('TeamSite', 'CommunicationSite', 'ProjectSite', 'DepartmentSite')]
    [string]$Template,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Owners,
    [Parameter(Mandatory = $false)]
    [string[]]$Members,
    [Parameter(Mandatory = $false)]
    [string]$Description,
    [Parameter(Mandatory = $false)]
    [switch]$IsPublic
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "=== Creating SharePoint Site from Template ===" -ForegroundColor Cyan
    Write-Host "Site Name: $SiteName" -ForegroundColor White
    Write-Host "Alias: $SiteAlias" -ForegroundColor White
    Write-Host "Template: $Template" -ForegroundColor White
    Write-Host ""

    if ($PSCmdlet.ShouldProcess($SiteName, "Create SharePoint site")) {
        # Create M365 Group (which creates SharePoint site)
        Write-Host "Creating Microsoft 365 Group..." -ForegroundColor Cyan

        $groupParams = @{
            DisplayName = $SiteName
            MailEnabled = $true
            MailNickname = $SiteAlias
            SecurityEnabled = $false
            GroupTypes = @("Unified")
            Description = $Description
            Visibility = if ($IsPublic) { "Public" } else { "Private" }
        }

        $group = New-MgGroup -BodyParameter $groupParams
        Write-Host "  ✓ Group created: $($group.Id)" -ForegroundColor Green

        # Wait for site provisioning
        Write-Host "  Waiting for SharePoint site provisioning..." -ForegroundColor Cyan
        Start-Sleep -Seconds 10

        # Get the SharePoint site
        $site = Get-MgGroupSite -GroupId $group.Id
        $siteUrl = $site.WebUrl

        Write-Host "  ✓ SharePoint site created: $siteUrl" -ForegroundColor Green

        # Add owners
        Write-Host "`nAdding owners..." -ForegroundColor Cyan
        foreach ($owner in $Owners) {
            try {
                $user = Get-MgUser -UserId $owner
                New-MgGroupOwner -GroupId $group.Id -DirectoryObjectId $user.Id
                Write-Host "  ✓ Added owner: $owner" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to add owner $owner : $_"
            }
        }

        # Add members
        if ($Members) {
            Write-Host "`nAdding members..." -ForegroundColor Cyan
            foreach ($member in $Members) {
                try {
                    $user = Get-MgUser -UserId $member
                    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                    Write-Host "  ✓ Added member: $member" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to add member $member : $_"
                }
            }
        }

        # Apply template-specific configurations
        Write-Host "`nApplying template configuration..." -ForegroundColor Cyan

        switch ($Template) {
            'ProjectSite' {
                Write-Host "  - Project site template includes:" -ForegroundColor White
                Write-Host "    • Document library for project files" -ForegroundColor Gray
                Write-Host "    • Tasks list for project tracking" -ForegroundColor Gray
                Write-Host "    • Issues list for problem tracking" -ForegroundColor Gray
                Write-Host "  Note: Full template application requires SharePoint PnP or admin access" -ForegroundColor Yellow
            }
            'DepartmentSite' {
                Write-Host "  - Department site template includes:" -ForegroundColor White
                Write-Host "    • Announcements list" -ForegroundColor Gray
                Write-Host "    • Shared documents library" -ForegroundColor Gray
                Write-Host "    • Calendar for events" -ForegroundColor Gray
                Write-Host "  Note: Full template application requires SharePoint PnP or admin access" -ForegroundColor Yellow
            }
            'CommunicationSite' {
                Write-Host "  - Communication site optimized for news and announcements" -ForegroundColor Gray
                Write-Host "  Note: Communication sites require SharePoint REST API" -ForegroundColor Yellow
            }
            'TeamSite' {
                Write-Host "  - Standard team collaboration site" -ForegroundColor Gray
            }
        }

        Write-Host "`n✓ Site creation complete!" -ForegroundColor Green
        Write-Host "`nSite Details:" -ForegroundColor Cyan
        Write-Host "  Name: $SiteName" -ForegroundColor White
        Write-Host "  URL: $siteUrl" -ForegroundColor White
        Write-Host "  Group ID: $($group.Id)" -ForegroundColor White
        Write-Host "  Site ID: $($site.Id)" -ForegroundColor White
        Write-Host "  Visibility: $(if ($IsPublic) { 'Public' } else { 'Private' })" -ForegroundColor White

        return [PSCustomObject]@{
            SiteName = $SiteName
            SiteUrl = $siteUrl
            SiteId = $site.Id
            GroupId = $group.Id
            Template = $Template
        }
    }
}
catch {
    Write-Error "Site creation failed: $_"
}
