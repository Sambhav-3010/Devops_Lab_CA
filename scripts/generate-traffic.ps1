param(
    [int]$Minutes = 5,
    [int]$IntervalSeconds = 2
)

$ErrorActionPreference = 'Continue'
$end = (Get-Date).AddMinutes($Minutes)
$count = 0

Write-Host "Generating demo traffic for $Minutes minute(s). Press Ctrl+C to stop." -ForegroundColor Cyan
while ((Get-Date) -lt $end) {
    $count++
    try { Invoke-RestMethod 'http://localhost:8000/health' | Out-Null } catch { Write-Host 'health request failed' -ForegroundColor Red }
    try { Invoke-RestMethod 'http://localhost:8000/' | Out-Null } catch { Write-Host 'root request failed' -ForegroundColor Red }

    if ($count % 5 -eq 0) {
        try { Invoke-RestMethod 'http://localhost:8000/load?mode=cpu&seconds=2' | Out-Null } catch { Write-Host 'cpu request failed' -ForegroundColor Red }
    }

    if ($count % 7 -eq 0) {
        try { Invoke-RestMethod 'http://localhost:8000/load?mode=error' | Out-Null } catch { Write-Host 'intentional HTTP 500 generated' -ForegroundColor Yellow }
    }

    Start-Sleep -Seconds $IntervalSeconds
}

Write-Host 'Traffic generation complete.' -ForegroundColor Green
