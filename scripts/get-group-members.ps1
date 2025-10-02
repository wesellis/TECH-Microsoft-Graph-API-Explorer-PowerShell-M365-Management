<#
.SYNOPSIS
    Get members of a Microsoft 365 group.
.PARAMETER GroupId
    The Group ID or display name.
.PARAMETER ExportPath
    Export members to CSV.
.EXAMPLE
    .\get-group-members.ps1 -GroupId "IT Department"
.NOTES
    Required Permissions: GroupMember.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GroupId,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)
try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected. Run Connect-MgGraph." }
    
    $group = Get-MgGroup -Filter "displayName eq '$GroupId'" | Select-Object -First 1
    if (-not $group) { $group = Get-MgGroup -GroupId $GroupId }
    
    $members = Get-MgGroupMember -GroupId $group.Id -All
    $result = $members | ForEach-Object {
        $user = Get-MgUser -UserId $_.Id -Property 'displayName,userPrincipalName,jobTitle,department' -ErrorAction SilentlyContinue
        if ($user) {
            [PSCustomObject]@{
                DisplayName = $user.DisplayName
                Email = $user.UserPrincipalName
                JobTitle = $user.JobTitle
                Department = $user.Department
            }
        }
    }
    
    Write-Host "Found $($result.Count) members in group: $($group.DisplayName)" -ForegroundColor Green
    
    if ($ExportPath) {
        $result | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "Exported to: $ExportPath" -ForegroundColor Cyan
    } else {
        $result | Format-Table -AutoSize
    }
    return $result
}
catch {
    Write-Error "Failed to get group members: $_"
}
