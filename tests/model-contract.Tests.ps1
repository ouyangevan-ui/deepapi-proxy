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
    "deepseek-v4-flash",
    "deepseek-v4-pro",
    "deepapi-vision",
    "text only",
    "image URL",
    "base64",
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
    "2026-07-17 15:59 UTC",
    "2026-07-24 15:59 UTC"
)) {
    Assert-True ($text.Contains($required)) "Model-contract docs must contain: $required"
}

foreach ($stale in @(
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
Assert-True ($verification.Contains('text_models = {"deepseek-v4-flash", "deepseek-v4-pro"}')) "Visible-model verifier must keep exact DeepSeek text allowlist"
Assert-True ($verification.Contains('vision_models = {"deepapi-vision"}')) "Visible-model verifier must include the named vision model"
Assert-True ($verification.Contains('legacy_aliases = {"deepseek-chat", "deepseek-reasoner"}')) "Visible-model verifier must identify retiring aliases"
Assert-True ($verification.Contains('legacy_cutoff = datetime(2026, 7, 17, 15, 59')) "Visible-model verifier must fail legacy migration before upstream retirement"
Assert-True ($verification.Contains('MODEL_POLICY="${MODEL_POLICY:-launch}"')) "Visible-model verifier must default to launch policy"
Assert-True ($verification.Contains('TEST_USER_TOKEN:?')) "Visible-model verifier must require a token without embedding one"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Model-contract static checks passed."
