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

Ordinary users and API clients may see only `deepapi-everyday`,
`deepapi-advanced`, and `deepapi-vision`. Upstream model names appear only in
administrator mapping, provider approval, billing, and incident records.
`deepapi-everyday` maps to the approved DeepSeek fast/daily text model,
`deepapi-advanced` maps to the approved DeepSeek advanced/reasoning model, and
`deepapi-vision` maps to one approved China vision model after
`VISION-MODEL-RESEARCH.md`, `COST-MODEL.md`, and `POLICIES-GATE.md` are GO.
GPT-style aliases and all non-approved channels/models are disabled or deleted.
OpenAI compatibility describes the protocol only; it does not imply OpenAI
models, feature parity, endorsement, or partnership.

Public DeepAPI names must not hide a different modality. If a request with
`deepapi-everyday` or `deepapi-advanced` contains image content, the gateway
must fail closed. Automatic image detection and switching is intentionally not
part of the MVP contract.

Requests using non-public model names, including `deepseek-chat`,
`deepseek-reasoner`, `deepseek-v4-*`, `qwen-*`, `gpt-*`, `claude-*`, and
`gemini-*`, fail closed with 4xx and no upstream usage for ordinary users.

Live one-api channel, group, model, mapping, and ratio settings are operator
controlled. They must be configured and verified with
`MODEL-CONTRACT-OPERATIONS.md` after every restore, migration, provider, or
admin change.

If the pinned one-api image cannot preserve OpenAI-compatible multimodal
message content, enforce the allowlist, or emit reconcilable usage for the
chosen vision provider, keep production NO-GO. The approved fallback is only a
narrow `deepapi-vision` shim in front of one-api, not a broad custom gateway.

## Vision Input Security Boundary

`deepapi-vision` accepts only OpenAI-compatible `messages[].content[]` with text
and `image_url.url` parts. The URL value must be either a public HTTPS image URL
or a base64 data URI image. Text models receiving any image content return 4xx
and do not auto-switch.

The gateway or approved narrow shim must reject SSRF and cost-abuse inputs
before upstream use: localhost, private ranges, link-local ranges, cloud
metadata addresses, DNS results or redirects to internal IPs, non-HTTPS URLs,
oversized image URLs, oversized base64 payloads, malformed images, malicious
images, excessive image count, and requests that exceed the vision model's
context, quota, rate, or concurrency policy. Prompt injection embedded in images
is treated as untrusted model input, not as instructions to the gateway or
operator.

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
