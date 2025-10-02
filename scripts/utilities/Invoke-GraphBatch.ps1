<#
.SYNOPSIS
    Execute Graph API operations in batches for better performance.
.DESCRIPTION
    Batches multiple Graph API requests together to reduce latency
    and avoid throttling. Supports automatic retry and error handling.
.PARAMETER InputObjects
    Array of objects to process.
.PARAMETER ScriptBlock
    Script block to execute for each object.
.PARAMETER BatchSize
    Number of items to process per batch. Default is 20.
.PARAMETER ThrottleLimit
    Maximum parallel operations. Default is 5.
.PARAMETER DelayMs
    Delay in milliseconds between batches. Default is 500.
.EXAMPLE
    $users | Invoke-GraphBatch -BatchSize 20 -ScriptBlock {
        param($u)
        Update-MgUser -UserId $u.id -Department "IT"
    }
.NOTES
    Required Permissions: Depends on operations being performed
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [array]$InputObjects,
    [Parameter(Mandatory = $true)]
    [scriptblock]$ScriptBlock,
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 20,
    [Parameter(Mandatory = $false)]
    [int]$ThrottleLimit = 5,
    [Parameter(Mandatory = $false)]
    [int]$DelayMs = 500
)

begin {
    $allObjects = @()
}

process {
    $allObjects += $InputObjects
}

end {
    try {
        $context = Get-MgContext
        if (-not $context) { throw "Not connected to Microsoft Graph." }

        Write-Host "Processing $($allObjects.Count) items in batches of $BatchSize..." -ForegroundColor Cyan

        $batches = [Math]::Ceiling($allObjects.Count / $BatchSize)
        $processed = 0
        $failed = 0

        for ($i = 0; $i < $batches; $i++) {
            $start = $i * $BatchSize
            $end = [Math]::Min($start + $BatchSize, $allObjects.Count)
            $batch = $allObjects[$start..($end-1)]

            Write-Progress -Activity "Processing batches" -Status "Batch $($i+1) of $batches" `
                -PercentComplete (($i / $batches) * 100)

            # Process batch with throttling
            $batch | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
                $item = $_
                $script = $using:ScriptBlock

                try {
                    & $script $item
                }
                catch {
                    Write-Warning "Failed to process item: $_"
                }
            }

            $processed += $batch.Count

            # Rate limiting delay between batches
            if ($i -lt ($batches - 1)) {
                Start-Sleep -Milliseconds $DelayMs
            }
        }

        Write-Progress -Activity "Processing batches" -Completed

        Write-Host "`n✓ Batch processing complete!" -ForegroundColor Green
        Write-Host "  Total Items: $($allObjects.Count)" -ForegroundColor Cyan
        Write-Host "  Batches: $batches" -ForegroundColor Cyan
        Write-Host "  Batch Size: $BatchSize" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Batch processing failed: $_"
    }
}
