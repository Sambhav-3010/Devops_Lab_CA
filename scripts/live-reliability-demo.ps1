param(
    [int]$DurationMinutes = 7,
    [int]$RequestIntervalSeconds = 1,
    [switch]$ScaleToZeroAtEnd
)

$ErrorActionPreference = 'Continue'
$baseUrl = 'http://localhost:8000'
$totalSeconds = [math]::Max(60, $DurationMinutes * 60)
$outageSeconds = if ($ScaleToZeroAtEnd) { 60 } else { 0 }
$trafficSeconds = $totalSeconds - $outageSeconds
$started = Get-Date

function Start-DemoJob([string]$Name, [scriptblock]$Work, [object[]]$Arguments) {
    $job = Start-Job -Name $Name -ScriptBlock $Work -ArgumentList $Arguments
    Write-Host "Started background workload: $Name (job $($job.Id))" -ForegroundColor DarkCyan
    return $job
}

Write-Host 'Starting parallel Kubernetes reliability demonstration.' -ForegroundColor Cyan
Write-Host "Duration: $DurationMinutes minute(s); application: $baseUrl" -ForegroundColor Cyan
Write-Host 'Keep Grafana on Last 5 minutes with 5-second refresh.' -ForegroundColor Cyan

$normalJob = Start-DemoJob 'normal-2xx' {
    param($Url, $Seconds, $Interval)
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        try { Invoke-RestMethod "$Url/health" -TimeoutSec 20 | Out-Null } catch { }
        Start-Sleep -Seconds $Interval
    }
} -Arguments $baseUrl, $trafficSeconds, $RequestIntervalSeconds

$fiveOhThreeJob = Start-DemoJob 'http-503-failures' {
    param($Url, $Seconds)
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        try { Invoke-RestMethod "$Url/fail" -TimeoutSec 20 | Out-Null } catch { }
        Start-Sleep -Seconds 3
    }
} -Arguments $baseUrl, $trafficSeconds

$fiveHundredJob = Start-DemoJob 'http-500-failures' {
    param($Url, $Seconds)
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        try { Invoke-RestMethod "$Url/load?mode=error" -TimeoutSec 20 | Out-Null } catch { }
        Start-Sleep -Seconds 4
    }
} -Arguments $baseUrl, $trafficSeconds

$cpuJob = Start-DemoJob 'cpu-pressure' {
    param($Url, $Seconds)
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        try { Invoke-RestMethod "$Url/load?mode=cpu&seconds=5" -TimeoutSec 20 | Out-Null } catch { }
        Start-Sleep -Seconds 8
    }
} -Arguments $baseUrl, $trafficSeconds

$latencyJob = Start-DemoJob 'p95-p99-latency' {
    param($Url, $Seconds)
    $end = (Get-Date).AddSeconds($Seconds)
    $durations = @(1, 2, 4, 8)
    $index = 0
    while ((Get-Date) -lt $end) {
        $duration = $durations[$index % $durations.Count]
        try { Invoke-RestMethod "$Url/load?mode=cpu&seconds=$duration" -TimeoutSec 30 | Out-Null } catch { }
        $index++
        Start-Sleep -Seconds 3
    }
} -Arguments $baseUrl, $trafficSeconds

$memoryJob = Start-DemoJob 'memory-pressure' {
    param($Url, $Seconds)
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        try { Invoke-RestMethod "$Url/load?mode=memory&mb=15" -TimeoutSec 20 | Out-Null } catch { }
        Start-Sleep -Seconds 15
    }
} -Arguments $baseUrl, $trafficSeconds

try {
    $deleteAt = [math]::Min(120, [math]::Max(30, [math]::Floor($trafficSeconds / 3)))
    while (((Get-Date) - $started).TotalSeconds -lt $trafficSeconds) {
        $elapsed = [math]::Floor(((Get-Date) - $started).TotalSeconds)
        if ($elapsed -ge $deleteAt -and -not $podDeleted) {
            Write-Host 'Deleting one application pod to demonstrate Kubernetes self-healing...' -ForegroundColor Yellow
            $pod = kubectl -n workload-lab get pods -l app=demo-app -o jsonpath='{.items[0].metadata.name}'
            if ($pod) { kubectl -n workload-lab delete pod $pod }
            $podDeleted = $true
        }
        if ($elapsed % 30 -eq 0) {
            Write-Host "Parallel demo running: $elapsed / $trafficSeconds seconds" -ForegroundColor Cyan
        }
        Start-Sleep -Seconds 1
    }

    if ($ScaleToZeroAtEnd) {
        Write-Host 'Final outage phase: scaling demo-app to zero replicas.' -ForegroundColor Red
        kubectl -n workload-lab scale deployment demo-app --replicas=0
        Write-Host "Observing DOWN state and failed requests for $outageSeconds seconds..." -ForegroundColor Red
        Start-Sleep -Seconds $outageSeconds
        Write-Host 'Application remains scaled to zero. Restore it manually with:' -ForegroundColor Yellow
        Write-Host 'kubectl -n workload-lab scale deployment demo-app --replicas=2' -ForegroundColor White
    }
}
finally {
    @($normalJob, $fiveOhThreeJob, $fiveHundredJob, $cpuJob, $latencyJob, $memoryJob) | ForEach-Object {
        Stop-Job $_ -ErrorAction SilentlyContinue
        Remove-Job $_ -Force -ErrorAction SilentlyContinue
    }
}

Write-Host 'Parallel reliability demonstration complete. Review Grafana and Prometheus now.' -ForegroundColor Green
