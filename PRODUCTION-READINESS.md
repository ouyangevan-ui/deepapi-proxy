# Production Readiness Gates

Repository checks reduce risk but do not prove the live service is ready.
Production is **NO-GO** until every required gate below has dated evidence.

| Gate | Owner | Acceptance command or action | Evidence | GO condition |
| --- | --- | --- | --- | --- |
| Repository revision | Engineering | `git fetch --prune && git rev-list --left-right --count HEAD...origin/master` | Output showing `0 0` plus commit ID | Deployed revision is reviewed revision |
| Historical exposure evidence | Security owner | Confirm the completed rotation and old-value invalidation without copying sensitive values | Dated screenshots/audit records with values redacted | Fixed-and-rotated record is complete; old values cannot authenticate |
| Admin authentication | Security owner | Verify unique admin access, strong authentication, recovery path, and least privilege | Redacted settings evidence and recovery test | Default/shared access removed |
| SSH hardening | Infrastructure owner | `sshd -T` and key-only login test | Redacted command output and successful test | Password/root policy approved |
| Network exposure | Infrastructure owner | `ss -ltnp`, `ufw status verbose` | Redacted output | Only approved public ports; app bound to localhost |
| Edge/rate-limit identity | Infrastructure owner | Verify direct/CDN path and force rate limits from independent clients | Redacted Nginx/access evidence | Limits use the intended client identity without trusting spoofed headers |
| Registration/access | Product owner | Inspect one-api settings and create one paid test user | Screenshots plus test record | Open registration/free credit disabled |
| Live brand application | Product owner | Complete `brand/APPLICATION.md` and inspect in a private browser window | Screenshots of tab, login, header, homepage, About, and footer | DeepAPI name/icon/favicon visible; no old or misleading brand content |
| Model contract channels/models | Product owner | Complete `MODEL-CONTRACT-OPERATIONS.md` and run `verify-model-contract.sh` | Redacted channel/model inventory plus command output | Launch users see exactly `deepseek-v4-flash`, `deepseek-v4-pro`, and `deepapi-vision`; legacy aliases fail closed |
| Vision provider approval | Product owner + counsel | Complete `VISION-MODEL-RESEARCH.md`, select one provider/model, and approve provider, region, terms, privacy, and resale/proxy risk | Dated official docs, rate card, terms copy, and approval record | One China vision model is approved for `deepapi-vision`; otherwise production is NO-GO |
| Vision request acceptance | Product owner | Run non-sensitive `deepapi-vision` image URL and base64 data-URI tests | Redacted request times, response status, model/channel, usage counters, and provider billing evidence | Both image URL and base64 succeed and bill correctly |
| Vision fail-closed behavior | Product + finance owners | Test unsupported model, legacy aliases, and image payloads sent to DeepSeek text models | Redacted 4xx results and provider usage check | Invalid names and DeepSeek-with-image requests return 4xx and create no upstream usage |
| Legacy model retirement | Product owner | Inventory migration-group users and test old aliases after the internal cutoff | Redacted inventory, customer migration evidence, and 4xx test | No legacy alias remains usable after 2026-07-17 15:59 UTC |
| Billing accuracy | Finance owner | Reconcile text and vision test usage to gateway and provider billing | Dated reconciliation worksheet | Input/output/image usage and actual cost delta approved by model |
| Cost model | Business owner | Complete `COST-MODEL.md` scenarios | Approved private workbook | All scenarios pass loss/margin limits |
| Privacy/logging | Privacy owner | Inventory Nginx, Docker, journal, one-api, payment, text-provider, and vision-provider logs | Approved retention/deletion matrix | Public policy discloses provider, image data handling, retention, deletion, and transfers |
| Encrypted offsite backup | Infrastructure owner | Run `deepapi-backup`; verify mount with `findmnt -T "$BACKUP_OFFSITE_DIR"` | Encrypted artifact, checksum, separate-mount output, and proof the mount transfers off-host | Fresh backup exists off host |
| Restore drill | Infrastructure owner | Run `deepapi-restore-verify BACKUP_FILE`, then recover a disposable host | Command output and dated drill notes | Integrity and service test pass |
| Pre-deploy backup evidence | Infrastructure owner | After the offsite/restore drills, create root-owned mode `0600` `/etc/deepapi/predeploy-backup.evidence` from `ops/predeploy-backup.evidence.example` | Evidence file naming reviewer, restored backup SHA-256, non-sensitive audit references, verified mount, PASS results, and unexpired epoch timestamps | `deepapi-predeploy-backup-gate` passes; otherwise updating an existing container is blocked |
| Monitoring/alerting | On-call owner | Force health-check failure and confirm external notification | Alert screenshot and response timestamp | Alert reaches a responsible person |
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

These commands do not replace live, account, financial, privacy, or legal
evidence.
