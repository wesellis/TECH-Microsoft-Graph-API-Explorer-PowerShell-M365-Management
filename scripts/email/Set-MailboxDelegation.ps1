<#
.SYNOPSIS
    Configure mailbox delegation permissions.
.DESCRIPTION
    Grants or removes mailbox folder permissions for delegation scenarios
    (e.g., assistant accessing manager's calendar/mail).
.PARAMETER MailboxOwner
    The user whose mailbox will be delegated.
.PARAMETER Delegate
    The user receiving delegation permissions.
.PARAMETER FolderType
    Folder to delegate: Calendar, Inbox, or Contacts.
.PARAMETER PermissionLevel
    Permission level: Read, Write, or FullAccess.
.PARAMETER Remove
    Remove delegation instead of granting.
.EXAMPLE
    .\Set-MailboxDelegation.ps1 -MailboxOwner "manager@contoso.com" -Delegate "assistant@contoso.com" -FolderType Calendar -PermissionLevel Write
.EXAMPLE
    .\Set-MailboxDelegation.ps1 -MailboxOwner "manager@contoso.com" -Delegate "assistant@contoso.com" -FolderType Inbox -Remove
.NOTES
    Required Permissions: MailboxSettings.ReadWrite, Calendars.ReadWrite (for calendar delegation)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$MailboxOwner,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Delegate,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Calendar', 'Inbox', 'Contacts')]
    [string]$FolderType,
    [Parameter(Mandatory = $false)]
    [ValidateSet('Read', 'Write', 'FullAccess')]
    [string]$PermissionLevel = 'Read',
    [Parameter(Mandatory = $false)]
    [switch]$Remove
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    # Get user objects
    $owner = Get-MgUser -UserId $MailboxOwner
    $delegateUser = Get-MgUser -UserId $Delegate

    if ($Remove) {
        if ($PSCmdlet.ShouldProcess("$($owner.DisplayName) - $FolderType", "Remove delegation for $($delegateUser.DisplayName)")) {
            Write-Host "Removing $FolderType delegation..." -ForegroundColor Cyan
            Write-Host "  Owner: $($owner.DisplayName) ($MailboxOwner)" -ForegroundColor White
            Write-Host "  Delegate: $($delegateUser.DisplayName) ($Delegate)" -ForegroundColor White

            # Map folder type to mail folder ID
            $folderId = switch ($FolderType) {
                'Calendar' { 'calendar' }
                'Inbox' { 'inbox' }
                'Contacts' { 'contacts' }
            }

            # Remove permission (Graph API limitation: may require Exchange Online cmdlets for full control)
            Write-Warning "Note: Full mailbox delegation removal may require Exchange Online PowerShell cmdlets."
            Write-Host "  Use: Remove-MailboxFolderPermission -Identity '$MailboxOwner:\$FolderType' -User '$Delegate'" -ForegroundColor Yellow
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess("$($owner.DisplayName) - $FolderType", "Grant $PermissionLevel to $($delegateUser.DisplayName)")) {
            Write-Host "Granting $FolderType delegation..." -ForegroundColor Cyan
            Write-Host "  Owner: $($owner.DisplayName) ($MailboxOwner)" -ForegroundColor White
            Write-Host "  Delegate: $($delegateUser.DisplayName) ($Delegate)" -ForegroundColor White
            Write-Host "  Permission: $PermissionLevel" -ForegroundColor White

            # For calendar, we can set permissions via Graph
            if ($FolderType -eq 'Calendar') {
                $permissionBody = @{
                    EmailAddress = @{
                        Name = $delegateUser.DisplayName
                        Address = $Delegate
                    }
                    AllowedRoles = @(
                        switch ($PermissionLevel) {
                            'Read' { 'read' }
                            'Write' { 'write' }
                            'FullAccess' { 'write' }
                        }
                    )
                    Role = switch ($PermissionLevel) {
                        'Read' { 'read' }
                        'Write' { 'write' }
                        'FullAccess' { 'write' }
                    }
                }

                try {
                    New-MgUserCalendarPermission -UserId $owner.Id -BodyParameter $permissionBody
                    Write-Host "`n✓ Calendar delegation granted successfully" -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to set calendar permission: $_"
                }
            }
            else {
                # Inbox/Contacts require Exchange Online cmdlets
                Write-Warning "Note: Full mailbox/contacts delegation requires Exchange Online PowerShell cmdlets."
                Write-Host "`nRecommended Exchange Online command:" -ForegroundColor Yellow
                Write-Host "  Add-MailboxFolderPermission -Identity '$MailboxOwner:\$FolderType' -User '$Delegate' -AccessRights $PermissionLevel" -ForegroundColor Cyan
            }
        }
    }
}
catch {
    Write-Error "Mailbox delegation failed: $_"
}
