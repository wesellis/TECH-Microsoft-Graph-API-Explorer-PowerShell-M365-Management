<#
.SYNOPSIS
    Test which Microsoft Graph API permissions are currently granted.
.DESCRIPTION
    Validates the current connection's permissions and tests access to
    common Graph API endpoints.
.EXAMPLE
    .\Test-GraphPermissions.ps1
.NOTES
    Helps troubleshoot permission issues before running other scripts.
#>
[CmdletBinding()]
param()

try {
    $context = Get-MgContext
    if (-not $context) {
        Write-Error "Not connected to Microsoft Graph. Run Connect-MgGraph first."
        return
    }

    Write-Host "`n=== Microsoft Graph Connection Info ===" -ForegroundColor Cyan
    Write-Host "Tenant ID: $($context.TenantId)" -ForegroundColor White
    Write-Host "Client ID: $($context.ClientId)" -ForegroundColor White
    Write-Host "Account: $($context.Account)" -ForegroundColor White

    Write-Host "`n=== Granted Scopes ===" -ForegroundColor Cyan
    $context.Scopes | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }

    Write-Host "`n=== Testing Permissions ===" -ForegroundColor Cyan

    $tests = @(
        @{ Name = 'User.Read.All'; Test = { Get-MgUser -Top 1 } },
        @{ Name = 'Group.Read.All'; Test = { Get-MgGroup -Top 1 } },
        @{ Name = 'Directory.Read.All'; Test = { Get-MgOrganization } },
        @{ Name = 'AuditLog.Read.All'; Test = { Get-MgAuditLogDirectoryAudit -Top 1 } }
    )

    foreach ($test in $tests) {
        try {
            $null = & $test.Test
            Write-Host "  ✓ $($test.Name) - Working" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ $($test.Name) - Failed" -ForegroundColor Red
        }
    }

    Write-Host ""
}
catch {
    Write-Error "Permission test failed: $_"
}
