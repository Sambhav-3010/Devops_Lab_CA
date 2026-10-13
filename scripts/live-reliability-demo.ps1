param(
    [int]$DurationMinutes = 7,
    [int]$RequestIntervalSeconds = 1
)

$ErrorActionPreference = 'Continue'

function Wait-Seconds($seconds, $message) {
    Write-Host "$message ($seconds seconds)" -ForegroundColor Cyan
    Start-Sleep -Seconds $seconds
}

$trafficJob = Start-Job -ArgumentList $DurationMinutes, $RequestIntervalSeconds -ScriptBlock {
    param($Minutes, $Interval)
    $end = (Get-Date).AddMinutes($Minutes)
    while ((Get-Date) -lt $end) {
        try { Invoke-RestMethod 'http://localhost:8000/health' | Out-Null } catch { }
        Start-Sleep -Seconds $Interval
    }
}

Write-Host 'Phase 1: continuous successful traffic is running.' -ForegroundColor Green
Wait-Seconds 30 'Collecting baseline 2xx traffic'

Write-Host 'Phase 2: CPU pressure and long requests.' -ForegroundColor Yellow
1..4 | ForEach-Object {
    try { Invoke-RestMethod 'http://localhost:8000/load?mode=cpu&seconds=10' | Out-Null } catch { }
}
Wait-Seconds 30 'Allowing p95 and p99 latency to appear'

Write-Host 'Phase 3: retained memory growth.' -ForegroundColor Yellow
1..6 | ForEach-Object {
    try { Invoke-RestMethod 'http://localhost:8000/load?mode=memory&mb=15' | Out-Null } catch { }
}
Wait-Seconds 30 'Allowing memory metrics to appear'

Write-Host 'Phase 4: deterministic HTTP 503 failures.' -ForegroundColor Red
$errorEnd = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $errorEnd) {
    try { Invoke-RestMethod 'http://localhost:8000/fail' | Out-Null } catch { }
    Start-Sleep -Seconds 2
}

Write-Host 'Phase 5: deleting one pod; Kubernetes should replace it.' -ForegroundColor Yellow
$pod = kubectl -n workload-lab get pods -l app=demo-app -o jsonpath='{.items[0].metadata.name}'
if ($pod) { kubectl -n workload-lab delete pod $pod }
Wait-Seconds 30 'Watching self-healing and replica recovery'

Write-Host 'Phase 6: scaling all replicas to zero.' -ForegroundColor Red
kubectl -n workload-lab scale deployment demo-app --replicas=0
Wait-Seconds 75 'Observe unavailable replicas and scrape/outage signals'

Write-Host 'Phase 7: restoring two replicas.' -ForegroundColor Green
kubectl -n workload-lab scale deployment demo-app --replicas=2
kubectl -n workload-lab rollout status deployment/demo-app --timeout=120s
Wait-Seconds 30 'Watching recovery and new successful traffic'

Stop-Job $trafficJob -ErrorAction SilentlyContinue
Remove-Job $trafficJob -Force -ErrorAction SilentlyContinue
Write-Host 'Reliability demo complete. Review Grafana panels and Prometheus alerts.' -ForegroundColor Green
