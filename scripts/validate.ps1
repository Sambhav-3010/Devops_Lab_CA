$ErrorActionPreference = 'Stop'
& "$PSScriptRoot\preflight.ps1"
kubectl apply --dry-run=client -f k8s/app.yaml | Out-Null
kubectl apply --dry-run=client -f k8s/servicemonitor.yaml | Out-Null
kubectl apply --dry-run=client -f k8s/alerts.yaml | Out-Null
kubectl apply --dry-run=client -f k8s/dashboard.yaml | Out-Null
Write-Host 'Manifest validation passed.'

