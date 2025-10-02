<#
.SYNOPSIS
    Generate comprehensive group membership report.
.DESCRIPTION
    Lists all groups with member counts, types, and optionally exports
    detailed membership for each group.
.PARAMETER IncludeMembers
    Include detailed member list for each group.
.PARAMETER GroupType
    Filter by group type: All, Security, Microsoft365, Distribution.
.PARAMETER ExportPath
    Export report to CSV.
.EXAMPLE
    .\Get-GroupMembershipReport.ps1 -IncludeMembers -ExportPath "C:\Reports\groups.csv"
.NOTES
    Required Permissions: Group.Read.All, GroupMember.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeMembers,
    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Security', 'Microsoft365', 'Distribution')]
    [string]$GroupType = 'All',
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating group membership report..." -ForegroundColor Cyan

    # Get all groups
    $groups = Get-MgGroup -All -Property 'id,displayName,description,mail,groupTypes,securityEnabled,mailEnabled,createdDateTime'

    # Filter by type if specified
    if ($GroupType -ne 'All') {
        $groups = $groups | Where-Object {
            switch ($GroupType) {
                'Security' { $_.SecurityEnabled -and -not $_.GroupTypes }
                'Microsoft365' { $_.GroupTypes -contains 'Unified' }
                'Distribution' { $_.MailEnabled -and -not $_.SecurityEnabled -and -not $_.GroupTypes }
            }
        }
    }

    $report = $groups | ForEach-Object {
        $group = $_

        # Get member count
        try {
            $members = Get-MgGroupMember -GroupId $group.Id -All
            $memberCount = $members.Count
        } catch {
            $memberCount = 0
        }

        $groupInfo = [PSCustomObject]@{
            GroupName = $group.DisplayName
            Email = $group.Mail
            Type = if ($group.GroupTypes -contains 'Unified') { 'Microsoft365' }
                   elseif ($group.SecurityEnabled) { 'Security' }
                   else { 'Distribution' }
            MemberCount = $memberCount
            Description = $group.Description
            CreatedDate = $group.CreatedDateTime
        }

        # Add member details if requested
        if ($IncludeMembers -and $memberCount -gt 0) {
            $memberList = $members | ForEach-Object {
                try {
                    $user = Get-MgUser -UserId $_.Id -Property 'displayName,userPrincipalName' -ErrorAction SilentlyContinue
                    if ($user) { $user.DisplayName }
                } catch { }
            }
            $groupInfo | Add-Member -MemberType NoteProperty -Name 'Members' -Value ($memberList -join '; ')
        }

        $groupInfo
    }

    Write-Host "`n✓ Found $($report.Count) groups" -ForegroundColor Green
    Write-Host "  Total Members: $(($report | Measure-Object MemberCount -Sum).Sum)" -ForegroundColor Cyan

    if ($ExportPath) {
        $report | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Format-Table -AutoSize
    }

    return $report
}
catch {
    Write-Error "Failed to generate group membership report: $_"
}
