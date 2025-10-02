<#
.SYNOPSIS
    Generate mailbox storage utilization report.
.DESCRIPTION
    Reports on mailbox sizes, quota usage, and storage metrics across
    the organization. Helps identify large mailboxes for cleanup.
.PARAMETER UserPrincipalName
    Specific user to report on (optional, default: all users).
.PARAMETER IncludeArchive
    Include archive mailbox statistics.
.PARAMETER MinSizeMB
    Only include mailboxes larger than specified MB.
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-MailboxSizeReport.ps1 -MinSizeMB 5000 -ExportPath "C:\large-mailboxes.csv"
.EXAMPLE
    .\Get-MailboxSizeReport.ps1 -UserPrincipalName "user@contoso.com" -IncludeArchive
.NOTES
    Required Permissions: MailboxSettings.Read, User.Read.All
    Note: This uses available Graph API data. Full mailbox stats require Exchange Online cmdlets.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName,
    [Parameter(Mandatory = $false)]
    [switch]$IncludeArchive,
    [Parameter(Mandatory = $false)]
    [int]$MinSizeMB,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating mailbox size report..." -ForegroundColor Cyan

    # Get users
    if ($UserPrincipalName) {
        $users = @(Get-MgUser -UserId $UserPrincipalName -Property 'displayName,userPrincipalName,mail')
    } else {
        $users = Get-MgUser -Filter "assignedLicenses/`$count ne 0 and userType eq 'Member'" -All `
            -Property 'displayName,userPrincipalName,mail' `
            -ConsistencyLevel eventual -CountVariable count
    }

    Write-Host "  Processing $($users.Count) mailboxes..." -ForegroundColor Cyan

    $report = $users | ForEach-Object {
        $user = $_
        Write-Progress -Activity "Scanning mailboxes" -Status $user.UserPrincipalName `
            -PercentComplete (([array]::IndexOf($users, $user) / $users.Count) * 100)

        try {
            # Get mailbox folder statistics
            $inboxStats = Get-MgUserMailFolderMessageCount -UserId $user.Id -MailFolderId "inbox"
            $sentItemsStats = Get-MgUserMailFolderMessageCount -UserId $user.Id -MailFolderId "sentitems"
            $deletedStats = Get-MgUserMailFolderMessageCount -UserId $user.Id -MailFolderId "deleteditems"

            # Estimate size (Graph API doesn't expose exact mailbox size without Exchange)
            # Using message counts as proxy
            $totalMessages = $inboxStats + $sentItemsStats + $deletedStats
            $estimatedSizeMB = [math]::Round($totalMessages * 0.15, 2) # Rough estimate: 150KB per message

            $mailboxInfo = [PSCustomObject]@{
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Email = $user.Mail
                InboxCount = $inboxStats
                SentItemsCount = $sentItemsStats
                DeletedItemsCount = $deletedStats
                TotalMessages = $totalMessages
                EstimatedSizeMB = $estimatedSizeMB
            }

            # Filter by size if specified
            if ($MinSizeMB -and $estimatedSizeMB -lt $MinSizeMB) {
                return $null
            }

            $mailboxInfo
        }
        catch {
            Write-Warning "Could not retrieve stats for $($user.UserPrincipalName): $_"
            return $null
        }
    } | Where-Object { $_ -ne $null }

    Write-Progress -Activity "Scanning mailboxes" -Completed

    # Calculate totals
    $totalMailboxes = $report.Count
    $totalMessages = ($report | Measure-Object -Property TotalMessages -Sum).Sum
    $totalSizeMB = ($report | Measure-Object -Property EstimatedSizeMB -Sum).Sum
    $avgSizeMB = [math]::Round($totalSizeMB / $totalMailboxes, 2)

    Write-Host "`n✓ Mailbox report generated" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total Mailboxes: $totalMailboxes" -ForegroundColor White
    Write-Host "  Total Messages: $totalMessages" -ForegroundColor White
    Write-Host "  Total Estimated Size: $totalSizeMB MB" -ForegroundColor White
    Write-Host "  Average Size: $avgSizeMB MB" -ForegroundColor White

    if ($MinSizeMB) {
        Write-Host "  Filtered: Mailboxes > $MinSizeMB MB" -ForegroundColor Yellow
    }

    if ($ExportPath) {
        $report | Sort-Object EstimatedSizeMB -Descending | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Sort-Object EstimatedSizeMB -Descending | Format-Table -AutoSize
    }

    return $report
}
catch {
    Write-Error "Mailbox size report failed: $_"
}
