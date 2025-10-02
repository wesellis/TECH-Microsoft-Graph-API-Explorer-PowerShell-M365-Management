<#
.SYNOPSIS
    Bulk update user properties from CSV file.
.DESCRIPTION
    Updates multiple user properties in bulk by importing from CSV file.
    Supports department, job title, location, phone numbers, and more.
.PARAMETER CsvPath
    Path to CSV file with user data. Must include UserPrincipalName column.
.PARAMETER WhatIf
    Show what would be changed without making actual changes.
.EXAMPLE
    .\Update-UserProperties.ps1 -CsvPath "C:\users.csv"

    CSV Format:
    UserPrincipalName,Department,JobTitle,OfficeLocation,MobilePhone
    john@contoso.com,IT,Manager,Building A,555-1234
.NOTES
    Required Permissions: User.ReadWrite.All
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]$CsvPath,
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Importing user data from CSV..." -ForegroundColor Cyan
    $users = Import-Csv -Path $CsvPath

    if (-not $users[0].UserPrincipalName) {
        throw "CSV must contain UserPrincipalName column"
    }

    $successCount = 0
    $failCount = 0
    $total = $users.Count

    Write-Host "Processing $total users..." -ForegroundColor Cyan

    foreach ($userData in $users) {
        try {
            $upn = $userData.UserPrincipalName

            # Verify user exists
            $user = Get-MgUser -UserId $upn -Property 'id,displayName' -ErrorAction Stop

            # Build update parameters
            $updateParams = @{}

            if ($userData.DisplayName) { $updateParams['DisplayName'] = $userData.DisplayName }
            if ($userData.Department) { $updateParams['Department'] = $userData.Department }
            if ($userData.JobTitle) { $updateParams['JobTitle'] = $userData.JobTitle }
            if ($userData.OfficeLocation) { $updateParams['OfficeLocation'] = $userData.OfficeLocation }
            if ($userData.MobilePhone) { $updateParams['MobilePhone'] = $userData.MobilePhone }
            if ($userData.City) { $updateParams['City'] = $userData.City }
            if ($userData.State) { $updateParams['State'] = $userData.State }
            if ($userData.Country) { $updateParams['Country'] = $userData.Country }
            if ($userData.PostalCode) { $updateParams['PostalCode'] = $userData.PostalCode }
            if ($userData.StreetAddress) { $updateParams['StreetAddress'] = $userData.StreetAddress }
            if ($userData.CompanyName) { $updateParams['CompanyName'] = $userData.CompanyName }

            if ($updateParams.Count -gt 0) {
                if ($WhatIf) {
                    Write-Host "[WHATIF] Would update $($user.DisplayName): $($updateParams.Keys -join ', ')" -ForegroundColor Yellow
                }
                elseif ($PSCmdlet.ShouldProcess($upn, "Update user properties")) {
                    Update-MgUser -UserId $upn -BodyParameter $updateParams
                    Write-Host "✓ Updated: $($user.DisplayName)" -ForegroundColor Green
                    $successCount++
                }
            } else {
                Write-Verbose "No updates needed for $upn"
            }
        }
        catch {
            Write-Warning "Failed to update $upn : $_"
            $failCount++
        }
    }

    Write-Host "`n=== Bulk Update Summary ===" -ForegroundColor Cyan
    Write-Host "Total Users: $total" -ForegroundColor White
    Write-Host "Successfully Updated: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor Red
}
catch {
    Write-Error "Bulk update failed: $_"
}
