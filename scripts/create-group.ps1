<#
.SYNOPSIS
    Create a new group in Microsoft 365.
.DESCRIPTION
    Creates a new security group or Microsoft 365 group in Azure AD.
.PARAMETER DisplayName
    The display name for the group.
.PARAMETER MailNickname
    The mail nickname (alias) for the group.
.PARAMETER Description
    Description of the group's purpose.
.PARAMETER GroupType
    Type of group: Security or Microsoft365.
.PARAMETER MailEnabled
    Enable email for the group.
.PARAMETER SecurityEnabled
    Enable security features for the group.
.EXAMPLE
    .\create-group.ps1 -DisplayName "IT Department" -MailNickname "it-dept" -GroupType Security
.NOTES
    Required Graph API Permissions: Group.ReadWrite.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DisplayName,
    [Parameter(Mandatory = $true)]
    [string]$MailNickname,
    [Parameter(Mandatory = $false)]
    [string]$Description,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Security', 'Microsoft365')]
    [string]$GroupType = 'Security',
    [Parameter(Mandatory = $false)]
    [bool]$MailEnabled = $false,
    [Parameter(Mandatory = $false)]
    [bool]$SecurityEnabled = $true
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    $groupParams = @{
        DisplayName = $DisplayName
        MailNickname = $MailNickname
        MailEnabled = $MailEnabled
        SecurityEnabled = $SecurityEnabled
    }

    if ($Description) { $groupParams['Description'] = $Description }

    if ($GroupType -eq 'Microsoft365') {
        $groupParams['GroupTypes'] = @('Unified')
        $groupParams['MailEnabled'] = $true
    }

    $newGroup = New-MgGroup -BodyParameter $groupParams
    Write-Host "✓ Group created successfully!" -ForegroundColor Green
    Write-Host "  Display Name: $DisplayName" -ForegroundColor Cyan
    Write-Host "  Group ID: $($newGroup.Id)" -ForegroundColor Cyan

    return $newGroup
}
catch {
    Write-Error "Failed to create group: $_"
}
