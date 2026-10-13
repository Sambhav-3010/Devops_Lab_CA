$ErrorActionPreference = 'Stop'

function Require-Command($name, $hint) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "$name is not installed or is not on PATH. $hint"
    }
}

Require-Command 'docker' 'Install Docker Desktop and reopen PowerShell.'
Require-Command 'kubectl' 'Install kubectl or use the Docker Desktop bundled CLI.'

$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    if ($dockerInfo -match 'permission denied|Access is denied') {
        throw "Docker Desktop is running, but this PowerShell identity cannot access its named pipe. Run the project from the same Windows user session that started Docker Desktop, or add that user to the docker-users group and sign out/in."
    }
    throw "Docker Engine is unavailable. Start Docker Desktop as your Windows user and wait until it reports Running. If it will not start, enable WSL 2/virtualization and repair Docker Desktop's Windows service permissions."
}

$contexts = @(kubectl config get-contexts -o name 2>$null)
if ($contexts -notcontains 'docker-desktop') {
    throw "kubectl has no docker-desktop context. In Docker Desktop, enable Kubernetes, wait for the cluster to become Running, then reopen PowerShell."
}

kubectl config use-context docker-desktop | Out-Null
kubectl get nodes
if ($LASTEXITCODE -ne 0) {
    throw "The docker-desktop Kubernetes API is not ready. Wait for Docker Desktop Kubernetes to finish starting and run this check again."
}

Require-Command 'helm' 'Install Helm 3 with: winget install --id Helm.Helm --exact --source winget. Then close and reopen PowerShell.'

Write-Host 'Preflight passed: Docker Engine, Helm, kubectl, and Docker Desktop Kubernetes are ready.' -ForegroundColor Green

