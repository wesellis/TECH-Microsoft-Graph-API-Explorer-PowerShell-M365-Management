<#
.SYNOPSIS
    Create a new user in Microsoft 365.

.DESCRIPTION
    Creates a new user account in Azure AD with specified properties.
    Supports setting department, job title, location, and other properties.

.PARAMETER DisplayName
    The display name for the user.

.PARAMETER UserPrincipalName
    The user principal name (UPN) / email address.

.PARAMETER MailNickname
    The mail alias for the user. If not specified, derived from UPN.

.PARAMETER Password
    The initial password for the user. If not specified, a random password is generated.

.PARAMETER ForceChangePassword
    Force user to change password on first sign-in. Default is true.

.PARAMETER Department
    The user's department.

.PARAMETER JobTitle
    The user's job title.

.PARAMETER OfficeLocation
    The user's office location.

.PARAMETER MobilePhone
    The user's mobile phone number.

.PARAMETER UsageLocation
    The usage location (country code) for license assignment. Required for licensing.

.PARAMETER SendWelcomeEmail
    Send a welcome email with credentials to the user.

.EXAMPLE
    .\create-user.ps1 -DisplayName "John Doe" -UserPrincipalName "john.doe@contoso.com" -UsageLocation "US"
    Create a new user with generated password.

.EXAMPLE
    .\create-user.ps1 -DisplayName "Jane Smith" -UserPrincipalName "jane.smith@contoso.com" -Password "P@ssw0rd!" -Department "IT" -JobTitle "IT Manager"
    Create a user with specified properties.

.NOTES
    Required Graph API Permissions: User.ReadWrite.All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $false)]
    [string]$MailNickname,

    [Parameter(Mandatory = $false)]
    [SecureString]$Password,

    [Parameter(Mandatory = $false)]
    [bool]$ForceChangePassword = $true,

    [Parameter(Mandatory = $false)]
    [string]$Department,

    [Parameter(Mandatory = $false)]
    [string]$JobTitle,

    [Parameter(Mandatory = $false)]
    [string]$OfficeLocation,

    [Parameter(Mandatory = $false)]
    [string]$MobilePhone,

    [Parameter(Mandatory = $false)]
    [ValidateLength(2, 2)]
    [string]$UsageLocation,

    [Parameter(Mandatory = $false)]
    [switch]$SendWelcomeEmail
)

begin {
    # Check if connected to Microsoft Graph
    try {
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-MgGraph first."
        }
    }
    catch {
        Write-Error "Failed to verify Microsoft Graph connection: $_"
        return
    }

    # Generate mail nickname if not provided
    if (-not $MailNickname) {
        $MailNickname = $UserPrincipalName.Split('@')[0]
    }

    # Generate random password if not provided
    if (-not $Password) {
        Add-Type -AssemblyName 'System.Web'
        $plainPassword = [System.Web.Security.Membership]::GeneratePassword(16, 4)
        $Password = ConvertTo-SecureString -String $plainPassword -AsPlainText -Force
        Write-Verbose "Generated random password"
    }
    else {
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    }
}

process {
    try {
        Write-Verbose "Creating user: $UserPrincipalName"

        # Build user object
        $passwordProfile = @{
            Password = $plainPassword
            ForceChangePasswordNextSignIn = $ForceChangePassword
        }

        $userParams = @{
            DisplayName = $DisplayName
            UserPrincipalName = $UserPrincipalName
            MailNickname = $MailNickname
            PasswordProfile = $passwordProfile
            AccountEnabled = $true
        }

        if ($Department) { $userParams['Department'] = $Department }
        if ($JobTitle) { $userParams['JobTitle'] = $JobTitle }
        if ($OfficeLocation) { $userParams['OfficeLocation'] = $OfficeLocation }
        if ($MobilePhone) { $userParams['MobilePhone'] = $MobilePhone }
        if ($UsageLocation) { $userParams['UsageLocation'] = $UsageLocation }

        # Create the user
        $newUser = New-MgUser -BodyParameter $userParams

        Write-Host "✓ User created successfully!" -ForegroundColor Green
        Write-Host "  Display Name: $DisplayName" -ForegroundColor Cyan
        Write-Host "  UPN: $UserPrincipalName" -ForegroundColor Cyan
        Write-Host "  User ID: $($newUser.Id)" -ForegroundColor Cyan
        Write-Host "  Temp Password: $plainPassword" -ForegroundColor Yellow

        if ($SendWelcomeEmail) {
            Write-Verbose "Sending welcome email..."
            # Email sending logic would go here
            Write-Warning "Welcome email functionality not yet implemented."
        }

        return $newUser

    }
    catch {
        Write-Error "Failed to create user: $_"
    }
}
