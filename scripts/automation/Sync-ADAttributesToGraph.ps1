<#
.SYNOPSIS
    Sync on-premises Active Directory attributes to Azure AD via Graph API.
.DESCRIPTION
    Synchronizes specified user attributes from on-prem AD to Azure AD/M365.
    Useful for hybrid environments where AD Connect doesn't sync certain attributes.
.PARAMETER ADServerName
    On-premises AD server to query.
.PARAMETER Attributes
    Array of attribute names to sync (e.g., 'telephoneNumber', 'department', 'title').
.PARAMETER UserFilter
    LDAP filter for selecting AD users (default: all enabled users).
.PARAMETER WhatIf
    Preview changes without applying them.
.PARAMETER ExportReport
    Export sync results to CSV file.
.EXAMPLE
    .\Sync-ADAttributesToGraph.ps1 -ADServerName "dc01.contoso.com" -Attributes "department","title" -WhatIf
.EXAMPLE
    .\Sync-ADAttributesToGraph.ps1 -ADServerName "dc01" -Attributes "telephoneNumber" -UserFilter "(department=IT)" -ExportReport "C:\sync-results.csv"
.NOTES
    Required Permissions: User.ReadWrite.All, Directory.ReadWrite.All
    Required Modules: ActiveDirectory, Microsoft.Graph
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ADServerName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Attributes,
    [Parameter(Mandatory = $false)]
    [string]$UserFilter = "(&(objectClass=user)(objectCategory=person)(!userAccountControl:1.2.840.113556.1.4.803:=2))",
    [Parameter(Mandatory = $false)]
    [string]$ExportReport
)

begin {
    try {
        # Check Graph connection
        $context = Get-MgContext
        if (-not $context) { throw "Not connected to Microsoft Graph." }

        # Check AD module
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            throw "ActiveDirectory module not found. Install with: Install-WindowsFeature RSAT-AD-PowerShell"
        }
        Import-Module ActiveDirectory

        Write-Host "=== AD to Graph Attribute Sync ===" -ForegroundColor Cyan
        Write-Host "AD Server: $ADServerName" -ForegroundColor White
        Write-Host "Attributes: $($Attributes -join ', ')" -ForegroundColor White
        Write-Host ""

        $syncResults = @()
        $successCount = 0
        $failureCount = 0
        $unchangedCount = 0
    }
    catch {
        Write-Error "Initialization failed: $_"
        return
    }
}

process {
    try {
        # Get AD users with specified attributes
        Write-Host "Retrieving users from Active Directory..." -ForegroundColor Cyan

        $adUsers = Get-ADUser -Server $ADServerName -LDAPFilter $UserFilter `
            -Properties ($Attributes + @('mail', 'userPrincipalName'))

        Write-Host "  Found $($adUsers.Count) AD users" -ForegroundColor Green

        # Process each user
        foreach ($adUser in $adUsers) {
            $upn = $adUser.UserPrincipalName

            Write-Progress -Activity "Syncing AD attributes" -Status $upn `
                -PercentComplete (([array]::IndexOf($adUsers, $adUser) / $adUsers.Count) * 100)

            try {
                # Get corresponding Azure AD user
                $azureUser = Get-MgUser -UserId $upn -ErrorAction Stop

                # Build update parameters
                $updateParams = @{}
                $changedAttributes = @()

                foreach ($attr in $Attributes) {
                    $adValue = $adUser.$attr

                    # Map AD attribute to Graph property
                    $graphProperty = switch ($attr) {
                        'telephoneNumber' { 'BusinessPhones' }
                        'mobile' { 'MobilePhone' }
                        'title' { 'JobTitle' }
                        'department' { 'Department' }
                        'company' { 'CompanyName' }
                        'streetAddress' { 'StreetAddress' }
                        'city' { 'City' }
                        'state' { 'State' }
                        'postalCode' { 'PostalCode' }
                        'country' { 'Country' }
                        'manager' { 'Manager' }
                        default { $attr }
                    }

                    # Get current Azure AD value
                    $azureValue = $azureUser.$graphProperty

                    # Check if value differs
                    if ($graphProperty -eq 'BusinessPhones') {
                        # BusinessPhones is an array
                        if ($adValue -and ($null -eq $azureValue -or $azureValue[0] -ne $adValue)) {
                            $updateParams[$graphProperty] = @($adValue)
                            $changedAttributes += "$graphProperty ($adValue)"
                        }
                    }
                    else {
                        if ($adValue -ne $azureValue) {
                            $updateParams[$graphProperty] = $adValue
                            $changedAttributes += "$graphProperty ($adValue)"
                        }
                    }
                }

                # Apply updates if changes detected
                if ($updateParams.Count -gt 0) {
                    if ($PSCmdlet.ShouldProcess($upn, "Update attributes: $($changedAttributes -join ', ')")) {
                        Update-MgUser -UserId $azureUser.Id -BodyParameter $updateParams
                        Write-Host "  ✓ Synced: $upn - $($changedAttributes -join ', ')" -ForegroundColor Green
                        $successCount++

                        $syncResults += [PSCustomObject]@{
                            UserPrincipalName = $upn
                            Status = 'Success'
                            ChangedAttributes = $changedAttributes -join '; '
                            Error = $null
                        }
                    }
                }
                else {
                    Write-Host "  - Unchanged: $upn" -ForegroundColor Gray
                    $unchangedCount++

                    $syncResults += [PSCustomObject]@{
                        UserPrincipalName = $upn
                        Status = 'Unchanged'
                        ChangedAttributes = $null
                        Error = $null
                    }
                }
            }
            catch {
                Write-Warning "Failed to sync $upn : $_"
                $failureCount++

                $syncResults += [PSCustomObject]@{
                    UserPrincipalName = $upn
                    Status = 'Failed'
                    ChangedAttributes = $null
                    Error = $_.Exception.Message
                }
            }
        }

        Write-Progress -Activity "Syncing AD attributes" -Completed
    }
    catch {
        Write-Error "Sync process failed: $_"
    }
}

end {
    Write-Host "`n=== Sync Summary ===" -ForegroundColor Cyan
    Write-Host "  Total Users: $($adUsers.Count)" -ForegroundColor White
    Write-Host "  Synced Successfully: $successCount" -ForegroundColor Green
    Write-Host "  Unchanged: $unchangedCount" -ForegroundColor Gray
    Write-Host "  Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { 'Red' } else { 'Green' })

    if ($ExportReport) {
        $syncResults | Export-Csv -Path $ExportReport -NoTypeInformation
        Write-Host "`n✓ Sync report exported to: $ExportReport" -ForegroundColor Green
    }

    return $syncResults
}
