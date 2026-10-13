param(
    [string]$BaseUrl = 'http://localhost:8000',
    [int]$BaselineRequests = 40,
    [int]$SlowRequests = 40
)

$ErrorActionPreference = 'Continue'

function Invoke-TimedRequest([string]$Url) {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Invoke-RestMethod -Uri $Url -TimeoutSec 60 | Out-Null
        $status = 'success'
    } catch {
        $status = 'failed'
    }
    $timer.Stop()
    [pscustomobject]@{
        Url = $Url
        Status = $status
        DurationMs = [math]::Round($timer.Elapsed.TotalMilliseconds, 0)
    }
}

Write-Host 'Latency demonstration started.' -ForegroundColor Cyan
Write-Host 'Keep Grafana open on the p95/p99 panel with a 5-minute time range.' -ForegroundColor Cyan

Write-Host "Phase 1: sending $BaselineRequests normal requests..." -ForegroundColor Green
1..$BaselineRequests | ForEach-Object {
    Invoke-TimedRequest "$BaseUrl/health"
} | Out-Null

Write-Host 'Phase 2: sending controlled slow requests: 1s, 2s, 4s and 8s...' -ForegroundColor Yellow
$durations = @(1, 1, 1, 1, 2, 2, 2, 4, 4, 8)
$results = foreach ($duration in $durations) {
    1..([math]::Max(1, [math]::Floor($SlowRequests / $durations.Count))) | ForEach-Object {
        Invoke-TimedRequest "$BaseUrl/load?mode=cpu&seconds=$duration"
    }
}

Write-Host 'Phase 3: sending normal requests to keep the time series active...' -ForegroundColor Green
1..10 | ForEach-Object {
    Invoke-TimedRequest "$BaseUrl/health"
} | Out-Null

$results | Format-Table -AutoSize
Write-Host 'Expected result: p95 rises above baseline and p99 rises further because of the 4s/8s requests.' -ForegroundColor Magenta
Write-Host 'Wait 15-30 seconds for Grafana refresh. The dashboard uses a 5-minute rate window.' -ForegroundColor Cyan
