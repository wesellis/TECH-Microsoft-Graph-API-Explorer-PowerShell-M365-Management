<#
.SYNOPSIS
    Add a user to a Microsoft 365 group.
.PARAMETER UserId
    User email or ID.
.PARAMETER GroupId
    Group name or ID.
.EXAMPLE
    .\add-user-to-group.ps1 -UserId "john@contoso.com" -GroupId "IT Department"
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
    
    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
    Write-Host "✓ Added $($user.DisplayName) to $($group.DisplayName)" -ForegroundColor Green
}
catch {
    Write-Error "Failed to add user to group: $_"
}
