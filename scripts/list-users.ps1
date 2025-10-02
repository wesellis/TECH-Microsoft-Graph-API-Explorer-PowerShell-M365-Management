<#
.SYNOPSIS
    List all users in the Microsoft 365 organization.

.DESCRIPTION
    Retrieves and lists all users from Microsoft Graph API with filtering and output options.
    Supports filtering by department, account status, user type, and more.

.PARAMETER Filter
    OData filter expression to filter users (e.g., "department eq 'IT'").

.PARAMETER Top
    Number of users to retrieve. Default is 100.

.PARAMETER Department
    Filter users by department name.

.PARAMETER EnabledOnly
    Show only enabled accounts.

.PARAMETER DisabledOnly
    Show only disabled accounts.

.PARAMETER ExportPath
    Path to export results to CSV file.

.EXAMPLE
    .\list-users.ps1
    List first 100 users.

.EXAMPLE
    .\list-users.ps1 -Department "IT" -EnabledOnly
    List enabled users in IT department.

.EXAMPLE
    .\list-users.ps1 -Top 500 -ExportPath "C:\users.csv"
    Export first 500 users to CSV.

.NOTES
    Required Graph API Permissions: User.Read.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Filter,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 999)]
    [int]$Top = 100,

    [Parameter(Mandatory = $false)]
    [string]$Department,

    [Parameter(Mandatory = $false)]
    [switch]$EnabledOnly,

    [Parameter(Mandatory = $false)]
    [switch]$DisabledOnly,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

begin {
    # Check if connected to Microsoft Graph
    try {
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-MgGraph first."
        }
    }
    catch {
        Write-Error "Failed to verify Microsoft Graph connection: $_"
        return
    }

    # Build filter expression
    $filterParts = @()
    if ($Filter) { $filterParts += $Filter }
    if ($Department) { $filterParts += "department eq '$Department'" }
    if ($EnabledOnly) { $filterParts += "accountEnabled eq true" }
    if ($DisabledOnly) { $filterParts += "accountEnabled eq false" }

    $finalFilter = $filterParts -join ' and '
}

process {
    try {
        Write-Verbose "Retrieving users from Microsoft Graph..."

        $params = @{
            Top = $Top
            Property = 'id,displayName,userPrincipalName,mail,jobTitle,department,accountEnabled,userType,createdDateTime'
            All = $false
        }

        if ($finalFilter) {
            $params['Filter'] = $finalFilter
            Write-Verbose "Using filter: $finalFilter"
        }

        $users = Get-MgUser @params | Select-Object `
            @{N='DisplayName'; E={$_.DisplayName}},
            @{N='UserPrincipalName'; E={$_.UserPrincipalName}},
            @{N='Mail'; E={$_.Mail}},
            @{N='JobTitle'; E={$_.JobTitle}},
            @{N='Department'; E={$_.Department}},
            @{N='Enabled'; E={$_.AccountEnabled}},
            @{N='UserType'; E={$_.UserType}},
            @{N='CreatedDate'; E={$_.CreatedDateTime}}

        Write-Host "Found $($users.Count) users." -ForegroundColor Green

        if ($ExportPath) {
            $users | Export-Csv -Path $ExportPath -NoTypeInformation
            Write-Host "Exported to: $ExportPath" -ForegroundColor Green
        }
        else {
            $users | Format-Table -AutoSize
        }

        return $users

    }
    catch {
        Write-Error "Failed to retrieve users: $_"
    }
}
