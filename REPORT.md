# DeepAPI Project Report

## Current State

DeepAPI is an OpenAI-compatible API proxy at `https://deepapi.click`. The first
commercial mode is manual payment plus manual one-api account provisioning.

## Production Files

| File | Purpose |
| --- | --- |
| `deploy.sh` | Production deployment script |
| `nginx-deepapi.conf` | Hardened HTTPS server config |
| `nginx-rate-limit-zones.conf` | Nginx rate-limit zones for `http {}` |
| `deepapi-project-doc.md` | Production runbook |
| `MANUAL-BILLING-SOP.md` | Manual payment and onboarding process |
| `FINAL-REPORT.md` | Launch readiness summary |

## Security State

- No live credentials are stored in public docs.
- one-api is bound to `127.0.0.1:3000`.
- UFW should expose only SSH, 80, and 443.
- Registration remains closed.
- Any token that previously appeared in Git history must remain revoked.
- VPS SSH should be key-only.
- Upstream provider keys should stay out of Git.
- Docker image is pinned by digest.

## Manual Revenue Path

1. Customer pays manually.
2. Operator records the customer in a private ledger.
3. Operator creates or enables one-api user.
4. Operator adds prepaid quota.
5. Operator sends API base URL and API key privately.
6. Operator reviews usage and provider cost daily.

See `MANUAL-BILLING-SOP.md`.
