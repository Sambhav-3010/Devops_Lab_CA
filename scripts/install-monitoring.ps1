$ErrorActionPreference = 'Stop'
& "$PSScriptRoot\preflight.ps1"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --create-namespace `
  --set grafana.adminPassword='DevOpsDemo123!' `
  --set grafana.sidecar.dashboards.searchNamespace='ALL' `
  --set nodeExporter.enabled=false

