<#
.SYNOPSIS
    Generate comprehensive Microsoft Teams usage report.
.DESCRIPTION
    Lists all Teams with member counts, channels, and activity metrics.
    Helps identify inactive teams and usage patterns.
.PARAMETER IncludeChannels
    Include channel count for each team.
.PARAMETER IncludeMembers
    Include member count for each team.
.PARAMETER MinDaysInactive
    Flag teams with no activity for specified days.
.PARAMETER ExportPath
    Export report to CSV.
.EXAMPLE
    .\Get-TeamsReport.ps1 -IncludeMembers -MinDaysInactive 90 -ExportPath "C:\teams.csv"
.NOTES
    Required Permissions: Team.ReadBasic.All, Channel.ReadBasic.All, TeamMember.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeChannels,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeMembers,
    [Parameter(Mandatory = $false)]
    [int]$MinDaysInactive,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating Teams report..." -ForegroundColor Cyan

    # Get all teams (teams are groups with 'Team' resource provisioned)
    $teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All `
        -Property 'id,displayName,description,mail,createdDateTime,visibility'

    $report = $teams | ForEach-Object {
        $team = $_

        $teamInfo = [PSCustomObject]@{
            TeamName = $team.DisplayName
            Description = $team.Description
            Email = $team.Mail
            Visibility = $team.Visibility
            CreatedDate = $team.CreatedDateTime
        }

        # Get member count if requested
        if ($IncludeMembers) {
            try {
                $members = Get-MgGroupMember -GroupId $team.Id -All
                $teamInfo | Add-Member -MemberType NoteProperty -Name 'MemberCount' -Value $members.Count
            } catch {
                $teamInfo | Add-Member -MemberType NoteProperty -Name 'MemberCount' -Value 0
            }
        }

        # Get channel count if requested
        if ($IncludeChannels) {
            try {
                $channels = Get-MgTeamChannel -TeamId $team.Id
                $teamInfo | Add-Member -MemberType NoteProperty -Name 'ChannelCount' -Value $channels.Count
            } catch {
                $teamInfo | Add-Member -MemberType NoteProperty -Name 'ChannelCount' -Value 0
            }
        }

        # Check for inactivity if specified
        if ($MinDaysInactive) {
            $daysSinceCreation = ((Get-Date) - $team.CreatedDateTime).Days
            $inactive = $daysSinceCreation -gt $MinDaysInactive
            $teamInfo | Add-Member -MemberType NoteProperty -Name 'Inactive' -Value $inactive
            $teamInfo | Add-Member -MemberType NoteProperty -Name 'DaysSinceCreated' -Value $daysSinceCreation
        }

        $teamInfo
    }

    Write-Host "`n✓ Found $($report.Count) teams" -ForegroundColor Green

    if ($MinDaysInactive) {
        $inactiveCount = ($report | Where-Object { $_.Inactive }).Count
        Write-Host "  Inactive Teams ($MinDaysInactive+ days): $inactiveCount" -ForegroundColor Yellow
    }

    if ($ExportPath) {
        $report | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Format-Table -AutoSize
    }

    return $report
}
catch {
    Write-Error "Failed to generate Teams report: $_"
}
