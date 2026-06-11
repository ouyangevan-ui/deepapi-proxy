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
    "ops/predeploy-backup-gate.sh",
    "ops/predeploy-backup.evidence.example",
    "ops/restore-verify.sh",
    "ops/healthcheck.sh",
    "COST-MODEL.md",
    "MODEL-CONTRACT-OPERATIONS.md",
    "VISION-MODEL-RESEARCH.md",
    "PRODUCTION-READINESS.md",
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
}

if (Test-Path -LiteralPath (Join-Path $repo "ops/restore-verify.sh")) {
    $restore = Read-RepoFile "ops/restore-verify.sh"
    Assert-True ($restore.Contains("age --decrypt")) "restore-verify.sh must decrypt a backup"
    Assert-True ($restore.Contains("integrity_check")) "restore-verify.sh must verify restored SQLite integrity"
}

if (Test-Path -LiteralPath (Join-Path $repo "PRODUCTION-READINESS.md")) {
    $readiness = Read-RepoFile "PRODUCTION-READINESS.md"
    Assert-True ($readiness.Contains("Owner")) "Production readiness gates must name owners"
    Assert-True ($readiness.Contains("Evidence")) "Production readiness gates must require evidence"
    Assert-True ($readiness.Contains("NO-GO")) "Production readiness gates must define NO-GO conditions"
    Assert-True ($readiness.Contains("MODEL-CONTRACT-OPERATIONS.md")) "Production readiness must use the model-contract operations gate"
    Assert-True ($readiness.Contains("verify-model-contract.sh")) "Production readiness must use the model-contract verifier"
    Assert-True ($readiness.Contains("Vision request acceptance")) "Production readiness must require live vision acceptance tests"
    Assert-True ($readiness.Contains("Vision rate limits")) "Production readiness must require live vision rate-limit tests"
    Assert-True ($readiness.Contains("10 requests/minute")) "Production readiness must state the default vision minute limit"
    Assert-True ($readiness.Contains("100 requests/hour")) "Production readiness must state the default vision hourly limit"
    Assert-True ($readiness.Contains("concurrency 1-2")) "Production readiness must state the default vision concurrency limit"
    Assert-True ($readiness.Contains("text and vision quotas are separate")) "Production readiness must require separate text and vision quotas"
    Assert-True ($readiness.Contains("Vision fail-closed behavior")) "Production readiness must require vision fail-closed tests"
    Assert-True ($readiness.Contains("Rate and concurrency enforcement")) "Production readiness must require rate/concurrency verification"
    Assert-True ($readiness.Contains("ordinary model and deepapi-vision")) "Rate/concurrency gate must cover ordinary model and deepapi-vision"
    Assert-True ($readiness.Contains("rate limit, concurrency limit, balance deduction, and over-limit behavior")) "Rate/concurrency gate must verify limits, billing, and over-limit behavior"
    Assert-True (-not $readiness.Contains("DEEPSEEK-ONLY-OPERATIONS.md")) "Production readiness must not reference the old DeepSeek-only gate"
    Assert-True (-not $readiness.Contains("verify-deepseek-only.sh")) "Production readiness must not reference the old DeepSeek-only verifier"
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "FAIL: $_" }
    exit 1
}

Write-Output "Production readiness static checks passed."
