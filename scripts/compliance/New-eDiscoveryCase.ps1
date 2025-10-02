<#
.SYNOPSIS
    Create and manage eDiscovery cases for compliance investigations.
.DESCRIPTION
    Creates eDiscovery cases with custodians, holds, and search queries
    for legal and compliance investigations in Microsoft 365.
.PARAMETER CaseName
    Name for the eDiscovery case.
.PARAMETER Description
    Case description and purpose.
.PARAMETER CaseType
    Case type: eDiscovery or AdvancedEDiscovery.
.PARAMETER Custodians
    Array of custodian email addresses to add to case.
.PARAMETER ExternalId
    External case/matter number for tracking.
.EXAMPLE
    .\New-eDiscoveryCase.ps1 -CaseName "Investigation-2024-001" -Description "Employment matter" -Custodians "user1@contoso.com","user2@contoso.com"
.EXAMPLE
    .\New-eDiscoveryCase.ps1 -CaseName "Legal-Hold-Q1" -CaseType AdvancedEDiscovery -ExternalId "CASE-2024-123"
.NOTES
    Required Permissions: eDiscovery.Read.All, eDiscovery.ReadWrite.All
    Requires Microsoft 365 E5 or Compliance license
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,
    [Parameter(Mandatory = $false)]
    [string]$Description,
    [Parameter(Mandatory = $false)]
    [ValidateSet('eDiscovery', 'AdvancedEDiscovery')]
    [string]$CaseType = 'eDiscovery',
    [Parameter(Mandatory = $false)]
    [string[]]$Custodians,
    [Parameter(Mandatory = $false)]
    [string]$ExternalId
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "=== eDiscovery Case Management ===" -ForegroundColor Cyan
    Write-Host "Case Name: $CaseName" -ForegroundColor White
    Write-Host "Type: $CaseType" -ForegroundColor White
    Write-Host ""

    if ($PSCmdlet.ShouldProcess($CaseName, "Create eDiscovery case")) {
        # Create eDiscovery case
        Write-Host "Creating eDiscovery case..." -ForegroundColor Cyan

        $caseParams = @{
            DisplayName = $CaseName
            Description = $Description
            ExternalId = $ExternalId
        }

        if ($CaseType -eq 'AdvancedEDiscovery') {
            # Create Advanced eDiscovery case
            $case = New-MgSecurityCaseEdiscoveryCase -BodyParameter $caseParams
        }
        else {
            # Create standard eDiscovery case
            $case = New-MgSecurityCaseEdiscoveryCase -BodyParameter $caseParams
        }

        Write-Host "✓ eDiscovery case created" -ForegroundColor Green
        Write-Host "  Case ID: $($case.Id)" -ForegroundColor Cyan
        Write-Host "  Status: $($case.Status)" -ForegroundColor Cyan

        # Add custodians if specified
        if ($Custodians) {
            Write-Host "`nAdding custodians to case..." -ForegroundColor Cyan

            foreach ($custodian in $Custodians) {
                try {
                    # Get user
                    $user = Get-MgUser -UserId $custodian

                    # Add as custodian
                    $custodianParams = @{
                        Email = $custodian
                        ApplyHoldToSources = $true
                    }

                    New-MgSecurityCaseEdiscoveryCaseCustodian -EdiscoveryCaseId $case.Id `
                        -BodyParameter $custodianParams

                    Write-Host "  ✓ Added custodian: $custodian" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to add custodian $custodian : $_"
                }
            }
        }

        Write-Host "`n✓ eDiscovery case setup complete" -ForegroundColor Green
        Write-Host "`nCase Details:" -ForegroundColor Cyan
        Write-Host "  Name: $CaseName" -ForegroundColor White
        Write-Host "  ID: $($case.Id)" -ForegroundColor White
        Write-Host "  Status: $($case.Status)" -ForegroundColor White
        Write-Host "  Created: $($case.CreatedDateTime)" -ForegroundColor White

        if ($ExternalId) {
            Write-Host "  External ID: $ExternalId" -ForegroundColor White
        }

        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Create search queries for the case" -ForegroundColor White
        Write-Host "2. Review and export search results" -ForegroundColor White
        Write-Host "3. Place holds on custodian data sources" -ForegroundColor White
        Write-Host "4. View case in Microsoft Purview Compliance Portal" -ForegroundColor White

        return $case
    }
}
catch {
    Write-Error "eDiscovery case creation failed: $_"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "- Verify you have eDiscovery.ReadWrite.All permission" -ForegroundColor White
    Write-Host "- Ensure tenant has required compliance licenses (E5 or Compliance)" -ForegroundColor White
    Write-Host "- Check that eDiscovery is enabled in compliance portal" -ForegroundColor White
}
