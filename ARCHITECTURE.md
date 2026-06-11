# DeepAPI Architecture

## Current Topology

```text
Client -> HTTPS Nginx -> 127.0.0.1:3000 one-api -> DeepSeek API
                                                    -> approved China vision API
                              |
                              +-> SQLite data and usage logs
```

The MVP is a single-VPS deployment. It has no automatic host failover and must
not be described as highly available.

## Provider And Model Contract

DeepSeek is the only enabled text provider for the initial product.
one-api must expose and route `deepseek-v4-flash` and `deepseek-v4-pro` only
for text requests. Image analysis is exposed only as the named public model
`deepapi-vision`, mapped to one approved China vision provider after
`VISION-MODEL-RESEARCH.md`, `COST-MODEL.md`, and `POLICIES-GATE.md` are GO.
GPT-style aliases and all non-approved channels/models are disabled or deleted.
OpenAI compatibility describes the protocol only; it does not imply OpenAI
models, feature parity, endorsement, or partnership.

DeepSeek model names must not hide a non-DeepSeek upstream. If a request with
`deepseek-v4-flash` or `deepseek-v4-pro` contains image content, the gateway
must fail closed. Automatic image detection and switching is intentionally not
part of the MVP contract.

`deepseek-chat` and `deepseek-reasoner` are upstream legacy aliases scheduled
for retirement on 2026-07-24 15:59 UTC. They are not public launch models.
Existing callers may temporarily use an isolated migration group until the
earlier DeepAPI cutoff of 2026-07-17 15:59 UTC. Do not remap both aliases to a
generic V4 model unless the gateway can inject and verify the correct thinking
mode; until cutoff, use upstream identity routing for the legacy aliases. After
cutoff, remove them and fail closed.

Live one-api channel, group, model, mapping, and ratio settings are operator
controlled. They must be configured and verified with
`MODEL-CONTRACT-OPERATIONS.md` after every restore, migration, provider, or
admin change.

If the pinned one-api image cannot preserve OpenAI-compatible multimodal
message content, enforce the allowlist, or emit reconcilable usage for the
chosen vision provider, keep production NO-GO. The approved fallback is only a
narrow `deepapi-vision` shim in front of one-api, not a broad custom gateway.

## Controls Implemented In Repository

- `deploy.sh` validates an explicit domain, renders the Nginx template, binds
  one-api to localhost, pins the image digest, and uses container-level log
  rotation. The container prevents privilege escalation and drops Linux
  capabilities.
- Container replacement retains the stopped previous container as a rollback
  point until the new container passes a local health check.
- `ops/healthcheck.sh` checks container state, the local status endpoint, and
  disk usage without printing response bodies.
- `ops/backup.sh` uses SQLite's online backup operation, runs
  `PRAGMA integrity_check`, encrypts with `age`, and requires a separately
  mounted offsite destination.
- `ops/restore-verify.sh` verifies checksum, decryption, archive extraction, and
  SQLite integrity.
- `ops/predeploy-backup-gate.sh` blocks replacement of an existing container
  unless current root-only manual evidence confirms an offsite transfer and
  restore drill; it also creates and checksum-verifies a fresh encrypted backup.
- Nginx provides TLS termination, security headers, request-size limits, and
  separate web/API rate limits.

## Data And Privacy

one-api stores account, channel, billing, and usage-log records in SQLite.
Nginx, Docker, the host journal, payment records, and upstream providers may
also retain metadata or content. Retention and deletion settings are operational
decisions and must match the approved privacy policy before launch.

Never promise zero logging. Minimize log contents, restrict access, set
retention, and document every processor and transfer.

## Failure Model

| Failure | Repository control | Remaining operational requirement |
| --- | --- | --- |
| Bad application image | Health-gated container rollback | Run a rollback drill |
| Process failure | Docker restart policy and health check | Configure external alert delivery |
| VPS failure | Encrypted offsite backup | Provision replacement host and run recovery drill |
| SQLite corruption | Consistent snapshot and integrity check | Test restore on a disposable host |
| DeepSeek outage or removed text model name | No hidden text fallback in initial product | Fail closed and report incident |
| Vision provider outage or removed model name | No hidden reroute under DeepSeek names | Fail closed and report incident |
| Disk exhaustion | Health-check threshold | External alert and response procedure |

## Deployment And Rollback

`deploy.sh` does not overwrite Docker daemon configuration or restart the Docker
daemon. It pulls the pinned image before stopping the current container. The old
container is not stopped until the pre-deploy gate validates current manual
offsite-transfer/restore evidence and a fresh consistent encrypted offsite
backup succeeds. It is then renamed and retained until the replacement passes
health checks. On failure, the script removes the replacement and starts the
rollback container.
The current Nginx site file is also retained until the rendered candidate passes
`nginx -t`.

This protects application rollback, not database schema downgrade. Before an
image change, create and verify an encrypted offsite backup and confirm whether
the image performs irreversible migrations.

## Capacity

No concurrency, user-count, request-volume, or availability claim is approved.
Measure CPU, memory, disk growth, request latency, error rate, and upstream
limits under a representative load test before publishing capacity claims.

## Historical Credential Incident

The historical credential exposure is fixed and affected credentials have been
rotated. Verification records contain no credential values.
