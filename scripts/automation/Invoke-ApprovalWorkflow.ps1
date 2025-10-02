<#
.SYNOPSIS
    Implement approval workflow for Graph API operations.
.DESCRIPTION
    Creates an approval workflow where operations require manager/admin approval
    before execution. Sends approval requests via email and tracks responses.
.PARAMETER Operation
    Operation type: CreateUser, DeleteUser, AddToGroup, GrantLicense, etc.
.PARAMETER TargetUser
    User being affected by the operation.
.PARAMETER Approvers
    Array of approver email addresses.
.PARAMETER RequestDetails
    Details of the requested operation.
.PARAMETER TimeoutHours
    Hours to wait for approval before canceling (default: 24).
.PARAMETER AutoExecute
    Automatically execute after approval (default: prompt).
.EXAMPLE
    .\Invoke-ApprovalWorkflow.ps1 -Operation "DeleteUser" -TargetUser "user@contoso.com" -Approvers "manager@contoso.com" -RequestDetails "Offboarding - last day 12/31"
.EXAMPLE
    .\Invoke-ApprovalWorkflow.ps1 -Operation "GrantLicense" -TargetUser "user@contoso.com" -Approvers "admin@contoso.com","finance@contoso.com" -RequestDetails "E5 license for project" -AutoExecute
.NOTES
    Required Permissions: Mail.Send, User.ReadWrite.All (or specific operation permissions)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CreateUser', 'DeleteUser', 'UpdateUser', 'AddToGroup', 'RemoveFromGroup', 'GrantLicense', 'RevokeLicense', 'Custom')]
    [string]$Operation,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetUser,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Approvers,
    [Parameter(Mandatory = $true)]
    [string]$RequestDetails,
    [Parameter(Mandatory = $false)]
    [int]$TimeoutHours = 24,
    [Parameter(Mandatory = $false)]
    [switch]$AutoExecute
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "=== Approval Workflow ===" -ForegroundColor Cyan
    Write-Host "Operation: $Operation" -ForegroundColor White
    Write-Host "Target User: $TargetUser" -ForegroundColor White
    Write-Host "Approvers: $($Approvers -join ', ')" -ForegroundColor White
    Write-Host ""

    # Generate unique approval ID
    $approvalId = [guid]::NewGuid().ToString().Substring(0, 8)
    $requestor = $context.Account

    # Create approval record
    $approvalRecord = [PSCustomObject]@{
        ApprovalId = $approvalId
        Timestamp = Get-Date
        Requestor = $requestor
        Operation = $Operation
        TargetUser = $TargetUser
        Details = $RequestDetails
        Approvers = $Approvers
        Status = 'Pending'
        ApprovedBy = $null
        ApprovedAt = $null
    }

    # Save to temp storage (in production, use database or SharePoint list)
    $approvalPath = "$env:TEMP\GraphApprovals"
    if (-not (Test-Path $approvalPath)) {
        New-Item -Path $approvalPath -ItemType Directory | Out-Null
    }
    $approvalFile = Join-Path $approvalPath "$approvalId.json"
    $approvalRecord | ConvertTo-Json | Out-File $approvalFile

    Write-Host "Approval request created: $approvalId" -ForegroundColor Green

    # Send approval emails
    Write-Host "Sending approval requests..." -ForegroundColor Cyan

    foreach ($approver in $Approvers) {
        try {
            $emailBody = @"
<html>
<body style='font-family: Arial, sans-serif;'>
<h2 style='color: #0078D4;'>Graph API Operation Approval Required</h2>

<table style='border-collapse: collapse; width: 100%;'>
<tr><td style='padding: 8px; font-weight: bold; border-bottom: 1px solid #ddd;'>Approval ID:</td><td style='padding: 8px; border-bottom: 1px solid #ddd;'>$approvalId</td></tr>
<tr><td style='padding: 8px; font-weight: bold; border-bottom: 1px solid #ddd;'>Requested By:</td><td style='padding: 8px; border-bottom: 1px solid #ddd;'>$requestor</td></tr>
<tr><td style='padding: 8px; font-weight: bold; border-bottom: 1px solid #ddd;'>Operation:</td><td style='padding: 8px; border-bottom: 1px solid #ddd;'>$Operation</td></tr>
<tr><td style='padding: 8px; font-weight: bold; border-bottom: 1px solid #ddd;'>Target User:</td><td style='padding: 8px; border-bottom: 1px solid #ddd;'>$TargetUser</td></tr>
<tr><td style='padding: 8px; font-weight: bold; border-bottom: 1px solid #ddd;'>Details:</td><td style='padding: 8px; border-bottom: 1px solid #ddd;'>$RequestDetails</td></tr>
<tr><td style='padding: 8px; font-weight: bold; border-bottom: 1px solid #ddd;'>Requested:</td><td style='padding: 8px; border-bottom: 1px solid #ddd;'>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</td></tr>
<tr><td style='padding: 8px; font-weight: bold; border-bottom: 1px solid #ddd;'>Expires:</td><td style='padding: 8px; border-bottom: 1px solid #ddd;'>$((Get-Date).AddHours($TimeoutHours).ToString('yyyy-MM-dd HH:mm:ss'))</td></tr>
</table>

<p style='margin-top: 20px;'><strong>To approve this request:</strong></p>
<p>Reply to this email with: <code style='background: #f0f0f0; padding: 2px 6px;'>APPROVE $approvalId</code></p>

<p><strong>To deny this request:</strong></p>
<p>Reply to this email with: <code style='background: #f0f0f0; padding: 2px 6px;'>DENY $approvalId [reason]</code></p>

<p style='color: #666; font-size: 12px; margin-top: 30px;'>This is an automated approval request from Microsoft Graph API workflow system.</p>
</body>
</html>
"@

            $mailParams = @{
                Message = @{
                    Subject = "Approval Required: $Operation for $TargetUser [$approvalId]"
                    Body = @{
                        ContentType = "HTML"
                        Content = $emailBody
                    }
                    ToRecipients = @(
                        @{
                            EmailAddress = @{
                                Address = $approver
                            }
                        }
                    )
                    Importance = "High"
                }
                SaveToSentItems = $true
            }

            Send-MgUserMail -UserId $requestor -BodyParameter $mailParams
            Write-Host "  ✓ Sent approval request to: $approver" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to send approval to $approver : $_"
        }
    }

    Write-Host "`n✓ Approval workflow initiated" -ForegroundColor Green
    Write-Host "`nApproval Details:" -ForegroundColor Cyan
    Write-Host "  Approval ID: $approvalId" -ForegroundColor White
    Write-Host "  Status: Pending" -ForegroundColor Yellow
    Write-Host "  Expires: $((Get-Date).AddHours($TimeoutHours).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host "  Tracking File: $approvalFile" -ForegroundColor Gray

    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "1. Wait for approver to respond via email" -ForegroundColor White
    Write-Host "2. Check approval status: Get-Content '$approvalFile' | ConvertFrom-Json" -ForegroundColor White
    Write-Host "3. Process approval responses (requires email monitoring script)" -ForegroundColor White

    if (-not $AutoExecute) {
        Write-Host "`nNote: AutoExecute is disabled. Operation must be run manually after approval." -ForegroundColor Yellow
    }

    return $approvalRecord
}
catch {
    Write-Error "Approval workflow failed: $_"
}
