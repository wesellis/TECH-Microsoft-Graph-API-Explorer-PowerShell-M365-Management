<#
.SYNOPSIS
    Generate OneDrive storage usage report.
.DESCRIPTION
    Reports on OneDrive storage utilization per user, including
    total storage, used space, and file counts.
.PARAMETER UserPrincipalName
    Specific user to report on (optional, default: all users).
.PARAMETER MinStorageGB
    Only show users with storage usage above specified GB.
.PARAMETER Period
    Report period: D7, D30, D90, D180 (default: D30).
.PARAMETER ExportPath
    Export report to CSV file.
.EXAMPLE
    .\Get-OneDriveUsageReport.ps1 -MinStorageGB 5 -ExportPath "C:\onedrive-usage.csv"
.EXAMPLE
    .\Get-OneDriveUsageReport.ps1 -UserPrincipalName "user@contoso.com" -Period D90
.NOTES
    Required Permissions: Reports.Read.All, User.Read.All
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName,
    [Parameter(Mandatory = $false)]
    [double]$MinStorageGB,
    [Parameter(Mandatory = $false)]
    [ValidateSet('D7', 'D30', 'D90', 'D180')]
    [string]$Period = 'D30',
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

try {
    $context = Get-MgContext
    if (-not $context) { throw "Not connected to Microsoft Graph." }

    Write-Host "Generating OneDrive usage report (Period: $Period)..." -ForegroundColor Cyan

    # Get OneDrive usage report
    $usageReport = Get-MgReportOneDriveUsageAccountDetail -Period $Period -OutFile "$env:TEMP\onedrive-report.csv"

    # Read the CSV report
    $reportData = Import-Csv "$env:TEMP\onedrive-report.csv"

    # Filter by user if specified
    if ($UserPrincipalName) {
        $reportData = $reportData | Where-Object { $_.'Owner Principal Name' -eq $UserPrincipalName }
    }

    # Process and format data
    $report = $reportData | ForEach-Object {
        $storageUsedGB = [math]::Round([double]$_.'Storage Used (Byte)' / 1GB, 2)
        $storageAllocatedGB = [math]::Round([double]$_.'Storage Allocated (Byte)' / 1GB, 2)
        $percentUsed = if ($storageAllocatedGB -gt 0) {
            [math]::Round(($storageUsedGB / $storageAllocatedGB) * 100, 2)
        } else { 0 }

        [PSCustomObject]@{
            DisplayName = $_.'Owner Display Name'
            UserPrincipalName = $_.'Owner Principal Name'
            IsDeleted = $_.'Is Deleted'
            LastActivityDate = $_.'Last Activity Date'
            FileCount = [int]$_.'File Count'
            ActiveFileCount = [int]$_.'Active File Count'
            StorageUsedGB = $storageUsedGB
            StorageAllocatedGB = $storageAllocatedGB
            PercentUsed = $percentUsed
            SiteUrl = $_.'Site URL'
            ReportPeriod = $_.'Report Period'
        }
    }

    # Filter by minimum storage if specified
    if ($MinStorageGB) {
        $report = $report | Where-Object { $_.StorageUsedGB -ge $MinStorageGB }
    }

    # Exclude deleted users by default
    $report = $report | Where-Object { $_.IsDeleted -eq 'False' }

    # Calculate totals
    $totalUsers = $report.Count
    $totalStorageUsed = ($report | Measure-Object -Property StorageUsedGB -Sum).Sum
    $totalStorageAllocated = ($report | Measure-Object -Property StorageAllocatedGB -Sum).Sum
    $avgStorageUsed = if ($totalUsers -gt 0) { [math]::Round($totalStorageUsed / $totalUsers, 2) } else { 0 }
    $totalFiles = ($report | Measure-Object -Property FileCount -Sum).Sum

    Write-Host "`n✓ OneDrive Usage Report" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Total Users: $totalUsers" -ForegroundColor White
    Write-Host "  Total Storage Used: $([math]::Round($totalStorageUsed, 2)) GB" -ForegroundColor White
    Write-Host "  Total Storage Allocated: $([math]::Round($totalStorageAllocated, 2)) GB" -ForegroundColor White
    Write-Host "  Average Storage per User: $avgStorageUsed GB" -ForegroundColor White
    Write-Host "  Total Files: $totalFiles" -ForegroundColor White

    if ($MinStorageGB) {
        Write-Host "  Filtered: Users with $MinStorageGB+ GB" -ForegroundColor Yellow
    }

    if ($ExportPath) {
        $report | Sort-Object StorageUsedGB -Descending | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "`n✓ Report exported to: $ExportPath" -ForegroundColor Green
    } else {
        $report | Sort-Object StorageUsedGB -Descending | Select-Object -First 25 |
            Format-Table DisplayName, UserPrincipalName, StorageUsedGB, FileCount, LastActivityDate -AutoSize
        Write-Host "`n(Showing top 25 users. Use -ExportPath for full report)" -ForegroundColor Yellow
    }

    # Cleanup temp file
    Remove-Item "$env:TEMP\onedrive-report.csv" -Force -ErrorAction SilentlyContinue

    return $report
}
catch {
    Write-Error "OneDrive usage report failed: $_"
}
