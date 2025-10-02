<#
.SYNOPSIS
    Generate report of all guest users in the organization.
.DESCRIPTION
    Lists all external/guest users with access details, sign-in activity,
    and group memberships for security auditing.
.PARAMETER IncludeSignInActivity
    Include last sign-in dates.
.PARAMETER IncludeGroupMemberships
    Include groups each guest belongs to.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-GuestUserReport.ps1 -IncludeSignInActivity -ExportPath "C:\Reports\guests.csv"
.NOTES
    Required Permissions: User.Read.All, AuditLog.Read.All, Directory.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSignInActivity,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeGroupMemberships,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Retrieving guest users..." -ForegroundColor Cyan

    # Get all guest users
    $guests = Get-MgUser -Filter "userType eq 'Guest'" -All `
        -Property 'id,displayName,userPrincipalName,mail,createdDateTime,accountEnabled,userType'

    $report = $guests | ForEach-Object {
        $guest = $_
        $guestInfo = [PSCustomObject]@{
            DisplayName = $guest.DisplayName
            Email = $guest.Mail
            UPN = $guest.UserPrincipalName
            Enabled = $guest.AccountEnabled
            CreatedDate = $guest.CreatedDateTime
        }

        # Add sign-in activity if requested
        if ($IncludeSignInActivity) {
            try {
                $signIn = Get-MgUser -UserId $guest.Id -Property 'signInActivity' |
                    Select-Object -ExpandProperty SignInActivity
                $guestInfo | Add-Member -MemberType NoteProperty -Name 'LastSignIn' -Value $signIn.LastSignInDateTime
            } catch {
                $guestInfo | Add-Member -MemberType NoteProperty -Name 'LastSignIn' -Value 'Unknown'
            }
        }

        # Add group memberships if requested
        if ($IncludeGroupMemberships) {
            try {
                $groups = Get-MgUserMemberOf -UserId $guest.Id
                $groupNames = ($groups | ForEach-Object { $_.AdditionalProperties.displayName }) -join '; '
                $guestInfo | Add-Member -MemberType NoteProperty -Name 'Groups' -Value $groupNames
                $guestInfo | Add-Member -MemberType NoteProperty -Name 'GroupCount' -Value $groups.Count
            } catch {
                $guestInfo | Add-Member -MemberType NoteProperty -Name 'Groups' -Value ''
                $guestInfo | Add-Member -MemberType NoteProperty -Name 'GroupCount' -Value 0
            }
        }

        $guestInfo
    }

    Write-Host "`n✓ Found $($report.Count) guest users" -ForegroundColor Green

    if ($ExportPath) {
        $report | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Format-Table -AutoSize
    }

    return $report
}
catch {
    Write-Error "Failed to generate guest user report: $_"
}
