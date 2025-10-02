<#
.SYNOPSIS
    Update user properties in Microsoft 365.
.DESCRIPTION
    Updates user properties in Azure AD including department, job title, phone numbers, and more.
.PARAMETER UserId
    The UserPrincipalName or ObjectId of the user to update.
.PARAMETER DisplayName
    New display name for the user.
.PARAMETER Department
    New department assignment.
.PARAMETER JobTitle
    New job title.
.PARAMETER OfficeLocation
    New office location.
.PARAMETER MobilePhone
    New mobile phone number.
.PARAMETER BusinessPhones
    Array of business phone numbers.
.PARAMETER Enable
    Enable the user account.
.PARAMETER Disable
    Disable the user account.
.EXAMPLE
    .\update-user.ps1 -UserId "john@contoso.com" -Department "Sales" -JobTitle "Sales Manager"
.NOTES
    Required Graph API Permissions: User.ReadWrite.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserId,
    [Parameter(Mandatory = $false)]
    [string]$DisplayName,
    [Parameter(Mandatory = $false)]
    [string]$Department,
    [Parameter(Mandatory = $false)]
    [string]$JobTitle,
    [Parameter(Mandatory = $false)]
    [string]$OfficeLocation,
    [Parameter(Mandatory = $false)]
    [string]$MobilePhone,
    [Parameter(Mandatory = $false)]
    [string[]]$BusinessPhones,
    [Parameter(Mandatory = $false)]
    [switch]$Enable,
    [Parameter(Mandatory = $false)]
    [switch]$Disable
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph. Run Connect-MgGraph first." }

    $updateParams = @{}
    if ($DisplayName) { $updateParams['DisplayName'] = $DisplayName }
    if ($Department) { $updateParams['Department'] = $Department }
    if ($JobTitle) { $updateParams['JobTitle'] = $JobTitle }
    if ($OfficeLocation) { $updateParams['OfficeLocation'] = $OfficeLocation }
    if ($MobilePhone) { $updateParams['MobilePhone'] = $MobilePhone }
    if ($BusinessPhones) { $updateParams['BusinessPhones'] = $BusinessPhones }
    if ($Enable) { $updateParams['AccountEnabled'] = $true }
    if ($Disable) { $updateParams['AccountEnabled'] = $false }

    if ($updateParams.Count -eq 0) {
        Write-Warning "No update parameters provided."
        return
    }

    Update-MgUser -UserId $UserId -BodyParameter $updateParams
    Write-Host "✓ User updated successfully!" -ForegroundColor Green

    $updatedUser = Get-MgUser -UserId $UserId -Property 'displayName,userPrincipalName,department,jobTitle'
    return $updatedUser
}
catch {
    Write-Error "Failed to update user: $_"
}
