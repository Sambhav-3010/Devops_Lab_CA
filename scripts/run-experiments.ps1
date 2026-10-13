$ErrorActionPreference = 'Continue'
Write-Host 'Baseline:'
Invoke-RestMethod http://localhost:8000/
Invoke-RestMethod http://localhost:8000/health
Write-Host 'CPU load:'
Invoke-RestMethod 'http://localhost:8000/load?mode=cpu&seconds=20'
Write-Host 'Memory load:'
1..6 | ForEach-Object { Invoke-RestMethod 'http://localhost:8000/load?mode=memory&mb=15' }
Write-Host 'Intentional errors:'
1..20 | ForEach-Object { try { Invoke-RestMethod 'http://localhost:8000/load?mode=error' } catch { Write-Host 'Generated HTTP 500' } }
Write-Host 'Reset:'
Invoke-RestMethod -Method Post http://localhost:8000/reset

