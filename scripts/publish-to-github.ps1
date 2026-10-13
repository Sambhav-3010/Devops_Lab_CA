param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryUrl,
    [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is not on PATH.'
}

git init
git branch -M $Branch
git add .

$pending = git status --short
if ($pending) {
    git commit -m 'Add Kubernetes workload reliability DevOps project'
}

$origin = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0 -and $origin) {
    git remote set-url origin $RepositoryUrl
} else {
    git remote add origin $RepositoryUrl
}

Write-Host "Pushing branch '$Branch' to $RepositoryUrl ..." -ForegroundColor Cyan
git push -u origin $Branch
Write-Host 'GitHub push completed.' -ForegroundColor Green
