# DeepAPI Readiness Summary

## Status

**Repository hardening implemented; production remains NO-GO pending manual
evidence.**

The initial product uses public model names: `deepapi-everyday`,
`deepapi-advanced`, and, after provider approval, `deepapi-vision`. OpenAI
compatibility refers only to the protocol and does not imply OpenAI models,
endorsement, or partnership.

Upstream names are not launch models. Ordinary users must never see or call
`deepseek-*`, `qwen-*`, `gpt-*`, `claude-*`, or `gemini-*`; those names are
administrator-only mapping and provider records.

## Eliminated In Repository

- Deployment no longer overwrites Docker daemon configuration or restarts the
  Docker daemon.
- Deployment no longer deletes the previous container before validating the
  replacement; it retains and restores a rollback container on failure.
- The Nginx domain is rendered from the validated `DOMAIN` input.
- Docker logs use per-container rotation.
- Docker is installed only when absent instead of upgraded on every deploy; the
  application container prevents privilege escalation and drops Linux
  capabilities.
- Online SQLite tar backup was replaced by a consistent SQLite snapshot,
  integrity check, encrypted offsite destination requirement, checksum, and
  restore verification.
- Updating an existing container is blocked unless a fresh encrypted backup
  passes checksum/mount checks and an unexpired root-only evidence file records
  a human-observed offsite transfer and successful restore drill.
- A privacy-safe local health check and scheduled failure signal were added.
- DeepAPI brand assets are installed by `deploy.sh`; Nginx serves stable asset
  URLs and overrides one-api's bundled fallback logo and favicon paths.
- Product and architecture docs no longer approve open registration, unlimited
  plans, fixed high token bundles, unverified margin/capacity/failover claims,
  or "no logs" language.
- Commercial cost and legal/policy/upstream-terms gates now name owners,
  evidence, and NO-GO conditions.

## Remaining Manual Gates

Production remains NO-GO until owners provide dated evidence for live access
revocation/replacement, SSH/network hardening, registration state, billing and
cost reconciliation, privacy/log retention, external alert delivery, rollback,
encrypted offsite backup, restore and replacement-host recovery drills, public
policies, and upstream resale rights.

The repository cannot automatically prove that storage is truly off-host or
that recovery works. Deployment therefore requires accountable, expiring manual
evidence and remains NO-GO if that evidence is absent or stale.

It also remains NO-GO until `MODEL-CONTRACT-OPERATIONS.md` confirms every
non-approved channel/model/alias is disabled or deleted, both public text
models route to DeepSeek and bill correctly, `deepapi-vision` routes only to
the approved China vision provider, image URL and base64 tests pass, and
upstream-name or text-with-image requests return 4xx without upstream usage.

The live one-api brand settings are also a manual gate. Follow
`brand/APPLICATION.md` to set System Name and Logo, replace old
Homepage/About/Footer content, and verify the page title, header icon, and
browser favicon in a private browser window.

The historical credential exposure is fixed and affected API credentials,
keys, and tokens have been rotated. This confirmation is recorded without
reproducing sensitive values; retain only redacted rotation, invalidation, and
health-check evidence.

See `PRODUCTION-READINESS.md` for the controlling checklist.
