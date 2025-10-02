<#
.SYNOPSIS
    Export calendar events from user mailbox.
.DESCRIPTION
    Retrieves calendar events for specified date range and exports
    to CSV for reporting or backup purposes.
.PARAMETER UserId
    User mailbox to export from. Use "me" for current user.
.PARAMETER StartDate
    Start date for event retrieval (format: YYYY-MM-DD).
.PARAMETER EndDate
    End date for event retrieval (format: YYYY-MM-DD).
.PARAMETER Days
    Alternative to EndDate: retrieve events for next X days from StartDate.
.PARAMETER ExportPath
    Export to CSV file.
.EXAMPLE
    .\Get-GraphCalendarEvents.ps1 -UserId "user@contoso.com" -Days 30 -ExportPath "C:\calendar.csv"
.EXAMPLE
    .\Get-GraphCalendarEvents.ps1 -UserId "me" -StartDate "2024-01-01" -EndDate "2024-12-31"
.NOTES
    Required Permissions: Calendars.Read, Calendars.ReadBasic
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$UserId,
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$StartDate,
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$EndDate,
    [Parameter(Mandatory = $false)]
    [int]$Days,
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    # Calculate date range
    if ($Days) {
        $startDateTime = Get-Date
        $endDateTime = $startDateTime.AddDays($Days)
    }
    elseif ($StartDate -and $EndDate) {
        $startDateTime = Get-Date $StartDate
        $endDateTime = Get-Date $EndDate
    }
    else {
        throw "Specify either -Days or both -StartDate and -EndDate"
    }

    Write-Host "Retrieving calendar events for: $UserId" -ForegroundColor Cyan
    Write-Host "  Date range: $($startDateTime.ToString('yyyy-MM-dd')) to $($endDateTime.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

    # Build filter
    $startISO = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $endISO = $endDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")

    $filter = "start/dateTime ge '$startISO' and end/dateTime le '$endISO'"

    # Get calendar events
    $events = Get-MgUserEvent -UserId $UserId -Filter $filter -All `
        -Property 'subject,start,end,location,organizer,attendees,isAllDay,isCancelled,importance'

    # Format results
    $results = $events | ForEach-Object {
        [PSCustomObject]@{
            Subject = $_.Subject
            StartTime = $_.Start.DateTime
            EndTime = $_.End.DateTime
            Location = $_.Location.DisplayName
            Organizer = $_.Organizer.EmailAddress.Address
            OrganizerName = $_.Organizer.EmailAddress.Name
            AttendeeCount = $_.Attendees.Count
            IsAllDay = $_.IsAllDay
            IsCancelled = $_.IsCancelled
            Importance = $_.Importance
            EventId = $_.Id
        }
    }

    Write-Host "`n✓ Found $($results.Count) calendar events" -ForegroundColor Green

    if ($ExportPath) {
        $results | Sort-Object StartTime | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "✓ Calendar exported to: $ExportPath" -ForegroundColor Green
    } else {
        $results | Sort-Object StartTime | Format-Table Subject, StartTime, EndTime, Location, Organizer -AutoSize
    }

    return $results
}
catch {
    Write-Error "Calendar export failed: $_"
}
