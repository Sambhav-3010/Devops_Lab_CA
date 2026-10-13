param(
    [Parameter(Mandatory = $true)]
    [string]$Stage,
    [Parameter(Mandatory = $true)]
    [string]$FailureText
)

$ErrorActionPreference = 'Stop'
$reportDirectory = Join-Path (Get-Location) 'artifacts'
$reportPath = Join-Path $reportDirectory 'gemini-failure-explanation.md'
New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null

$safeFailure = $FailureText
if ($safeFailure.Length -gt 10000) {
    $safeFailure = $safeFailure.Substring($safeFailure.Length - 10000)
}

$fallback = @"
# Pipeline failure explanation

Gemini analysis was not called because `GEMINI_API_KEY` is not configured.

- **Stage:** $Stage
- **Observed error:**

```
$safeFailure
```

Configure the Gemini API key in Jenkins Credentials to enable AI-assisted explanation.
"@

if ([string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
    Set-Content -Path $reportPath -Value $fallback -Encoding UTF8
    Write-Host 'Gemini skipped: GEMINI_API_KEY is not configured.' -ForegroundColor Yellow
    Write-Host "Fallback report: $reportPath"
    exit 0
}

$baseUrl = if ($env:GEMINI_BASE_URL) { $env:GEMINI_BASE_URL.TrimEnd('/') } else { 'https://generativelanguage.googleapis.com/v1beta' }
$model = if ($env:GEMINI_MODEL) { $env:GEMINI_MODEL } else { 'gemini-2.5-flash' }

$prompt = @"
You are a DevOps pipeline failure analyst using Gemini 2.5 Flash. Analyze the Jenkins failure below.
Do not invent facts. Do not request or expose secrets. Do not print environment-file contents or API keys.
Return concise Markdown with exactly these sections:
1. What failed
2. Evidence
3. Most likely root cause
4. Immediate fix
5. Prevention in the pipeline
6. Deployment impact

Pipeline stage: $Stage
Failure output:
$safeFailure
"@

$payload = @{
    system_instruction = @{ parts = @(@{ text = 'You explain CI/CD failures for students using precise evidence-based language.' }) }
    contents = @(@{ role = 'user'; parts = @(@{ text = $prompt }) })
    generationConfig = @{
        temperature = if ($env:LLM_TEMPERATURE) { [double]$env:LLM_TEMPERATURE } else { 0.2 }
        topP = if ($env:LLM_TOP_P) { [double]$env:LLM_TOP_P } else { 0.9 }
        maxOutputTokens = if ($env:LLM_MAX_TOKENS) { [int]$env:LLM_MAX_TOKENS } else { 8192 }
    }
} | ConvertTo-Json -Depth 8

try {
    $response = Invoke-RestMethod `
        -Method Post `
        -Uri "$baseUrl/models/$model`:generateContent?key=$([uri]::EscapeDataString($env:GEMINI_API_KEY))" `
        -Headers @{ Accept = 'application/json' } `
        -ContentType 'application/json' `
        -Body $payload `
        -TimeoutSec 90

    $explanation = ($response.candidates[0].content.parts | ForEach-Object { $_.text }) -join "`n"
    if ([string]::IsNullOrWhiteSpace($explanation)) {
        throw 'Gemini returned an empty explanation.'
    }

    Set-Content -Path $reportPath -Value "# Gemini Pipeline Analysis`n`n$explanation" -Encoding UTF8
    Write-Host "Gemini explanation written to $reportPath" -ForegroundColor Cyan
}
catch {
    Set-Content -Path $reportPath -Value ($fallback + "`nGemini request error: " + $_.Exception.Message) -Encoding UTF8
    Write-Warning "Gemini analysis failed, but the original pipeline failure will remain the build result: $($_.Exception.Message)"
}

exit 0
