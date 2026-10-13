$ErrorActionPreference = 'Stop'

& "$PSScriptRoot\preflight.ps1"
& "$PSScriptRoot\build.ps1"

kubectl apply -f "$PSScriptRoot\..\k8s\app.yaml"
kubectl -n workload-lab rollout status deployment/demo-app

& "$PSScriptRoot\install-monitoring.ps1"

kubectl apply -f "$PSScriptRoot\..\k8s\servicemonitor.yaml"
kubectl apply -f "$PSScriptRoot\..\k8s\alerts.yaml"
kubectl apply -f "$PSScriptRoot\..\k8s\dashboard.yaml"

kubectl -n workload-lab get pods,svc,servicemonitor,prometheusrule
kubectl -n monitoring get pods
kubectl -n monitoring rollout status deployment/monitoring-grafana --timeout=180s
kubectl -n monitoring rollout status deployment/monitoring-kube-prometheus-operator --timeout=180s

Write-Host 'Project setup completed.' -ForegroundColor Green
Write-Host 'Next: open separate PowerShell windows for port-forward.ps1, Grafana, and Prometheus.'

