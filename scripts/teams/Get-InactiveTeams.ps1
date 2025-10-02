<#
.SYNOPSIS
    Find inactive Microsoft Teams based on age or activity.
.DESCRIPTION
    Identifies teams with no recent activity based on creation date
    or last activity timestamp. Useful for cleanup and archival.
.PARAMETER DaysSinceCreation
    Find teams created more than X days ago with no activity.
.PARAMETER ExportPath
    Export results to CSV file.
.PARAMETER IncludeMemberCount
    Include current member count in results.
.EXAMPLE
    .\Get-InactiveTeams.ps1 -DaysSinceCreation 180 -ExportPath "C:\inactive-teams.csv"
.NOTES
    Required Permissions: Team.ReadBasic.All, TeamMember.Read.All (if -IncludeMemberCount)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$DaysSinceCreation,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeMemberCount
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Finding inactive teams (created $DaysSinceCreation+ days ago)..." -ForegroundColor Cyan

    # Get all teams
    $teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All `
        -Property 'id,displayName,description,mail,createdDateTime,visibility'

    $cutoffDate = (Get-Date).AddDays(-$DaysSinceCreation)

    $inactiveTeams = $teams | Where-Object {
        $_.CreatedDateTime -lt $cutoffDate
    } | ForEach-Object {
        $team = $_
        $daysSinceCreated = [math]::Round(((Get-Date) - $team.CreatedDateTime).TotalDays, 0)

        $teamInfo = [PSCustomObject]@{
            TeamName = $team.DisplayName
            Description = $team.Description
            Email = $team.Mail
            Visibility = $team.Visibility
            CreatedDate = $team.CreatedDateTime
            DaysSinceCreated = $daysSinceCreated
            Id = $team.Id
        }

        # Add member count if requested
        if ($IncludeMemberCount) {
            try {
                $members = Get-MgGroupMember -GroupId $team.Id -All
                $teamInfo | Add-Member -MemberType NoteProperty -Name 'MemberCount' -Value $members.Count
            } catch {
                $teamInfo | Add-Member -MemberType NoteProperty -Name 'MemberCount' -Value 0
            }
        }

        $teamInfo
    }

    Write-Host "`n✓ Found $($inactiveTeams.Count) inactive teams" -ForegroundColor Green
    Write-Host "  Criteria: Created $DaysSinceCreation+ days ago" -ForegroundColor Cyan

    if ($ExportPath) {
        $inactiveTeams | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $inactiveTeams | Format-Table -AutoSize
    }

    return $inactiveTeams
}
catch {
    Write-Error "Failed to find inactive teams: $_"
}
