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

$deploy = Read-RepoFile "deploy.sh"
$nginx = Read-RepoFile "nginx-deepapi.conf"
$runbook = Read-RepoFile "deepapi-project-doc.md"
$billing = Read-RepoFile "MANUAL-BILLING-SOP.md"
$balanceLimits = Read-RepoFile "BALANCE-BILLING-LIMITS.md"
$oneApiLimits = Read-RepoFile "ONEAPI-LIMITS-RUNBOOK.md"

Assert-True (-not $deploy.Contains("/etc/docker/daemon.json")) "deploy.sh must not overwrite Docker daemon configuration"
Assert-True (-not $deploy.Contains("systemctl restart docker")) "deploy.sh must not restart the Docker daemon"
Assert-True ($deploy.Contains("if ! command -v docker")) "deploy.sh must not reinstall or upgrade Docker on every deploy"
Assert-True ($deploy.Contains("docker rename")) "deploy.sh must retain a rollback container during replacement"
Assert-True ($deploy.Contains("deepapi.rollback")) "deploy.sh must retain and restore the previous Nginx config"
Assert-True ($deploy.Contains("healthcheck.sh")) "deploy.sh must install and use the health check"
Assert-True ($deploy.Contains("backup.sh")) "deploy.sh must install the consistent backup job"
Assert-True ($deploy.Contains("predeploy-backup-gate.sh")) "deploy.sh must install the pre-deploy backup gate"
Assert-True ($deploy.Contains("/usr/local/sbin/deepapi-predeploy-backup-gate")) "deploy.sh must run the pre-deploy backup gate"
Assert-True (-not $deploy.Contains(". /etc/deepapi/backup.env")) "deploy.sh and cron must not directly source a root job config"
Assert-True ($deploy.Contains("--log-opt max-size=")) "deploy.sh must configure per-container log rotation"
Assert-True ($deploy.Contains("--security-opt no-new-privileges:true")) "one-api must prevent privilege escalation"
Assert-True ($deploy.Contains("--cap-drop ALL")) "one-api must drop Linux capabilities"
Assert-True ($nginx.Contains("__DOMAIN__")) "Nginx config must be rendered from DOMAIN"
Assert-True (-not $nginx.Contains("deepapi.click")) "Nginx config must not hard-code the production domain"
Assert-True ((Read-RepoFile "nginx-rate-limit-zones.conf").Contains("zone=api_limit:20m rate=10r/s")) "Nginx API zone must remain 10r/s/IP"
Assert-True ((Read-RepoFile "nginx-rate-limit-zones.conf").Contains("zone=web_limit:10m rate=2r/s")) "Nginx web zone must remain 2r/s/IP"
Assert-True ($nginx.Contains("limit_req zone=api_limit burst=120 nodelay")) "Nginx API burst must remain 120"
Assert-True ($nginx.Contains("limit_req zone=web_limit burst=20 nodelay")) "Nginx web burst must remain 20"

foreach ($requiredLimitText in @(
    "/v1 average 10r/s/IP with burst 120",
    "web average 2r/s/IP with burst 20",
    "Nginx is an IP-layer guardrail",
    "commercial limits must be configured by user, token, and group in one-api",
    "Test users: 60/min, 1000/hour, concurrency 3",
    "Starter: 120/min, 3000/hour, concurrency 5",
    "Vision: 10/min, 100/hour, concurrency 1-2"
)) {
    Assert-True (($runbook + $billing).Contains($requiredLimitText)) "Rate/concurrency policy must document: $requiredLimitText"
}

foreach ($path in @(
    "ops/backup.sh",
    "ops/backup-job.sh",
    "ops/backup.env.example",
    "ops/deepapi-backup.service",
    "ops/deepapi-backup.timer",
    "ops/predeploy-backup-gate.sh",
    "ops/predeploy-backup.evidence.example",
    "ops/restore-verify.sh",
    "ops/healthcheck.sh",
    "ops/healthcheck-notify.sh",
    "ops/RESTORE-DRILL-RUNBOOK.md",
    "ops/MONITORING-RUNBOOK.md",
    "COST-MODEL.md",
    "MODEL-CONTRACT-OPERATIONS.md",
    "VISION-MODEL-RESEARCH.md",
    "SECURITY-BOUNDARIES.md",
    "PRODUCTION-READINESS.md",
    "BALANCE-BILLING-LIMITS.md",
    "ONEAPI-LIMITS-RUNBOOK.md",
    "ops/verify-live-limits.example.sh",
    "POLICIES-GATE.md"
)) {
    Assert-True (Test-Path -LiteralPath (Join-Path $repo $path)) "$path must exist"
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/predeploy-backup-gate.sh")) {
    $gate = Read-RepoFile "ops/predeploy-backup-gate.sh"
    Assert-True ($gate.Contains("deepapi-backup-job")) "pre-deploy gate must create a fresh backup"
    Assert-True ($gate.Contains("sha256sum --check")) "pre-deploy gate must verify the encrypted artifact checksum"
    Assert-True ($gate.Contains("findmnt")) "pre-deploy gate must verify the offsite mount"
    Assert-True ($gate.Contains("restore_verified_at_epoch")) "pre-deploy gate must require restore evidence"
    Assert-True ($gate.Contains("evidence_expires_at_epoch")) "pre-deploy gate must reject stale evidence"
    Assert-True ($gate.Contains("restored_backup_sha256")) "pre-deploy gate must link evidence to the restored backup"
    Assert-True ($gate.Contains("restore_evidence_reference")) "pre-deploy gate must require a restore audit reference"
    Assert-True ($gate.Contains("offsite_evidence_reference")) "pre-deploy gate must require an offsite audit reference"
    Assert-True ($gate.Contains("evidence still contains an example placeholder")) "pre-deploy gate must reject example placeholders"
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/predeploy-backup.evidence.example")) {
    $evidenceExample = Read-RepoFile "ops/predeploy-backup.evidence.example"
    Assert-True ($evidenceExample.Contains("status=NO-GO")) "committed evidence example must fail closed"
    Assert-True (-not $evidenceExample.Contains("status=PASS")) "repository must not contain passing deployment evidence"
}

$gateCall = $deploy.IndexOf("`n  /usr/local/sbin/deepapi-predeploy-backup-gate`n  docker stop")
$stopCall = $deploy.IndexOf('docker stop "${CONTAINER_NAME}"')
Assert-True ($gateCall -ge 0 -and $stopCall -ge 0 -and $gateCall -lt $stopCall) "pre-deploy backup gate must run before stopping the existing container"

if (Test-Path -LiteralPath (Join-Path $repo "ops/backup.sh")) {
    $backup = Read-RepoFile "ops/backup.sh"
    Assert-True ($backup.Contains(".backup")) "backup.sh must use SQLite online backup"
    Assert-True ($backup.Contains("integrity_check")) "backup.sh must verify SQLite integrity"
    Assert-True ($backup.Contains("age --encrypt")) "backup.sh must encrypt backups"
    Assert-True ($backup.Contains("AGE_RECIPIENTS_FILE")) "backup.sh must use an age recipients file"
    Assert-True ($backup.Contains("--recipients-file")) "backup.sh must encrypt with recipients-file"
    Assert-True ($backup.Contains("BACKUP_LOCAL_TMP")) "backup.sh must use a configured local temporary directory"
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/backup.env.example")) {
    $backupEnv = Read-RepoFile "ops/backup.env.example"
    foreach ($requiredBackupEnv in @(
        "BACKUP_OFFSITE_DIR",
        "AGE_RECIPIENTS_FILE",
        "BACKUP_LOCAL_TMP",
        "BACKUP_RETENTION_DAYS",
        "local tarball or same-disk",
        "NO-GO for production"
    )) {
        Assert-True ($backupEnv.Contains($requiredBackupEnv)) "backup.env.example must document: $requiredBackupEnv"
    }
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/deepapi-backup.service")) {
    $backupService = Read-RepoFile "ops/deepapi-backup.service"
    Assert-True ($backupService.Contains("/usr/local/sbin/deepapi-backup-job")) "systemd service must run the validated backup job"
    Assert-True ($backupService.Contains("NoNewPrivileges=true")) "systemd service must include hardening"
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/deepapi-backup.timer")) {
    $backupTimer = Read-RepoFile "ops/deepapi-backup.timer"
    Assert-True ($backupTimer.Contains("OnCalendar=")) "systemd timer must define a schedule"
    Assert-True ($backupTimer.Contains("Persistent=true")) "systemd timer must catch up missed daily backups"
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/restore-verify.sh")) {
    $restore = Read-RepoFile "ops/restore-verify.sh"
    Assert-True ($restore.Contains("age --decrypt")) "restore-verify.sh must decrypt a backup"
    Assert-True ($restore.Contains("integrity_check")) "restore-verify.sh must verify restored SQLite integrity"
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/RESTORE-DRILL-RUNBOOK.md")) {
    $restoreRunbook = Read-RepoFile "ops/RESTORE-DRILL-RUNBOOK.md"
    foreach ($requiredRestoreRunbook in @(
        "Repository tests do not prove live backup readiness",
        "local tarball is NO-GO",
        "offsite encrypted backup",
        "sha256sum --check",
        "BACKUP_AGE_IDENTITY_FILE",
        "one-api recoverability",
        "disposable host"
    )) {
        Assert-True ($restoreRunbook.Contains($requiredRestoreRunbook)) "Restore drill runbook must document: $requiredRestoreRunbook"
    }
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/healthcheck-notify.sh")) {
    $notify = Read-RepoFile "ops/healthcheck-notify.sh"
    Assert-True ($notify.Contains("ALERT_WEBHOOK_URL")) "healthcheck notifier must be webhook-configured by environment"
    Assert-True ($notify.Contains("Inspect one-api, HTTPS, disk")) "healthcheck notifier must identify one-api/HTTPS/disk failures"
    Assert-True (-not $notify.Contains("https://")) "healthcheck notifier must not contain a real or placeholder webhook URL"
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/MONITORING-RUNBOOK.md")) {
    $monitoringRunbook = Read-RepoFile "ops/MONITORING-RUNBOOK.md"
    foreach ($requiredMonitoringRunbook in @(
        "Repository checks do not prove live monitoring",
        "external alert reaches a responsible person",
        "one-api, HTTPS, or disk",
        "ALERT_WEBHOOK_URL",
        "Never commit or paste the real webhook",
        "Local-only logs, terminal output, or repository test passes are NO-GO"
    )) {
        Assert-True ($monitoringRunbook.Contains($requiredMonitoringRunbook)) "Monitoring runbook must document: $requiredMonitoringRunbook"
    }
}

if (Test-Path -LiteralPath (Join-Path $repo "PRODUCTION-READINESS.md")) {
    $readiness = Read-RepoFile "PRODUCTION-READINESS.md"
    Assert-True ($readiness.Contains("Owner")) "Production readiness gates must name owners"
    Assert-True ($readiness.Contains("Evidence")) "Production readiness gates must require evidence"
    Assert-True ($readiness.Contains("NO-GO")) "Production readiness gates must define NO-GO conditions"
    Assert-True ($readiness.Contains("SECURITY-BOUNDARIES.md")) "Production readiness must include the backend security boundaries gate"
    Assert-True ($readiness.Contains("Backend security boundaries")) "Production readiness must name the backend security boundaries gate"
    Assert-True ($readiness.Contains("MODEL-CONTRACT-OPERATIONS.md")) "Production readiness must use the model-contract operations gate"
    Assert-True ($readiness.Contains("verify-model-contract.sh")) "Production readiness must use the model-contract verifier"
    Assert-True ($readiness.Contains("Vision request acceptance")) "Production readiness must require live vision acceptance tests"
    Assert-True ($readiness.Contains("Vision input security")) "Production readiness must require vision input security tests"
    Assert-True ($readiness.Contains("illegal internal URL")) "Vision input gate must test internal URL rejection"
    Assert-True ($readiness.Contains("metadata address")) "Vision input gate must test metadata-address rejection"
    Assert-True ($readiness.Contains("oversized base64")) "Vision input gate must test oversized base64 rejection"
    Assert-True ($readiness.Contains("malformed image")) "Vision input gate must test malformed image rejection"
    Assert-True ($readiness.Contains("no bodies, image URLs, base64, or credentials")) "Vision evidence must exclude sensitive request data"
    Assert-True ($readiness.Contains("Vision rate limits")) "Production readiness must require live vision rate-limit tests"
    Assert-True ($readiness.Contains("10 requests/minute")) "Production readiness must state the default vision minute limit"
    Assert-True ($readiness.Contains("100 requests/hour")) "Production readiness must state the default vision hourly limit"
    Assert-True ($readiness.Contains("concurrency 1-2")) "Production readiness must state the default vision concurrency limit"
    Assert-True ($readiness.Contains("text and vision quotas are separate")) "Production readiness must require separate text and vision quotas"
    Assert-True ($readiness.Contains("Vision fail-closed behavior")) "Production readiness must require vision fail-closed tests"
    Assert-True ($readiness.Contains("Rate and concurrency enforcement")) "Production readiness must require rate/concurrency verification"
    Assert-True ($readiness.Contains("ordinary model and deepapi-vision")) "Rate/concurrency gate must cover ordinary model and deepapi-vision"
    Assert-True ($readiness.Contains("minute limit, hourly limit, concurrency limit, balance/quota deduction, and over-limit behavior")) "Rate/concurrency gate must verify minute/hour/concurrency limits, billing, and over-limit behavior"
    Assert-True ($readiness.Contains("ops/backup.env.example")) "Production readiness must include backup env sample"
    Assert-True ($readiness.Contains("ops/deepapi-backup.service")) "Production readiness must include backup systemd service"
    Assert-True ($readiness.Contains("ops/deepapi-backup.timer")) "Production readiness must include backup systemd timer"
    Assert-True ($readiness.Contains("local tarball is NO-GO")) "Production readiness must state local tarball backup is NO-GO"
    Assert-True ($readiness.Contains("ops/RESTORE-DRILL-RUNBOOK.md")) "Production readiness must include restore drill runbook"
    Assert-True ($readiness.Contains("Automated restore drill")) "Production readiness must name the automated restore drill gate"
    Assert-True ($readiness.Contains("one-api recoverability")) "Production readiness must require one-api restore recoverability"
    Assert-True ($readiness.Contains("ops/healthcheck-notify.sh")) "Production readiness must include healthcheck notifier"
    Assert-True ($readiness.Contains("ops/MONITORING-RUNBOOK.md")) "Production readiness must include monitoring runbook"
    Assert-True ($readiness.Contains("External monitoring/alerting")) "Production readiness must name external monitoring/alerting"
    Assert-True ($readiness.Contains("one-api, HTTPS, and disk anomalies")) "Production readiness must require one-api/HTTPS/disk alerting"
    Assert-True ($readiness.Contains("They do not prove live offsite backup, automated restore drill, external")) "Production readiness must not claim repository tests prove live operations"
    Assert-True ($readiness.Contains("Balance and user self-service")) "Production readiness must include balance and user self-service gate"
    Assert-True ($readiness.Contains("one-api package limits")) "Production readiness must include one-api package limits gate"
    Assert-True ($readiness.Contains("ONEAPI-LIMITS-RUNBOOK.md")) "Production readiness must reference the one-api limits runbook"
    Assert-True ($readiness.Contains("ops/verify-live-limits.example.sh")) "Production readiness must reference the live limit verification template"
    Assert-True ($readiness.Contains("Gateway charge, provider cost, input/output/cache/image usage, balance/quota changes")) "Production readiness must require billing reconciliation dimensions"
    Assert-True (-not $readiness.Contains("DEEPSEEK-ONLY-OPERATIONS.md")) "Production readiness must not reference the old DeepSeek-only gate"
    Assert-True (-not $readiness.Contains("verify-deepseek-only.sh")) "Production readiness must not reference the old DeepSeek-only verifier"
}

foreach ($requiredBalanceText in @(
    "one-api quota or balance value, using the exact unit exposed by one-api",
    "If one-api displays quota instead of a USD balance",
    "Customers who receive only an API Key and no one-api login cannot self-serve",
    "provisioned as one-api user accounts",
    '`/v1` average 10r/s/IP with burst 120',
    "configured in one-api at the user, token, and group layers",
    "Test users | 60/min | 1000/hour | 3",
    "Starter | 120/min | 3000/hour | 5",
    "Vision | 10/min | 100/hour | 1-2",
    "ordinary model",
    "deepapi-vision",
    "Minute limit enforcement",
    "Hourly limit enforcement",
    "Concurrency enforcement",
    "Balance/quota deduction after successful requests",
    "Rejected requests create no upstream usage",
    "Gateway charge by account, token, group, model, and request",
    "Input tokens, output/reasoning tokens, cache-hit input, cache-miss input",
    "Starting balance/quota",
    "Difference between gateway charge and provider bill"
)) {
    Assert-True ($balanceLimits.Contains($requiredBalanceText)) "Balance/billing/limit gate must document: $requiredBalanceText"
}

foreach ($requiredBillingText in @(
    "one-api quota or balance unit",
    "customer cannot self-serve a",
    "cache-hit input, cache-miss input, image units",
    "Confirm over-limit and rejected requests created no upstream"
)) {
    Assert-True ($billing.Contains($requiredBillingText)) "Manual billing SOP must document: $requiredBillingText"
}

foreach ($requiredOneApiText in @(
    "This runbook defines the live one-api configuration",
    "completing this file does not mean the live one-api admin settings have been configured",
    "one-api login account",
    "Issuing only an API Key is not enough for self-service",
    "user, token, and group layers",
    "average 10r/s/IP with burst",
    "Test users | test | 60/min | 1000/hour | 3",
    "Starter | starter | 120/min | 3000/hour | 5",
    "Vision | vision | 10/min | 100/hour | 1-2",
    "Vision usage must not consume text quota",
    "Text usage must not consume vision quota",
    "Minute limit enforcement",
    "Hourly limits reject excess requests",
    "Concurrency limits reject excess requests",
    "Successful requests deduct the correct balance/quota unit",
    "Over-limit and rejected requests create no upstream provider usage",
    "Do not record prompt bodies",
    "no upstream model names"
)) {
    Assert-True ($oneApiLimits.Contains($requiredOneApiText)) "One-api limits runbook must document: $requiredOneApiText"
}

$liveLimitScript = Read-RepoFile "ops/verify-live-limits.example.sh"
foreach ($requiredScriptText in @(
    "TEST_USER_TOKEN",
    "read -r -s TEST_USER_TOKEN",
    "Authorization: Bearer",
    "/v1/models",
    "/v1/chat/completions",
    "ILLEGAL_PAYLOAD_FILE",
    "MINUTE_ATTEMPTS",
    "HOURLY_ATTEMPTS",
    "CONCURRENCY_ATTEMPTS",
    "RUN_LIVE_LIMIT_LOAD",
    "Token: [hidden]",
    "Do not store prompt bodies",
    "Rejected requests must create no upstream usage"
)) {
    Assert-True ($liveLimitScript.Contains($requiredScriptText)) "Live limit template must include: $requiredScriptText"
}

Assert-True (-not $liveLimitScript.Contains("set -x")) "Live limit template must not echo commands or secrets"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "FAIL: $_" }
    exit 1
}

Write-Output "Production readiness static checks passed."
