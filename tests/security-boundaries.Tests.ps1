$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$docPath = Join-Path $repo "SECURITY-BOUNDARIES.md"
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        $failures.Add($Message)
    }
}

Assert-True (Test-Path -LiteralPath $docPath) "SECURITY-BOUNDARIES.md must exist"

if (Test-Path -LiteralPath $docPath) {
    $doc = Get-Content -LiteralPath $docPath -Raw

    foreach ($column in @(
        "interface_input",
        "login_state",
        "permission_design",
        "password_rule",
        "data_ownership",
        "risk_type",
        "handling_logic",
        "verification_method"
    )) {
        Assert-True ($doc.Contains($column)) "Security boundary table must include anchor column: $column"
    }

    foreach ($boundary in @(
        "admin_login",
        "user_console",
        "api_key_call",
        "model_selection",
        "text_request",
        "vision_request",
        "channel_credentials",
        "user_group_permissions",
        "balance_billing",
        "usage_logs",
        "nginx_boundary",
        "rate_concurrency",
        "static_pricing_page",
        "backup_restore",
        "deploy_script",
        "historical_credential_incident",
        "legal_privacy"
    )) {
        Assert-True ($doc.Contains($boundary)) "Security boundary document must cover: $boundary"
    }

    foreach ($required in @(
        "one-api-admin-is-production-boundary",
        "nginx-ip-guardrail-not-commercial-rate-limit",
        "commercial-limits-by-user-token-group",
        "no-credentials-in-git-chat-screenshots-logs",
        "redacted-admin-screenshots-only",
        "no-default-or-shared-admin",
        "unique-admin",
        "strong-password",
        "recommend-2fa-and-recovery-path",
        "ssh-key-only-or-strongly-restricted"
    )) {
        Assert-True ($doc.Contains($required)) "Security boundary document must state anchor: $required"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "FAIL: $_" }
    exit 1
}

Write-Output "Security boundaries static checks passed."
