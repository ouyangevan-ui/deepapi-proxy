# DeepAPI Production Runbook

DeepAPI remains pre-launch until every required row in
`PRODUCTION-READINESS.md` is GO.

## Deploy

Before deploying, provision `/etc/deepapi/backup.env` as a root-owned `0600`
regular file
containing the offsite mount path, public `age` recipient, database path, and
retention period. Keep private decryption material off the VPS and out of Git.
Confirm the offsite path is a separate mount with `findmnt`.

Before updating an existing container, complete a human-observed offsite
transfer and disposable-host restore drill. Copy
`ops/predeploy-backup.evidence.example` to
`/etc/deepapi/predeploy-backup.evidence`, record only non-sensitive evidence,
including the restored backup SHA-256 and references to the offsite-transfer
and restore audit records; set root ownership and mode `0600`, and set a short
expiry. The deployment gate rejects missing, stale, non-root, permissive,
failed, untraceable, or wrong-mount evidence.
It then creates and checksum-verifies a fresh encrypted backup before stopping
the existing container. This evidence file is an accountable manual attestation,
not automatic proof of recoverability.

Run from the checked-out repository as root:

```bash
DOMAIN=your-domain.example ADMIN_EMAIL=admin@your-domain.example bash deploy.sh
```

Set `ENABLE_WWW=1` only after the `www` DNS name resolves to this service.

The script:

- requires an explicit valid domain and renders the Nginx template;
- binds one-api to `127.0.0.1:3000`;
- pins the one-api image by digest;
- configures per-container log rotation without replacing Docker daemon config;
- keeps the previous container until the replacement is healthy;
- requires a successful encrypted offsite backup before replacing an existing
  container and requires current manual offsite-transfer/restore evidence;
- installs consistent encrypted backup, restore verification, and health-check
  scripts;
- installs and serves the repository-managed DeepAPI logo, icon, and favicon;
- installs cron schedules for local health checks and encrypted offsite backup.

## Verify Deployment

```bash
nginx -t
deepapi-healthcheck
ss -ltnp
ufw status verbose
findmnt -T "$BACKUP_OFFSITE_DIR"
deepapi-backup
deepapi-restore-verify /path/to/encrypted-backup
curl -fsSI "https://${DOMAIN}/brand/deepapi-logo.svg"
curl -fsSI "https://${DOMAIN}/brand/deepapi-icon.svg"
curl -fsSI "https://${DOMAIN}/favicon.svg"
```

Do not treat these commands alone as launch approval. Attach redacted outputs
and drill notes to the matching production-readiness gates.

## Brand Application

Nginx serves stable brand asset URLs and overrides one-api's fallback
`/logo.png` and `/favicon.ico` paths. An administrator must still set the
one-api System Name and Logo URL, then review Homepage, About, and Footer.
Follow [`brand/APPLICATION.md`](brand/APPLICATION.md) for exact values and
visual verification steps. Repository changes do not prove the live settings
were applied.

Use only the assets in `brand/` for public branding, invoices, and customer
emails. Do not use OpenAI logos, OpenAI-style knot/blossom marks, OpenAI Sans,
or copy that implies an official relationship.

## Account And Billing Mode

Keep open registration and free signup credit disabled. After payment is
confirmed, create one manually approved account with explicit balance, quota,
rate limit, enabled models, and expiry. Reconcile input tokens, output tokens,
gateway deductions, and upstream invoice cost.

Do not advertise any plan until the private cost model passes every scenario in
`COST-MODEL.md` and policies pass `POLICIES-GATE.md`.

Launch accounts expose only `deepseek-v4-flash`, `deepseek-v4-pro`, and,
after provider approval, `deepapi-vision`. DeepSeek models are text only; image
analysis requires the explicit `deepapi-vision` model and must never be hidden
behind a DeepSeek model name. `deepseek-chat` and `deepseek-reasoner` are
retiring upstream aliases and must not be enabled for new accounts. Follow
`MODEL-CONTRACT-OPERATIONS.md` for the isolated migration-group policy and the
earlier DeepAPI cutoff of 2026-07-17 15:59 UTC.

## Rate And Concurrency Policy

Current Nginx edge limits are:

| Path | Nginx limit |
| --- | --- |
| `/v1` API | `/v1 average 10r/s/IP with burst 120` |
| Web/UI | `web average 2r/s/IP with burst 20` |

Nginx is an IP-layer guardrail. It cannot enforce paid plan limits, per-user
quotas, or per-token abuse controls. Those commercial limits must be configured
by user, token, and group in one-api; in short, commercial limits must be
configured by user, token, and group in one-api.

Policy: commercial limits must be configured by user, token, and group in one-api.

Recommended one-api launch settings:

| Account/group | Minute limit | Hour limit | Concurrency | Required policy phrase |
| --- | ---: | ---: | ---: |
| Test users | 60/min | 1000/hour | 3 | `Test users: 60/min, 1000/hour, concurrency 3` |
| Starter | 120/min | 3000/hour | 5 | `Starter: 120/min, 3000/hour, concurrency 5` |
| Vision | 10/min | 100/hour | 1-2 | `Vision: 10/min, 100/hour, concurrency 1-2` |

Before accepting payment, verify these settings with a test key for an ordinary
text model and for `deepapi-vision`: allowed requests succeed, concurrent
requests cap correctly, over-limit requests fail closed, balances are deducted
only for billable accepted requests, and rejected requests create no upstream
provider usage.

## Logging And Privacy

The service is not log-free. one-api usage records, Nginx access/error logs,
Docker logs, host journal entries, payment records, and upstream provider logs
may exist. Do not log request or response bodies unless explicitly approved.
Restrict log access, set retention/deletion periods, and ensure public privacy
language matches actual behavior.

## Backup And Restore

`deepapi-backup` uses SQLite online backup, checks integrity, encrypts the
archive, and refuses a destination on the root filesystem. A successful backup
does not prove recoverability. At least monthly, run `deepapi-restore-verify`
and recover a disposable host, then verify login, account/quota state, and a
non-sensitive test request.

After that drill, an accountable infrastructure owner may update the
pre-deploy evidence file with PASS results and expiry. Never set PASS merely to
unblock deployment.

## Monitoring, Failure, And Rollback

The cron health check writes a critical host log entry on failure. Before
launch, connect host failure logs to an external alert path and prove delivery
to the on-call owner. A single VPS has no automatic host failover.

The deploy script retains a stopped rollback container until the new container
passes health checks. Database migrations may still be irreversible, so create
and verify a backup before changing images and run rollback drills in staging.

## Incident Checklist

1. Disable affected customer access and keep registration closed.
2. Stop promotion and payment acceptance if billing, privacy, security, or
   upstream-terms impact is unclear.
3. Rotate or revoke affected access in the relevant system without copying
   sensitive values into tickets or Git.
4. Preserve only the minimum necessary audit evidence with access controls.
5. Reconcile gateway usage, provider billing, payments, refunds, and disputes.
6. Document scope, timeline, owner, notification decision, and recovery proof.

The responsible owner has confirmed the previously exposed API access was
revoked and replaced. Repository evidence cannot independently prove live
provider state; keep the production-readiness remediation gate and its redacted
evidence current.
