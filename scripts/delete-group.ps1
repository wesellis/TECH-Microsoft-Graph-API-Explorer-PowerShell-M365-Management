<#
.SYNOPSIS
    Delete a Microsoft 365 group.
.PARAMETER GroupId
    Group name or ID.
.PARAMETER Force
    Skip confirmation.
.EXAMPLE
    .\delete-group.ps1 -GroupId "Old Project Team"
.NOTES
    Required Permissions: Group.ReadWrite.All
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$GroupId,
    [Parameter(Mandatory = $false)]
    [switch]$Force
)
try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected." }
    
    $group = Get-MgGroup -Filter "displayName eq '$GroupId'" | Select-Object -First 1
    if (-not $group) { $group = Get-MgGroup -GroupId $GroupId }
    
    if ($Force -or $PSCmdlet.ShouldProcess($group.DisplayName, "Delete group")) {
        Remove-MgGroup -GroupId $group.Id
        Write-Host "✓ Group deleted: $($group.DisplayName)" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Failed to delete group: $_"
}
