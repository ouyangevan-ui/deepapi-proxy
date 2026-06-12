$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        $failures.Add($Message)
    }
}

function Read-RepoFile {
    param([string]$Path)
    return Get-Content -LiteralPath (Join-Path $repo $Path) -Raw
}

$requiredFiles = @(
    "PRD.md",
    "ARCHITECTURE.md",
    "REPORT.md",
    "FINAL-REPORT.md",
    "deepapi-project-doc.md",
    "MANUAL-BILLING-SOP.md",
    "MODEL-CONTRACT-OPERATIONS.md",
    "VISION-MODEL-RESEARCH.md",
    "COST-MODEL.md",
    "POLICIES-GATE.md",
    "PRODUCTION-READINESS.md",
    "verify-model-contract.sh"
)

$text = ""
foreach ($path in $requiredFiles) {
    $fullPath = Join-Path $repo $path
    Assert-True (Test-Path -LiteralPath $fullPath) "$path must exist"
    if (Test-Path -LiteralPath $fullPath) {
        $text += Read-RepoFile $path
    }
}

foreach ($required in @(
    "deepapi-everyday",
    "deepapi-advanced",
    "deepapi-vision",
    "deepseek-v4-flash",
    "deepseek-v4-pro",
    "qwen3-vl-flash",
    "text only",
    "image URL",
    "base64",
    "base64 data URI",
    "messages[].content[]",
    "SSRF",
    "private ranges",
    "metadata addresses",
    "169.254.169.254",
    "oversized base64",
    "malformed images",
    "malicious images",
    "cost explosion",
    "Qwen",
    "GLM",
    "Kimi",
    "OpenAI-compatible",
    "fail closed",
    "no upstream usage",
    "separate vision",
    "10 requests/minute",
    "100 requests/hour",
    "concurrency 1-2",
    "Test group only",
    "separate rate-limit and quota policies",
    "Do not log prompt text",
    "4xx",
    "no upstream usage"
)) {
    Assert-True ($text.Contains($required)) "Model-contract docs must contain: $required"
}

foreach ($stale in @(
    'deepseek-v4-flash`, `deepseek-v4-pro`, and `deepapi-vision`',
    'DeepSeek will retire `deepseek-chat`',
    '2026-07-17 15:59 UTC',
    '2026-07-24 15:59 UTC',
    'Launch accounts expose only `deepseek-v4-flash`',
    'public launch models are `deepseek-v4-flash`',
    'Launch users see exactly `deepseek-v4-flash`',
    'MODEL_POLICY=legacy-migration',
    'legacy-migration',
    'DeepSeek-only: public launch models',
    'only enabled upstream provider',
    'No other model, provider, or GPT-style alias may be exposed or routed during',
    'launch users see only `deepseek-v4-flash` and `deepseek-v4-pro`',
    'verify-deepseek-only.sh',
    'DEEPSEEK-ONLY-OPERATIONS.md',
    'Model access is limited to `deepseek-v4-flash` and/or'
)) {
    Assert-True (-not $text.Contains($stale)) "Model-contract docs contain stale statement: $stale"
}

$verification = Read-RepoFile "verify-model-contract.sh"
Assert-True ($verification.Contains('allowed = {"deepapi-everyday", "deepapi-advanced", "deepapi-vision"}')) "Visible-model verifier must use exact public deepapi allowlist"
Assert-True (-not $verification.Contains("deepseek-v4")) "Visible-model verifier must not expose upstream DeepSeek names"
Assert-True (-not $verification.Contains("qwen")) "Visible-model verifier must not expose upstream vision names"
Assert-True ($verification.Contains('TEST_USER_TOKEN:?')) "Visible-model verifier must require a token without embedding one"

$pricing = Read-RepoFile "static/pricing/index.html"
foreach ($forbiddenPublicName in @("deepseek-v4", "deepseek-chat", "deepseek-reasoner", "qwen3-vl", "gpt-", "claude-", "gemini-")) {
    Assert-True (-not $pricing.Contains($forbiddenPublicName)) "Pricing page must not expose upstream model name: $forbiddenPublicName"
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Model-contract static checks passed."
