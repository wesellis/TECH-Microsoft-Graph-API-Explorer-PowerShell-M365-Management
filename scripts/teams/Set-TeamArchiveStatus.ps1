<#
.SYNOPSIS
    Archive or unarchive Microsoft Teams.
.DESCRIPTION
    Archives teams to preserve content while preventing new activity,
    or unarchives teams to restore full functionality.
.PARAMETER TeamId
    The ID of the team to archive/unarchive.
.PARAMETER Archive
    Archive the team.
.PARAMETER Unarchive
    Unarchive the team.
.PARAMETER SetReadOnly
    When archiving, set team to read-only (default: true).
.EXAMPLE
    .\Set-TeamArchiveStatus.ps1 -TeamId "abc123" -Archive
.EXAMPLE
    Get-InactiveTeams -Days 180 | Set-TeamArchiveStatus -Archive
.NOTES
    Required Permissions: Team.ReadWrite.All, TeamSettings.ReadWrite.All
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Archive')]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('Id')]
    [ValidateNotNullOrEmpty()]
    [string]$TeamId,
    [Parameter(Mandatory = $true, ParameterSetName = 'Archive')]
    [switch]$Archive,
    [Parameter(Mandatory = $true, ParameterSetName = 'Unarchive')]
    [switch]$Unarchive,
    [Parameter(Mandatory = $false, ParameterSetName = 'Archive')]
    [bool]$SetReadOnly = $true
)

begin {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }
}

process {
    try {
        # Get team details
        $team = Get-MgTeam -TeamId $TeamId

        if ($Archive) {
            if ($PSCmdlet.ShouldProcess($team.DisplayName, "Archive Team")) {
                Write-Host "Archiving team: $($team.DisplayName)..." -ForegroundColor Cyan

                $archiveParams = @{
                    ShouldSetSpoSiteReadOnlyForMembers = $SetReadOnly
                }

                Invoke-MgArchiveTeam -TeamId $TeamId -BodyParameter $archiveParams

                Write-Host "✓ Team archived successfully" -ForegroundColor Green
                Write-Host "  Team: $($team.DisplayName)" -ForegroundColor Cyan
                Write-Host "  ID: $TeamId" -ForegroundColor Cyan
                Write-Host "  Read-Only: $SetReadOnly" -ForegroundColor Cyan
            }
        }

        if ($Unarchive) {
            if ($PSCmdlet.ShouldProcess($team.DisplayName, "Unarchive Team")) {
                Write-Host "Unarchiving team: $($team.DisplayName)..." -ForegroundColor Cyan

                Invoke-MgUnarchiveTeam -TeamId $TeamId

                Write-Host "✓ Team unarchived successfully" -ForegroundColor Green
                Write-Host "  Team: $($team.DisplayName)" -ForegroundColor Cyan
                Write-Host "  ID: $TeamId" -ForegroundColor Cyan
            }
        }
    }
    catch {
        Write-Error "Failed to change archive status for team $TeamId : $_"
    }
}
