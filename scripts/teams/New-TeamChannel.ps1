<#
.SYNOPSIS
    Create a new channel in a Microsoft Team.
.DESCRIPTION
    Creates standard or private channels with customizable settings.
    Supports adding members to private channels.
.PARAMETER TeamId
    The ID of the team where the channel will be created.
.PARAMETER DisplayName
    Name of the channel.
.PARAMETER Description
    Channel description.
.PARAMETER ChannelType
    Channel type: Standard or Private. Default is Standard.
.PARAMETER Members
    Array of user UPNs to add to private channel.
.EXAMPLE
    .\New-TeamChannel.ps1 -TeamId "abc123" -DisplayName "Marketing" -Description "Marketing discussions"
.EXAMPLE
    .\New-TeamChannel.ps1 -TeamId "abc123" -DisplayName "Private Project" -ChannelType Private -Members "user1@contoso.com","user2@contoso.com"
.NOTES
    Required Permissions: Channel.Create, ChannelMember.ReadWrite.All (for private channels)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TeamId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,
    [Parameter(Mandatory = $false)]
    [string]$Description,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Standard', 'Private')]
    [string]$ChannelType = 'Standard',
    [Parameter(Mandatory = $false)]
    [string[]]$Members
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    # Get team info
    $team = Get-MgTeam -TeamId $TeamId

    if ($PSCmdlet.ShouldProcess("$($team.DisplayName) - $DisplayName", "Create channel")) {
        Write-Host "Creating channel in team: $($team.DisplayName)..." -ForegroundColor Cyan

        $channelParams = @{
            DisplayName = $DisplayName
            Description = $Description
            MembershipType = $ChannelType.ToLower()
        }

        $channel = New-MgTeamChannel -TeamId $TeamId -BodyParameter $channelParams

        Write-Host "✓ Channel created successfully!" -ForegroundColor Green
        Write-Host "  Channel: $DisplayName" -ForegroundColor Cyan
        Write-Host "  Type: $ChannelType" -ForegroundColor Cyan
        Write-Host "  Channel ID: $($channel.Id)" -ForegroundColor Cyan

        # Add members to private channel
        if ($ChannelType -eq 'Private' -and $Members) {
            Write-Host "`n  Adding $($Members.Count) member(s) to private channel..." -ForegroundColor Cyan
            foreach ($member in $Members) {
                try {
                    $user = Get-MgUser -UserId $member

                    $membershipParams = @{
                        '@odata.type' = '#microsoft.graph.aadUserConversationMember'
                        Roles = @('member')
                        'User@odata.bind' = "https://graph.microsoft.com/v1.0/users('$($user.Id)')"
                    }

                    New-MgTeamChannelMember -TeamId $TeamId -ChannelId $channel.Id -BodyParameter $membershipParams
                    Write-Host "    ✓ Added: $member" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to add member $member : $_"
                }
            }
        }

        return $channel
    }
}
catch {
    Write-Error "Failed to create channel: $_"
}
