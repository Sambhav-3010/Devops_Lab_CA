param(
    [int]$Minutes = 5,
    [int]$IntervalSeconds = 2
)

$ErrorActionPreference = 'Continue'
$trafficJob = Start-Job -ArgumentList $Minutes, $IntervalSeconds -ScriptBlock {
    param($RunMinutes, $DelaySeconds)
    $end = (Get-Date).AddMinutes($RunMinutes)
    while ((Get-Date) -lt $end) {
        try { Invoke-RestMethod 'http://localhost:8000/health' | Out-Null } catch {}
        try { Invoke-RestMethod 'http://localhost:8000/' | Out-Null } catch {}
        Start-Sleep -Seconds $DelaySeconds
    }
}

Write-Host 'Live demo started. Traffic is running in the background.' -ForegroundColor Cyan
Start-Sleep -Seconds 15

Write-Host 'Generating HTTP 500 failures...' -ForegroundColor Yellow
1..20 | ForEach-Object {
    try { Invoke-RestMethod 'http://localhost:8000/fail' | Out-Null } catch {}
}

Write-Host 'Deleting one application pod to demonstrate Kubernetes self-healing...' -ForegroundColor Yellow
$pod = kubectl -n workload-lab get pods -l app=demo-app -o jsonpath='{.items[0].metadata.name}'
if ($pod) { kubectl -n workload-lab delete pod $pod }
Start-Sleep -Seconds 25

Write-Host 'Scaling the service to zero to demonstrate an outage...' -ForegroundColor Red
kubectl -n workload-lab scale deployment demo-app --replicas=0
Start-Sleep -Seconds 75

Write-Host 'Restoring the service to two replicas...' -ForegroundColor Green
kubectl -n workload-lab scale deployment demo-app --replicas=2
kubectl -n workload-lab rollout status deployment/demo-app --timeout=120s

Write-Host 'Generating post-recovery HTTP 500 traffic so the failure remains visible...' -ForegroundColor Yellow
$errorEnd = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $errorEnd) {
    try { Invoke-RestMethod 'http://localhost:8000/fail' | Out-Null } catch {}
    Start-Sleep -Seconds 2
}

Stop-Job $trafficJob -ErrorAction SilentlyContinue
Remove-Job $trafficJob -Force -ErrorAction SilentlyContinue
Write-Host 'Live demo complete. Review Grafana and Prometheus alerts.' -ForegroundColor Green
