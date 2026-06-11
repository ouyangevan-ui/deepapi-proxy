# DeepAPI Project Report

## Current State

DeepAPI is pre-launch and supports manual prepaid onboarding only. Repository
hardening is not equivalent to production approval; `PRODUCTION-READINESS.md`
is the controlling go/no-go checklist.

The initial product provides DeepSeek text models (`deepseek-v4-flash` and
`deepseek-v4-pro`) plus a named China vision model (`deepapi-vision`) through
an OpenAI-compatible protocol. It does not provide OpenAI models or imply an
official OpenAI relationship. All non-approved channels, models, and aliases
must be disabled or deleted in live one-api before onboarding.

DeepSeek will retire `deepseek-chat` and `deepseek-reasoner` on
2026-07-24 15:59 UTC. They are not launch models. Existing callers may use an
isolated migration group only until DeepAPI's earlier cutoff,
2026-07-17 15:59 UTC; afterward the aliases fail closed.

## Repository Controls

- Localhost-only application binding, pinned image, Nginx security headers, and
  rate limits.
- Domain-rendered Nginx configuration.
- Container-level log rotation without Docker daemon replacement/restart.
- Health-gated container replacement with rollback retention.
- Consistent encrypted offsite SQLite backup and restore-verification scripts.
- Fail-closed deployment gate requiring a fresh encrypted backup plus current
  human evidence of offsite transfer and successful restore.
- Repository-managed DeepAPI brand asset installation and stable Nginx routes,
  including one-api fallback logo and favicon overrides.
- Explicit cost, privacy/logging, policy, upstream-terms, monitoring, recovery,
  and live-environment gates.

## Brand Status

The repository assets and serving paths are maintainable through `deploy.sh`.
The live one-api System Name, Logo, Homepage, About, and Footer remain
operator-controlled database settings. Apply and verify them using
`brand/APPLICATION.md`; do not treat repository changes as proof that the live
UI has changed.

## Historical Exposure Status

The historical credential exposure is fixed and affected API credentials,
keys, and tokens have been rotated. The repository deliberately does not
reproduce sensitive historical values. Keep only non-sensitive owner evidence
of rotation, old-value invalidation, and new-value health checks.

## Model Contract Operations

Live channel, model, mapping, group, routing, and billing enforcement remains
operator-controlled in one-api. Complete `MODEL-CONTRACT-OPERATIONS.md` and
run `verify-model-contract.sh`; any visible or routable non-approved model is
NO-GO. DeepSeek public model names are text-only, and image analysis must use
the explicit `deepapi-vision` model.

## Commercial Status

No final price, fixed token bundle, unlimited plan, margin claim, or open
registration is approved. Complete `COST-MODEL.md`, `POLICIES-GATE.md`, and the
live billing reconciliation gate before accepting a customer.
Vision pricing is a separate SKU and remains NO-GO until image URL and base64
tests reconcile to provider billing without loss.
