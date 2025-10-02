<#
.SYNOPSIS
    Create a new Microsoft Team with specified settings.
.DESCRIPTION
    Creates a new Team with customizable settings including visibility,
    members, owners, and channels. Supports template-based creation.
.PARAMETER DisplayName
    Name of the team.
.PARAMETER Description
    Team description.
.PARAMETER Visibility
    Team visibility: Public or Private. Default is Private.
.PARAMETER Owners
    Array of user UPNs or IDs to add as team owners.
.PARAMETER Members
    Array of user UPNs or IDs to add as team members.
.PARAMETER CreateDefaultChannels
    Create default General channel only (default) or skip.
.PARAMETER AllowGuestAccess
    Allow guest users to join the team.
.EXAMPLE
    .\New-GraphTeam.ps1 -DisplayName "Project Alpha" -Description "Q1 Project Team" -Owners "admin@contoso.com" -Members "user1@contoso.com","user2@contoso.com"
.NOTES
    Required Permissions: Team.Create, TeamMember.ReadWrite.All, Group.ReadWrite.All
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,
    [Parameter(Mandatory = $false)]
    [string]$Description,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Public', 'Private')]
    [string]$Visibility = 'Private',
    [Parameter(Mandatory = $false)]
    [string[]]$Owners,
    [Parameter(Mandatory = $false)]
    [string[]]$Members,
    [Parameter(Mandatory = $false)]
    [switch]$AllowGuestAccess
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    if ($PSCmdlet.ShouldProcess($DisplayName, "Create new Team")) {
        Write-Host "Creating team: $DisplayName..." -ForegroundColor Cyan

        # Build team parameters
        $teamParams = @{
            DisplayName = $DisplayName
            Description = $Description
            Visibility = $Visibility
            AdditionalProperties = @{
                'template@odata.bind' = "https://graph.microsoft.com/v1.0/teamsTemplates('standard')"
            }
        }

        # Create the group first
        $group = New-MgGroup -DisplayName $DisplayName `
            -Description $Description `
            -MailEnabled:$true `
            -MailNickname ($DisplayName -replace '\s','') `
            -SecurityEnabled:$false `
            -GroupTypes @("Unified") `
            -Visibility $Visibility

        Write-Host "  Group created: $($group.Id)" -ForegroundColor Green

        # Wait for group provisioning
        Start-Sleep -Seconds 5

        # Create team from group
        $team = New-MgTeam -GroupId $group.Id `
            -DisplayName $DisplayName `
            -Description $Description `
            -GuestSettings @{
                AllowCreateUpdateChannels = $AllowGuestAccess
                AllowDeleteChannels = $false
            }

        Write-Host "  Team created: $($team.Id)" -ForegroundColor Green

        # Add owners
        if ($Owners) {
            Write-Host "  Adding $($Owners.Count) owner(s)..." -ForegroundColor Cyan
            foreach ($owner in $Owners) {
                try {
                    $user = Get-MgUser -UserId $owner
                    New-MgGroupOwner -GroupId $group.Id -DirectoryObjectId $user.Id
                    Write-Host "    ✓ Added owner: $owner" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to add owner $owner : $_"
                }
            }
        }

        # Add members
        if ($Members) {
            Write-Host "  Adding $($Members.Count) member(s)..." -ForegroundColor Cyan
            foreach ($member in $Members) {
                try {
                    $user = Get-MgUser -UserId $member
                    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                    Write-Host "    ✓ Added member: $member" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to add member $member : $_"
                }
            }
        }

        Write-Host "`n✓ Team created successfully!" -ForegroundColor Green
        Write-Host "  Name: $DisplayName" -ForegroundColor Cyan
        Write-Host "  Team ID: $($team.Id)" -ForegroundColor Cyan
        Write-Host "  Group ID: $($group.Id)" -ForegroundColor Cyan
        Write-Host "  Visibility: $Visibility" -ForegroundColor Cyan

        return $team
    }
}
catch {
    Write-Error "Failed to create team: $_"
}
