<#
.SYNOPSIS
    Remove a user from a Microsoft 365 group.
.PARAMETER UserId
    User email or ID.
.PARAMETER GroupId
    Group name or ID.
.EXAMPLE
    .\remove-user-from-group.ps1 -UserId "john@contoso.com" -GroupId "IT Department"
.NOTES
    Required Permissions: GroupMember.ReadWrite.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserId,
    [Parameter(Mandatory = $true)]
    [string]$GroupId
)
try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected." }
    
    $user = Get-MgUser -UserId $UserId
    $group = Get-MgGroup -Filter "displayName eq '$GroupId'" | Select-Object -First 1
    if (-not $group) { $group = Get-MgGroup -GroupId $GroupId }
    
    Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id
    Write-Host "✓ Removed $($user.DisplayName) from $($group.DisplayName)" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to remove user from group: $_"
}
