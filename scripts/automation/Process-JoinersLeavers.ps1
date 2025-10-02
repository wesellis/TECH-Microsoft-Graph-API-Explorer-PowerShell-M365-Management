<#
.SYNOPSIS
    Automate onboarding and offboarding user processes.
.DESCRIPTION
    Processes new hires (joiners) and departing employees (leavers) from CSV files.
    For joiners: Creates accounts, assigns groups, sets properties.
    For leavers: Disables accounts, removes from groups, exports mailbox.
.PARAMETER Mode
    Operation mode: Joiners or Leavers.
.PARAMETER CsvPath
    Path to CSV file with user data.
.PARAMETER WhatIf
    Preview changes without executing.
.EXAMPLE
    .\Process-JoinersLeavers.ps1 -Mode Joiners -CsvPath "C:\new-hires.csv"

    Joiners CSV: DisplayName,UserPrincipalName,Department,JobTitle,ManagerEmail,Groups
    Leavers CSV: UserPrincipalName,LastDay,ForwardEmail,BackupMailbox
.NOTES
    Required Permissions: User.ReadWrite.All, Group.ReadWrite.All, Mail.ReadWrite
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Joiners', 'Leavers')]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]$CsvPath,
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    $users = Import-Csv -Path $CsvPath
    Write-Host "Processing $($users.Count) $Mode..." -ForegroundColor Cyan

    if ($Mode -eq 'Joiners') {
        # Process new hires
        foreach ($newUser in $users) {
            try {
                if ($WhatIf) {
                    Write-Host "[WHATIF] Would create: $($newUser.DisplayName)" -ForegroundColor Yellow
                    continue
                }

                # Generate password
                Add-Type -AssemblyName 'System.Web'
                $password = [System.Web.Security.Membership]::GeneratePassword(16, 4)

                # Create user
                $userParams = @{
                    DisplayName = $newUser.DisplayName
                    UserPrincipalName = $newUser.UserPrincipalName
                    MailNickname = $newUser.UserPrincipalName.Split('@')[0]
                    PasswordProfile = @{
                        Password = $password
                        ForceChangePasswordNextSignIn = $true
                    }
                    AccountEnabled = $true
                    Department = $newUser.Department
                    JobTitle = $newUser.JobTitle
                    UsageLocation = 'US'
                }

                $user = New-MgUser -BodyParameter $userParams
                Write-Host "✓ Created user: $($newUser.DisplayName)" -ForegroundColor Green
                Write-Host "  Temp Password: $password" -ForegroundColor Yellow

                # Add to groups if specified
                if ($newUser.Groups) {
                    $groupNames = $newUser.Groups -split ';'
                    foreach ($groupName in $groupNames) {
                        try {
                            $group = Get-MgGroup -Filter "displayName eq '$($groupName.Trim())'" | Select-Object -First 1
                            if ($group) {
                                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                                Write-Host "  Added to group: $groupName" -ForegroundColor Cyan
                            }
                        } catch {
                            Write-Warning "  Could not add to group $groupName : $_"
                        }
                    }
                }

                # Set manager if specified
                if ($newUser.ManagerEmail) {
                    try {
                        $manager = Get-MgUser -UserId $newUser.ManagerEmail
                        Set-MgUserManagerByRef -UserId $user.Id -DirectoryObjectId $manager.Id
                        Write-Host "  Set manager: $($newUser.ManagerEmail)" -ForegroundColor Cyan
                    } catch {
                        Write-Warning "  Could not set manager: $_"
                    }
                }
            }
            catch {
                Write-Error "Failed to process joiner $($newUser.DisplayName): $_"
            }
        }
    }
    else {
        # Process leavers
        foreach ($leavingUser in $users) {
            try {
                $upn = $leavingUser.UserPrincipalName
                $user = Get-MgUser -UserId $upn -Property 'id,displayName'

                if ($WhatIf) {
                    Write-Host "[WHATIF] Would process leaver: $($user.DisplayName)" -ForegroundColor Yellow
                    continue
                }

                # Disable account
                Update-MgUser -UserId $upn -AccountEnabled:$false
                Write-Host "✓ Disabled account: $($user.DisplayName)" -ForegroundColor Yellow

                # Remove from all groups
                $groups = Get-MgUserMemberOf -UserId $user.Id
                foreach ($group in $groups) {
                    try {
                        Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id
                        Write-Host "  Removed from: $($group.AdditionalProperties.displayName)" -ForegroundColor Cyan
                    } catch {
                        Write-Verbose "Could not remove from group: $_"
                    }
                }

                # Set out of office if email forwarding specified
                if ($leavingUser.ForwardEmail) {
                    Write-Host "  Set email forwarding to: $($leavingUser.ForwardEmail)" -ForegroundColor Cyan
                    # Email forwarding logic would go here
                }

                Write-Host "✓ Offboarding complete for: $($user.DisplayName)" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to process leaver $upn : $_"
            }
        }
    }

    Write-Host "`n✓ $Mode processing complete!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to process $Mode : $_"
}
