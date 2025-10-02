<#
.SYNOPSIS
    Search emails across user mailboxes using Microsoft Graph.
.DESCRIPTION
    Searches email messages based on subject, sender, date range, and content.
    Returns matching messages with key details.
.PARAMETER UserId
    User mailbox to search. Use "me" for current user.
.PARAMETER Subject
    Search in subject line.
.PARAMETER From
    Filter by sender email address.
.PARAMETER StartDate
    Search emails from this date forward (format: YYYY-MM-DD).
.PARAMETER EndDate
    Search emails up to this date (format: YYYY-MM-DD).
.PARAMETER Top
    Maximum number of results to return (default: 50).
.PARAMETER ExportPath
    Export results to CSV file.
.EXAMPLE
    .\Search-GraphMail.ps1 -UserId "user@contoso.com" -Subject "invoice" -StartDate "2024-01-01"
.EXAMPLE
    .\Search-GraphMail.ps1 -UserId "me" -From "noreply@vendor.com" -Top 100 -ExportPath "C:\emails.csv"
.NOTES
    Required Permissions: Mail.Read, Mail.ReadBasic (or Mail.ReadWrite for current user)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$UserId,
    [Parameter(Mandatory = $false)]
    [string]$Subject,
    [Parameter(Mandatory = $false)]
    [string]$From,
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$StartDate,
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$EndDate,
    [Parameter(Mandatory = $false)]
    [int]$Top = 50,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Searching emails in mailbox: $UserId..." -ForegroundColor Cyan

    # Build filter query
    $filterParts = @()

    if ($Subject) {
        $filterParts += "contains(subject, '$Subject')"
    }

    if ($From) {
        $filterParts += "from/emailAddress/address eq '$From'"
    }

    if ($StartDate) {
        $startDateTime = Get-Date $StartDate -Format "yyyy-MM-ddTHH:mm:ssZ"
        $filterParts += "receivedDateTime ge $startDateTime"
    }

    if ($EndDate) {
        $endDateTime = Get-Date $EndDate -Format "yyyy-MM-ddTHH:mm:ssZ"
        $filterParts += "receivedDateTime le $endDateTime"
    }

    $filter = if ($filterParts.Count -gt 0) { $filterParts -join ' and ' } else { $null }

    # Search messages
    $params = @{
        UserId = $UserId
        Top = $Top
        Property = 'subject,from,receivedDateTime,isRead,hasAttachments,bodyPreview'
        OrderBy = 'receivedDateTime desc'
    }

    if ($filter) {
        $params['Filter'] = $filter
    }

    $messages = Get-MgUserMessage @params

    # Format results
    $results = $messages | ForEach-Object {
        [PSCustomObject]@{
            Subject = $_.Subject
            From = $_.From.EmailAddress.Address
            FromName = $_.From.EmailAddress.Name
            ReceivedDate = $_.ReceivedDateTime
            IsRead = $_.IsRead
            HasAttachments = $_.HasAttachments
            BodyPreview = $_.BodyPreview
            MessageId = $_.Id
        }
    }

    Write-Host "`n✓ Found $($results.Count) matching messages" -ForegroundColor Green

    if ($Subject) { Write-Host "  Subject filter: $Subject" -ForegroundColor Cyan }
    if ($From) { Write-Host "  From filter: $From" -ForegroundColor Cyan }
    if ($StartDate) { Write-Host "  Start date: $StartDate" -ForegroundColor Cyan }
    if ($EndDate) { Write-Host "  End date: $EndDate" -ForegroundColor Cyan }

    if ($ExportPath) {
        $results | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✓ Results exported to: $ExportPath" -ForegroundColor Green
    } else {
        $results | Format-Table Subject, From, ReceivedDate, IsRead, HasAttachments -AutoSize
    }

    return $results
}
catch {
    Write-Error "Email search failed: $_"
}
