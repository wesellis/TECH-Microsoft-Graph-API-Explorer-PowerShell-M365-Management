<#
.SYNOPSIS
    Manage SharePoint site and library permissions via Graph API.
.DESCRIPTION
    Grant or remove permissions on SharePoint sites, document libraries,
    and folders. Supports user and group permissions with various roles.
.PARAMETER SiteUrl
    SharePoint site URL.
.PARAMETER ItemPath
    Path to document library or folder (optional, default: site level).
.PARAMETER PrincipalEmail
    Email of user or group to grant/remove permission.
.PARAMETER Role
    Permission role: Read, Write, Owner, or Custom.
.PARAMETER Remove
    Remove permission instead of granting.
.PARAMETER SendInvitation
    Send email invitation to user (default: true).
.EXAMPLE
    .\Set-SharePointPermissions.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/marketing" -PrincipalEmail "user@contoso.com" -Role Write
.EXAMPLE
    .\Set-SharePointPermissions.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/hr" -ItemPath "/Documents/Confidential" -PrincipalEmail "hr-team@contoso.com" -Role Read
.NOTES
    Required Permissions: Sites.FullControl.All, Sites.Manage.All
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SiteUrl,
    [Parameter(Mandatory = $false)]
    [string]$ItemPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PrincipalEmail,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Read', 'Write', 'Owner')]
    [string]$Role = 'Read',
    [Parameter(Mandatory = $false)]
    [switch]$Remove,
    [Parameter(Mandatory = $false)]
    [bool]$SendInvitation = $true
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Managing SharePoint permissions..." -ForegroundColor Cyan
    Write-Host "  Site: $SiteUrl" -ForegroundColor White
    Write-Host "  Principal: $PrincipalEmail" -ForegroundColor White

    # Get site
    $sitePath = $SiteUrl -replace 'https://', ''
    $site = Get-MgSite -Search $sitePath | Select-Object -First 1

    if (-not $site) {
        throw "Site not found: $SiteUrl"
    }

    Write-Host "  Site ID: $($site.Id)" -ForegroundColor Gray

    # Map role to permission type
    $permissionRoles = switch ($Role) {
        'Read' { @('read') }
        'Write' { @('write') }
        'Owner' { @('owner', 'write', 'read') }
    }

    if ($Remove) {
        # Remove permission
        if ($PSCmdlet.ShouldProcess("$PrincipalEmail on $SiteUrl", "Remove $Role permission")) {
            Write-Host "`nRemoving permissions..." -ForegroundColor Yellow

            # Get existing permissions
            $permissions = Get-MgSitePermission -SiteId $site.Id

            # Find permission for this principal
            $targetPermission = $permissions | Where-Object {
                $_.GrantedToIdentitiesV2.User.Email -eq $PrincipalEmail -or
                $_.GrantedToV2.User.Email -eq $PrincipalEmail
            }

            if ($targetPermission) {
                Remove-MgSitePermission -SiteId $site.Id -PermissionId $targetPermission.Id
                Write-Host "✓ Permission removed for: $PrincipalEmail" -ForegroundColor Green
            }
            else {
                Write-Host "No existing permission found for: $PrincipalEmail" -ForegroundColor Yellow
            }
        }
    }
    else {
        # Grant permission
        if ($PSCmdlet.ShouldProcess("$PrincipalEmail on $SiteUrl", "Grant $Role permission")) {
            Write-Host "`nGranting permissions..." -ForegroundColor Cyan

            # Get user/group
            try {
                $principal = Get-MgUser -UserId $PrincipalEmail -ErrorAction SilentlyContinue
                $principalType = "User"
            }
            catch {
                $principal = Get-MgGroup -Filter "mail eq '$PrincipalEmail'" -ErrorAction SilentlyContinue | Select-Object -First 1
                $principalType = "Group"
            }

            if (-not $principal) {
                throw "Principal not found: $PrincipalEmail"
            }

            # Create sharing invitation
            $inviteParams = @{
                Recipients = @(
                    @{
                        Email = $PrincipalEmail
                    }
                )
                RequireSignIn = $true
                SendInvitation = $SendInvitation
                Roles = $permissionRoles
            }

            if ($ItemPath) {
                # Get drive item for specific path
                $drive = Get-MgSiteDrive -SiteId $site.Id | Select-Object -First 1
                $item = Get-MgDriveItem -DriveId $drive.Id -DriveItemId "root:$ItemPath"

                Invoke-MgInviteDriveItem -DriveId $drive.Id -DriveItemId $item.Id -BodyParameter $inviteParams
                Write-Host "✓ Permission granted on: $ItemPath" -ForegroundColor Green
            }
            else {
                # Site-level permission
                Invoke-MgInviteSite -SiteId $site.Id -BodyParameter $inviteParams
                Write-Host "✓ Site-level permission granted" -ForegroundColor Green
            }

            Write-Host "  Principal: $PrincipalEmail ($principalType)" -ForegroundColor Cyan
            Write-Host "  Role: $Role" -ForegroundColor Cyan
            Write-Host "  Invitation Sent: $SendInvitation" -ForegroundColor Cyan
        }
    }
}
catch {
    Write-Error "Permission management failed: $_"
}
