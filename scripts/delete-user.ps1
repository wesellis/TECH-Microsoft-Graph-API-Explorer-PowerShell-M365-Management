<#
.SYNOPSIS
    Delete a user from Microsoft 365.
.DESCRIPTION
    Permanently deletes a user account from Azure AD.
.PARAMETER UserId
    The UserPrincipalName or ObjectId of the user to delete.
.PARAMETER Force
    Skip confirmation prompt.
.EXAMPLE
    .\delete-user.ps1 -UserId "john@contoso.com"
.NOTES
    Required Graph API Permissions: User.ReadWrite.All
    WARNING: This action is permanent and cannot be undone.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserId,
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    $user = Get-MgUser -UserId $UserId -Property 'displayName,userPrincipalName'

    if ($Force -or $PSCmdlet.ShouldProcess($user.UserPrincipalName, "Delete user")) {
        Remove-MgUser -UserId $UserId
        Write-Host "✓ User deleted: $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Failed to delete user: $_"
}
