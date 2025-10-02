<#
.SYNOPSIS
    Generate Multi-Factor Authentication (MFA) enrollment status report.
.DESCRIPTION
    Reports on MFA registration status across all users, including
    authentication methods registered and default methods.
.PARAMETER IncludeGuests
    Include guest users in the report.
.PARAMETER UnregisteredOnly
    Show only users who haven't registered for MFA.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-MFAStatusReport.ps1 -UnregisteredOnly -ExportPath "C:\mfa-gaps.csv"
.EXAMPLE
    .\Get-MFAStatusReport.ps1 -IncludeGuests
.NOTES
    Required Permissions: UserAuthenticationMethod.Read.All, User.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeGuests,
    [Parameter(Mandatory = $false)]
    [switch]$UnregisteredOnly,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating MFA status report..." -ForegroundColor Cyan

    # Get users
    $filterQuery = "accountEnabled eq true"
    if (-not $IncludeGuests) {
        $filterQuery += " and userType eq 'Member'"
    }

    $users = Get-MgUser -Filter $filterQuery -All `
        -Property 'id,displayName,userPrincipalName,userType' `
        -ConsistencyLevel eventual

    Write-Host "  Processing $($users.Count) users..." -ForegroundColor Cyan

    $report = $users | ForEach-Object {
        $user = $_
        Write-Progress -Activity "Checking MFA status" -Status $user.UserPrincipalName `
            -PercentComplete (([array]::IndexOf($users, $user) / $users.Count) * 100)

        try {
            # Get authentication methods
            $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id

            $methodTypes = $authMethods | ForEach-Object {
                $_.AdditionalProperties.'@odata.type' -replace '#microsoft.graph.', ''
            }

            $hasMFA = $methodTypes -contains 'phoneAuthenticationMethod' -or
                      $methodTypes -contains 'microsoftAuthenticatorAuthenticationMethod' -or
                      $methodTypes -contains 'fido2AuthenticationMethod' -or
                      $methodTypes -contains 'softwareOathAuthenticationMethod'

            $mfaStatus = if ($hasMFA) { "Registered" } else { "Not Registered" }

            $userInfo = [PSCustomObject]@{
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                UserType = $user.UserType
                MFAStatus = $mfaStatus
                MethodCount = $authMethods.Count
                Methods = ($methodTypes -join ', ')
                HasPhoneAuth = $methodTypes -contains 'phoneAuthenticationMethod'
                HasAuthenticatorApp = $methodTypes -contains 'microsoftAuthenticatorAuthenticationMethod'
                HasFIDO2 = $methodTypes -contains 'fido2AuthenticationMethod'
                HasPasswordless = $methodTypes -contains 'passwordlessAuthenticationMethod'
            }

            # Filter if only showing unregistered
            if ($UnregisteredOnly -and $hasMFA) {
                return $null
            }

            $userInfo
        }
        catch {
            Write-Warning "Could not retrieve MFA status for $($user.UserPrincipalName): $_"
            return $null
        }
    } | Where-Object { $_ -ne $null }

    Write-Progress -Activity "Checking MFA status" -Completed

    # Calculate statistics
    $totalUsers = $report.Count
    $registeredUsers = ($report | Where-Object { $_.MFAStatus -eq 'Registered' }).Count
    $unregisteredUsers = $totalUsers - $registeredUsers
    $registrationRate = [math]::Round(($registeredUsers / $totalUsers) * 100, 2)

    Write-Host "`n✓ MFA Status Report" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total Users: $totalUsers" -ForegroundColor White
    Write-Host "  MFA Registered: $registeredUsers ($registrationRate%)" -ForegroundColor Green
    Write-Host "  Not Registered: $unregisteredUsers" -ForegroundColor $(if ($unregisteredUsers -gt 0) { 'Yellow' } else { 'Green' })

    if ($ExportPath) {
        $report | Sort-Object MFAStatus, DisplayName | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Sort-Object MFAStatus, DisplayName | Format-Table DisplayName, UserPrincipalName, MFAStatus, MethodCount, Methods -AutoSize
    }

    return $report
}
catch {
    Write-Error "MFA status report failed: $_"
}
