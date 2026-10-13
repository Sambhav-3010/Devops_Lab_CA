param(
    [int]$Seconds = 90,
    [int]$IntervalSeconds = 2
)

$ErrorActionPreference = 'Continue'
$end = (Get-Date).AddSeconds($Seconds)
Write-Host "Generating HTTP 500 traffic for $Seconds seconds. Press Ctrl+C to stop." -ForegroundColor Yellow
while ((Get-Date) -lt $end) {
    try { Invoke-RestMethod 'http://localhost:8000/fail' | Out-Null } catch {}
    Start-Sleep -Seconds $IntervalSeconds
}
Write-Host 'HTTP 500 traffic complete.' -ForegroundColor Green
