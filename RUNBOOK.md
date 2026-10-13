# Kubernetes Workload Reliability — Command Runbook

Run these commands from PowerShell.

Project directory:

```powershell
cd "C:\Users\sambh\Desktop\Devops Presentation\kubernetes-workload-monitoring"
```

## 1. Check prerequisites

```powershell
docker --version
kubectl version --client
helm version
docker desktop kubernetes status
kubectl config get-contexts
```

Select Docker Desktop Kubernetes:

```powershell
kubectl config use-context docker-desktop
kubectl get nodes
```

Expected node status: `Ready`.

## 2. First-time setup

```powershell
.\scripts\setup.ps1
```

The setup script builds the Node.js image, deploys two application replicas, installs Prometheus/Grafana, creates the ServiceMonitor, installs alert rules, and creates the dashboard.

Verify the application:

```powershell
kubectl get pods -n workload-lab
kubectl get deployment -n workload-lab
kubectl get service -n workload-lab
```

Verify monitoring:

```powershell
kubectl get pods -n monitoring
```

Required core pods should eventually be `Running` and ready:

- Grafana
- Prometheus
- Prometheus Operator
- kube-state-metrics
- Alertmanager

Node-exporter is disabled for Docker Desktop because it is optional and can fail on host-level mounts inside the Docker Desktop VM.

## 3. Start port-forwards

Use separate PowerShell windows. Keep each command running.

### Application

```powershell
kubectl -n workload-lab port-forward service/demo-app 8000:8000
```

Open:

- http://localhost:8000/
- http://localhost:8000/health
- http://localhost:8000/metrics
- http://localhost:8000/fail

### Grafana

```powershell
kubectl -n monitoring port-forward service/monitoring-grafana 3000:80
```

Open: http://localhost:3000

Credentials:

```text
Username: admin
Password: DevOpsDemo123!
```

Dashboard:

```text
http://localhost:3000/d/workload-reliability/kubernetes-workload-reliability
```

### Prometheus

```powershell
kubectl -n monitoring port-forward service/monitoring-kube-prometheus-prometheus 9090:9090
```

Open:

- http://localhost:9090
- http://localhost:9090/targets
- http://localhost:9090/alerts

## 4. Apply dashboard or alert changes

```powershell
kubectl apply -f .\k8s\dashboard.yaml
kubectl apply -f .\k8s\alerts.yaml
```

Refresh Grafana after applying the dashboard ConfigMap.

## 5. Generate normal traffic

This creates continuous successful requests for a fixed duration:

```powershell
.\scripts\generate-traffic.ps1 -Minutes 5 -IntervalSeconds 2
```

Manual successful requests:

```powershell
Invoke-RestMethod http://localhost:8000/
Invoke-RestMethod http://localhost:8000/health
```

## 6. Simulate CPU pressure

```powershell
Invoke-RestMethod "http://localhost:8000/load?mode=cpu&seconds=10"
```

Repeat several times:

```powershell
1..4 | ForEach-Object {
    Invoke-RestMethod "http://localhost:8000/load?mode=cpu&seconds=10"
}
```

Observe CPU and p95/p99 latency in Grafana.

## 7. Simulate memory pressure

```powershell
1..6 | ForEach-Object {
    Invoke-RestMethod "http://localhost:8000/load?mode=memory&mb=15"
}
```

Reset the retained memory:

```powershell
Invoke-RestMethod -Method Post http://localhost:8000/reset
```

## 8. Generate deterministic HTTP 503 failures

The `/fail` route always returns HTTP 503:

```powershell
try {
    Invoke-RestMethod http://localhost:8000/fail
}
catch {
    $_.Exception.Response.StatusCode.value__
}
```

Generate failures for 90 seconds:

```powershell
.\scripts\generate-errors.ps1 -Seconds 90 -IntervalSeconds 2
```

PromQL for the 503 rate:

```promql
sum(rate(demo_http_requests_total{namespace="workload-lab",status="503"}[2m]))
```

## 9. Demonstrate pod self-healing

List application pods:

```powershell
kubectl get pods -n workload-lab
```

Delete one application pod:

```powershell
kubectl delete pod -n workload-lab <demo-app-pod-name>
```

Watch recovery:

```powershell
kubectl get pods -n workload-lab -w
```

Stop watching with `Ctrl+C`.

Expected result: Kubernetes creates a replacement pod because the Deployment desired replica count is two.

## 10. Demonstrate application service DOWN

Scale all application replicas to zero:

```powershell
kubectl scale deployment demo-app -n workload-lab --replicas=0
```

Check state:

```powershell
kubectl get pods -n workload-lab
kubectl get deployment -n workload-lab
```

Grafana should show:

- Application Service State: `DOWN`
- Available replicas: `0`
- Replica availability alert
- Scrape/target failure or missing target

Important: with zero replicas, the Kubernetes Service does not generate application HTTP 5xx responses. Requests may fail with connection refused because no application pod exists. Use `/fail` for application-generated HTTP 503 responses.

Restore the service:

```powershell
kubectl scale deployment demo-app -n workload-lab --replicas=2
kubectl rollout status deployment/demo-app -n workload-lab
```

## 11. Complete automated reliability demo

This runs continuous traffic, CPU pressure, memory pressure, HTTP 503 failures, pod self-healing, outage, and recovery:

```powershell
.\scripts\live-reliability-demo.ps1 -DurationMinutes 7
```

Watch these pages while it runs:

- Grafana: http://localhost:3000/d/workload-reliability/kubernetes-workload-reliability
- Prometheus alerts: http://localhost:9090/alerts
- Prometheus targets: http://localhost:9090/targets

## 12. Useful PromQL

Application scrape status:

```promql
up{namespace="workload-lab"}
```

HTTP requests by status:

```promql
sum by (status) (rate(demo_http_requests_total{namespace="workload-lab"}[2m]))
```

Availability:

```promql
100 * (
  1 -
  (sum(rate(demo_http_requests_total{namespace="workload-lab",status=~"5.."}[5m])) or vector(0))
  /
  clamp_min(sum(rate(demo_http_requests_total{namespace="workload-lab"}[5m])), 0.001)
)
```

p95 latency:

```promql
histogram_quantile(0.95, sum by (le) (rate(demo_http_request_duration_seconds_bucket{namespace="workload-lab"}[5m])))
```

p99 latency:

```promql
histogram_quantile(0.99, sum by (le) (rate(demo_http_request_duration_seconds_bucket{namespace="workload-lab"}[5m])))
```

Available replicas:

```promql
kube_deployment_status_replicas_available{namespace="workload-lab",deployment="demo-app"}
```

Restarts:

```promql
increase(kube_pod_container_status_restarts_total{namespace="workload-lab",container="demo-app"}[15m])
```

## 13. Troubleshooting

Check application resources:

```powershell
kubectl get pods,svc,deploy -n workload-lab
kubectl get events -n workload-lab --sort-by=.lastTimestamp
```

Check monitoring resources:

```powershell
kubectl get pods -n monitoring
kubectl get events -n monitoring --sort-by=.lastTimestamp
```

Check application logs:

```powershell
kubectl logs -n workload-lab deployment/demo-app
```

Check Prometheus target labels:

```powershell
kubectl get servicemonitor -n workload-lab
kubectl get service demo-app -n workload-lab --show-labels
```

If a PowerShell traffic job was interrupted:

```powershell
Get-Job
Get-Job | Stop-Job
Get-Job | Remove-Job -Force
```

## 14. Stop and clean up

Stop only the application:

```powershell
kubectl scale deployment demo-app -n workload-lab --replicas=0
```

Remove the application:

```powershell
kubectl delete namespace workload-lab
```

Remove Prometheus and Grafana:

```powershell
helm uninstall monitoring -n monitoring
```

Disable the local Kubernetes cluster from Docker Desktop only when finished with the project.


## 15. Git and pipeline commands

Initialize and publish the repository:

```powershell
git init
git add .
git commit -m "Initial Kubernetes workload reliability project"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repository>.git
git push -u origin main
```

Run application tests locally:

```powershell
cd app
npm install --no-audit --no-fund
npm test
cd ..
```

The GitHub Actions CI workflow runs automatically on push and pull request. The local CD workflow requires a self-hosted runner because GitHub-hosted runners cannot directly access Docker Desktop Kubernetes. Jenkins can be used instead with the included `Jenkinsfile`.

