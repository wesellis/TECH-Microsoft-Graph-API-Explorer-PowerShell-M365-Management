<#
.SYNOPSIS
    Get detailed information about a user from Microsoft 365.

.DESCRIPTION
    Retrieves comprehensive user information from Microsoft Graph API including:
    - Basic user properties (name, email, department, etc.)
    - Sign-in activity
    - License assignments
    - Group memberships
    - Manager information

.PARAMETER UserId
    The UserPrincipalName (UPN) or ObjectId of the user to retrieve information for.

.PARAMETER IncludeSignInActivity
    Include recent sign-in activity data.

.PARAMETER IncludeLicenses
    Include detailed license assignment information.

.PARAMETER IncludeGroups
    Include group membership information.

.PARAMETER IncludeManager
    Include manager information.

.EXAMPLE
    .\get-user-info.ps1 -UserId "john.doe@contoso.com"
    Get basic user information.

.EXAMPLE
    .\get-user-info.ps1 -UserId "john.doe@contoso.com" -IncludeSignInActivity -IncludeLicenses -IncludeGroups
    Get comprehensive user information including activity, licenses, and groups.

.NOTES
    Required Graph API Permissions:
    - User.Read.All
    - Directory.Read.All (for groups and manager)
    - AuditLog.Read.All (for sign-in activity)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$UserId,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSignInActivity,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeLicenses,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeGroups,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeManager
)

begin {
    # Check if connected to Microsoft Graph
    try {
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Please run Connect-MgGraph first."
        }
        Write-Verbose "Connected to tenant: $($context.TenantId)"
    }
    catch {
        Write-Error "Failed to verify Microsoft Graph connection: $_"
        return
    }
}

process {
    try {
        Write-Verbose "Retrieving user information for: $UserId"

        # Get base user information
        $selectProperties = @(
            'id', 'displayName', 'userPrincipalName', 'mail', 'jobTitle',
            'department', 'officeLocation', 'mobilePhone', 'businessPhones',
            'accountEnabled', 'createdDateTime', 'userType', 'companyName'
        )

        $user = Get-MgUser -UserId $UserId -Property ($selectProperties -join ',') -ErrorAction Stop

        # Build result object
        $result = [PSCustomObject]@{
            Id                  = $user.Id
            DisplayName         = $user.DisplayName
            UserPrincipalName   = $user.UserPrincipalName
            Mail                = $user.Mail
            JobTitle            = $user.JobTitle
            Department          = $user.Department
            Office              = $user.OfficeLocation
            MobilePhone         = $user.MobilePhone
            BusinessPhones      = $user.BusinessPhones -join ', '
            AccountEnabled      = $user.AccountEnabled
            UserType            = $user.UserType
            CompanyName         = $user.CompanyName
            CreatedDateTime     = $user.CreatedDateTime
        }

        # Get sign-in activity if requested
        if ($IncludeSignInActivity) {
            Write-Verbose "Retrieving sign-in activity..."
            try {
                $signInActivity = Get-MgUser -UserId $user.Id -Property 'signInActivity' | Select-Object -ExpandProperty SignInActivity
                $result | Add-Member -MemberType NoteProperty -Name 'LastSignIn' -Value $signInActivity.LastSignInDateTime
                $result | Add-Member -MemberType NoteProperty -Name 'LastNonInteractiveSignIn' -Value $signInActivity.LastNonInteractiveSignInDateTime
            }
            catch {
                Write-Warning "Could not retrieve sign-in activity: $_"
            }
        }

        # Get license information if requested
        if ($IncludeLicenses) {
            Write-Verbose "Retrieving license assignments..."
            try {
                $licenses = Get-MgUserLicenseDetail -UserId $user.Id
                $licenseNames = $licenses | ForEach-Object { $_.SkuPartNumber }
                $result | Add-Member -MemberType NoteProperty -Name 'Licenses' -Value ($licenseNames -join ', ')
                $result | Add-Member -MemberType NoteProperty -Name 'LicenseCount' -Value $licenses.Count
            }
            catch {
                Write-Warning "Could not retrieve license information: $_"
            }
        }

        # Get group memberships if requested
        if ($IncludeGroups) {
            Write-Verbose "Retrieving group memberships..."
            try {
                $groups = Get-MgUserMemberOf -UserId $user.Id
                $groupNames = $groups | ForEach-Object {
                    if ($_.AdditionalProperties.displayName) {
                        $_.AdditionalProperties.displayName
                    }
                }
                $result | Add-Member -MemberType NoteProperty -Name 'Groups' -Value ($groupNames -join ', ')
                $result | Add-Member -MemberType NoteProperty -Name 'GroupCount' -Value $groups.Count
            }
            catch {
                Write-Warning "Could not retrieve group memberships: $_"
            }
        }

        # Get manager if requested
        if ($IncludeManager) {
            Write-Verbose "Retrieving manager information..."
            try {
                $manager = Get-MgUserManager -UserId $user.Id -ErrorAction SilentlyContinue
                if ($manager) {
                    $result | Add-Member -MemberType NoteProperty -Name 'Manager' -Value $manager.AdditionalProperties.displayName
                    $result | Add-Member -MemberType NoteProperty -Name 'ManagerEmail' -Value $manager.AdditionalProperties.userPrincipalName
                }
            }
            catch {
                Write-Verbose "User has no manager assigned."
            }
        }

        # Output result
        Write-Output $result

    }
    catch {
        Write-Error "Failed to retrieve user information for '$UserId': $_"
    }
}

end {
    Write-Verbose "User information retrieval completed."
}
