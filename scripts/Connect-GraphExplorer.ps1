<#
.SYNOPSIS
    Connect to Microsoft Graph with common permission scopes.
.DESCRIPTION
    Simplified connection script that requests common Graph API permissions
    needed for user, group, and organizational management.
.PARAMETER TenantId
    The Azure AD tenant ID (optional, will prompt if not provided).
.PARAMETER Scopes
    Custom permission scopes (optional, uses defaults if not specified).
.EXAMPLE
    .\Connect-GraphExplorer.ps1
.EXAMPLE
    .\Connect-GraphExplorer.ps1 -TenantId "contoso.onmicrosoft.com"
.NOTES
    This is the recommended way to connect before running other scripts.
    Default scopes cover most common administrative tasks.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    [Parameter(Mandatory = $false)]
    [string[]]$Scopes
)

try {
    Write-Host "`n=== Microsoft Graph API Explorer ===" -ForegroundColor Cyan
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor White

    # Default scopes for common operations
    if (-not $Scopes) {
        $Scopes = @(
            'User.ReadWrite.All',
            'Group.ReadWrite.All',
            'Directory.ReadWrite.All',
            'Organization.Read.All',
            'AuditLog.Read.All',
            'GroupMember.ReadWrite.All'
        )
    }

    # Connect parameters
    $connectParams = @{
        Scopes = $Scopes
    }

    if ($TenantId) {
        $connectParams['TenantId'] = $TenantId
    }

    # Connect to Graph
    Connect-MgGraph @connectParams

    # Display connection info
    $context = Get-MgContext

    Write-Host "`n✓ Successfully connected to Microsoft Graph!" -ForegroundColor Green
    Write-Host "`nConnection Details:" -ForegroundColor Cyan
    Write-Host "  Tenant ID: $($context.TenantId)" -ForegroundColor White
    Write-Host "  Account: $($context.Account)" -ForegroundColor White
    Write-Host "  Client ID: $($context.ClientId)" -ForegroundColor White

    Write-Host "`nGranted Scopes:" -ForegroundColor Cyan
    $context.Scopes | ForEach-Object {
        Write-Host "  ✓ $_" -ForegroundColor Green
    }

    Write-Host "`nYou're ready to run Graph API scripts!" -ForegroundColor Green
    Write-Host "To disconnect, run: Disconnect-MgGraph`n" -ForegroundColor Yellow

    return $context
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure Microsoft.Graph module is installed: Install-Module Microsoft.Graph" -ForegroundColor White
    Write-Host "2. Check your account has appropriate permissions" -ForegroundColor White
    Write-Host "3. Verify network connectivity to Microsoft Graph" -ForegroundColor White
}
