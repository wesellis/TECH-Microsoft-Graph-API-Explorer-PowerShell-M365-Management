<#
.SYNOPSIS
    List all groups in the Microsoft 365 organization.
.DESCRIPTION
    Retrieves and lists all groups with filtering options.
.PARAMETER Filter
    OData filter expression.
.PARAMETER Top
    Number of groups to retrieve. Default is 100.
.PARAMETER SecurityGroupsOnly
    Show only security groups.
.PARAMETER Microsoft365Only
    Show only Microsoft 365 groups.
.PARAMETER ExportPath
    Path to export results to CSV.
.EXAMPLE
    .\list-groups.ps1 -SecurityGroupsOnly
.NOTES
    Required Graph API Permissions: Group.Read.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Filter,
    [Parameter(Mandatory = $false)]
    [int]$Top = 100,
    [Parameter(Mandatory = $false)]
    [switch]$SecurityGroupsOnly,
    [Parameter(Mandatory = $false)]
    [switch]$Microsoft365Only,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    $params = @{
        Top = $Top
        Property = 'id,displayName,description,mail,mailEnabled,securityEnabled,groupTypes,createdDateTime'
    }

    if ($Filter) { $params['Filter'] = $Filter }

    $groups = Get-MgGroup @params

    if ($SecurityGroupsOnly) {
        $groups = $groups | Where-Object { $_.SecurityEnabled -and -not $_.GroupTypes }
    }
    if ($Microsoft365Only) {
        $groups = $groups | Where-Object { $_.GroupTypes -contains 'Unified' }
    }

    $result = $groups | Select-Object DisplayName, Mail, @{N='Type';E={
        if ($_.GroupTypes -contains 'Unified') { 'Microsoft365' }
        elseif ($_.SecurityEnabled) { 'Security' }
        else { 'Distribution' }
    }}, CreatedDateTime

    Write-Host "Found $($result.Count) groups." -ForegroundColor Green

    if ($ExportPath) {
        $result | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "Exported to: $ExportPath" -ForegroundColor Green
    }
    else {
        $result | Format-Table -AutoSize
    }

    return $result
}
catch {
    Write-Error "Failed to retrieve groups: $_"
}
