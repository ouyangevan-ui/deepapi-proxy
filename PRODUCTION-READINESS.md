# Production Readiness Gates

Repository checks reduce risk but do not prove the live service is ready.
Production is **NO-GO** until every required gate below has dated evidence.

| Gate | Owner | Acceptance command or action | Evidence | GO condition |
| --- | --- | --- | --- | --- |
| Repository revision | Engineering | `git fetch --prune && git rev-list --left-right --count HEAD...origin/master` | Output showing `0 0` plus commit ID | Deployed revision is reviewed revision |
| Historical exposure evidence | Security owner | Confirm the completed rotation and old-value invalidation without copying sensitive values | Dated screenshots/audit records with values redacted | Fixed-and-rotated record is complete; old values cannot authenticate |
| Admin authentication | Security owner | Verify unique admin access, strong authentication, recovery path, and least privilege | Redacted settings evidence and recovery test | Default/shared access removed |
| Backend security boundaries | Security owner | Review `SECURITY-BOUNDARIES.md` row by row and attach redacted evidence for each verification method | Signed boundary checklist, redacted one-api/Nginx/log screenshots, and no-secret evidence references | Every boundary row is accepted; missing or unredacted evidence is NO-GO |
| SSH hardening | Infrastructure owner | `sshd -T` and key-only login test | Redacted command output and successful test | Password/root policy approved |
| Network exposure | Infrastructure owner | `ss -ltnp`, `ufw status verbose` | Redacted output | Only approved public ports; app bound to localhost |
| Edge/rate-limit identity | Infrastructure owner | Verify direct/CDN path and force rate limits from independent clients | Redacted Nginx/access evidence | Limits use the intended client identity without trusting spoofed headers |
| Registration/access | Product owner | Inspect one-api settings and create one paid test user | Screenshots plus test record | Open registration/free credit disabled |
| Balance and user self-service | Product + finance owners | Complete `BALANCE-BILLING-LIMITS.md`; inspect a paid one-api user account and an API-Key-only test record | Redacted screenshots of quota/balance unit, API Keys/tokens, usage logs, and customer wording | Logged-in users can see their own quota/balance unit, API Keys, and usage logs; API-Key-only customers are documented as unable to self-serve unless a manual-statement contract exists |
| Live brand application | Product owner | Complete `brand/APPLICATION.md` and inspect in a private browser window | Screenshots of tab, login, header, homepage, About, and footer | DeepAPI name/icon/favicon visible; no old or misleading brand content |
| Model contract channels/models | Product owner | Complete `MODEL-CONTRACT-OPERATIONS.md` and run `verify-model-contract.sh` | Redacted channel/model inventory plus command output | Launch users see exactly `deepapi-everyday`, `deepapi-advanced`, and `deepapi-vision`; upstream names fail closed |
| Vision provider approval | Product owner + counsel | Complete `VISION-MODEL-RESEARCH.md`, select one provider/model, and approve provider, region, terms, privacy, and resale/proxy risk | Dated official docs, rate card, terms copy, and approval record | One China vision model is approved for `deepapi-vision`; otherwise production is NO-GO |
| Vision request acceptance | Product owner | Run non-sensitive `deepapi-vision` image URL and base64 data-URI tests | Redacted request times, response status, model/channel, usage counters, and provider billing evidence | Both image URL and base64 succeed and bill correctly |
| Vision input security | Product + security owners | Test public image URL, base64 data URI, illegal internal URL, metadata address, oversized base64, malformed image, DeepAPI text-model-with-image, unsupported model, upstream model names, and legacy aliases | Redacted pass/fail, model, channel, usage, deduction, provider-usage, and reviewer evidence; no bodies, image URLs, base64, or credentials | Valid public URL/base64 pass; SSRF, oversize, malformed, invalid-model, upstream-name, legacy, and text-model-with-image cases fail closed with no upstream usage |
| Vision rate limits | Product + infrastructure owners | Configure test-group-only access and force minute, hourly, and concurrent `deepapi-vision` limits | Redacted one-api settings plus 429/queue/rejection evidence | Vision starts at 10 requests/minute, 100 requests/hour, concurrency 1-2; text and vision quotas are separate |
| Model fail-closed behavior | Product + finance owners | Test unsupported model, upstream model names, and image payloads sent to DeepAPI text models; includes Vision fail-closed behavior | Redacted 4xx results and provider usage check | Invalid names, upstream names, and text-with-image requests return 4xx and create no upstream usage |
| Billing accuracy | Finance owner | Reconcile text and vision test usage to gateway and provider billing | Dated reconciliation worksheet | Gateway charge, provider cost, input/output/cache/image usage, balance/quota changes, and upstream bill delta are approved by model |
| Rate and concurrency enforcement | Product + finance owners | With a test key, exercise an ordinary model and deepapi-vision: `deepapi-everyday`, `deepapi-advanced`, and `deepapi-vision` against one-api user/token/group settings | Redacted request windows, one-api settings screenshots, usage logs, balance/quota deltas, and provider usage check | Configured minute limit, hourly limit, concurrency limit, balance/quota deduction, and over-limit behavior match policy; rejected requests create no upstream usage |
| Cost model | Business owner | Complete `COST-MODEL.md` scenarios | Approved private workbook | All scenarios pass loss/margin limits |
| Privacy/logging | Privacy owner | Inventory Nginx, Docker, journal, one-api, payment, text-provider, and vision-provider logs | Approved retention/deletion matrix | Public policy discloses provider, image data handling, retention, deletion, and transfers |
| Encrypted offsite backup | Infrastructure owner | Configure root-only `/etc/deepapi/backup.env` from `ops/backup.env.example`, install `ops/deepapi-backup.service` and `ops/deepapi-backup.timer`, run `deepapi-backup`, and verify mount with `findmnt -T "$BACKUP_OFFSITE_DIR"` | Encrypted artifact, checksum, separate-mount output, systemd timer status, and proof the mount transfers off-host | Fresh backup exists off host; local tarball is NO-GO |
| Automated restore drill | Infrastructure owner | Follow `ops/RESTORE-DRILL-RUNBOOK.md`: run `deepapi-restore-verify BACKUP_FILE`, then recover a disposable directory or alternate host | Command output, restored backup SHA-256, dated drill notes, redacted one-api recovery evidence, and reviewer | Checksum, decryption, SQLite integrity, and one-api recoverability pass |
| Pre-deploy backup evidence | Infrastructure owner | After the offsite/restore drills, create root-owned mode `0600` `/etc/deepapi/predeploy-backup.evidence` from `ops/predeploy-backup.evidence.example` | Evidence file naming reviewer, restored backup SHA-256, non-sensitive audit references, verified mount, PASS results, and unexpired epoch timestamps | `deepapi-predeploy-backup-gate` passes; otherwise updating an existing container is blocked |
| External monitoring/alerting | On-call owner | Configure `ops/healthcheck-notify.sh` using `ops/MONITORING-RUNBOOK.md`; force one-api, HTTPS, and disk failures and confirm external notification | Redacted alert screenshot, delivery timestamp, owner acknowledgement, and no webhook secret in Git/logs/screenshots | Alert reaches a responsible person for one-api, HTTPS, and disk anomalies |
| Upstream outage behavior | Product + on-call owners | Simulate upstream timeout/error in staging and observe customer response and any configured switch | Redacted drill record | Approved graceful-failure or tested-switch behavior |
| Rollback | Infrastructure owner | Deploy a known-failing candidate in staging and observe rollback | Container/status output and drill notes | Previous version returns healthy |
| Host failover | Infrastructure owner | Recover replacement VPS from backup and switch test DNS | Timed drill record | Approved RTO/RPO met |
| Image/supply chain | Security owner | Scan pinned image digest and review upstream maintenance/release notes | Dated scan report and approval | No unaccepted critical/high findings |
| Policies/upstream terms | Business owner + counsel | Complete `POLICIES-GATE.md` | Dated approvals and terms copies | Every policy/terms row is GO |

## Repository Verification

Run from the repository:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\production-readiness.Tests.ps1
git diff --check
```

These repository tests only verify that gates, samples, and runbooks are present.
They do not prove live offsite backup, automated restore drill, external
monitoring/alerting, or one-api per-plan rate limiting has been configured.
They do not replace live, account, financial, privacy, or legal evidence.
