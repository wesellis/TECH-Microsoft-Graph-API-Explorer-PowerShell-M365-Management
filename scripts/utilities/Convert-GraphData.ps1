<#
.SYNOPSIS
    Convert Graph API responses to different output formats.
.DESCRIPTION
    Transforms Graph API JSON responses into CSV, HTML tables, or formatted objects.
    Useful for reporting and data export workflows.
.PARAMETER InputObject
    The Graph API response object to convert.
.PARAMETER OutputFormat
    Output format: CSV, HTML, JSON, Excel, or GridView.
.PARAMETER OutputPath
    File path for export (not needed for GridView).
.EXAMPLE
    Get-MgUser -Top 10 | Convert-GraphData -OutputFormat HTML -OutputPath "C:\users.html"
.NOTES
    Simplifies data export from Graph API responses.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [object]$InputObject,
    [Parameter(Mandatory = $true)]
    [ValidateSet('CSV', 'HTML', 'JSON', 'GridView')]
    [string]$OutputFormat,
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

begin {
    $allData = @()
}

process {
    $allData += $InputObject
}

end {
    try {
        Write-Host "Converting $($allData.Count) objects to $OutputFormat..." -ForegroundColor Cyan

        switch ($OutputFormat) {
            'CSV' {
                if (-not $OutputPath) {
                    throw "OutputPath required for CSV export"
                }
                $allData | Export-Csv -Path $OutputPath -NoTypeInformation
                Write-Host "✓ CSV exported to: $OutputPath" -ForegroundColor Green
            }

            'HTML' {
                if (-not $OutputPath) {
                    throw "OutputPath required for HTML export"
                }
                $html = $allData | ConvertTo-Html -Title "Graph API Data" -PreContent "<h1>Graph API Export</h1><p>Generated: $(Get-Date)</p>"
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "✓ HTML exported to: $OutputPath" -ForegroundColor Green
            }

            'JSON' {
                if (-not $OutputPath) {
                    throw "OutputPath required for JSON export"
                }
                $allData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "✓ JSON exported to: $OutputPath" -ForegroundColor Green
            }

            'GridView' {
                $allData | Out-GridView -Title "Graph API Data - $($allData.Count) items"
            }
        }

        return $allData
    }
    catch {
        Write-Error "Data conversion failed: $_"
    }
}
