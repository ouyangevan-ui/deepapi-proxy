# One-API Limits Runbook

This runbook defines the live one-api configuration and verification steps for
commercial rate limits, balance/quota visibility, and concurrency. It is a
repository-level checklist only; completing this file does not mean the live
one-api admin settings have been configured.

Policy: completing this file does not mean the live one-api admin settings have been configured.

## Required Account Boundary

Paid customers must have a one-api login account to self-serve:

- Current balance/quota in the exact unit one-api displays.
- API Keys/tokens that belong to the customer account.
- Usage logs and quota deductions for their own requests.
- Enabled model set and package expiry.

Issuing only an API Key is not enough for self-service. API-Key-only customers
cannot view a balance/quota page, manage keys, or inspect usage logs unless
DeepAPI provides a separate manual statement process in the contract.

## Package Limit Matrix

Configure commercial limits in one-api at the user, token, and group layers.
Nginx remains only an IP-layer guardrail for `/v1` average 10r/s/IP with burst
120; it is not a paid-plan limit.

Policy: `/v1` average 10r/s/IP with burst 120 remains an IP-layer guardrail only.

| Package | one-api group | Minute limit | Hourly limit | Concurrency | Model access |
| --- | --- | ---: | ---: | ---: | --- |
| Test users | test | 60/min | 1000/hour | 3 | `deepapi-everyday`, `deepapi-advanced` as approved |
| Starter | starter | 120/min | 3000/hour | 5 | `deepapi-everyday`, `deepapi-advanced` as approved |
| Vision | vision | 10/min | 100/hour | 1-2 | `deepapi-vision` only |

Text and vision must be separated:

- `deepapi-vision` must use a separate one-api group/token policy from text.
- Vision usage must not consume text quota.
- Text usage must not consume vision quota.
- A user who buys both text and vision should have separately auditable quota
  or balance changes for each package.

## Live Configuration Checklist

- [ ] Create or update the paid user account in one-api.
- [ ] Assign the customer to the approved text group and/or vision group.
- [ ] Create one token per package where practical, so text and vision usage
  can be audited independently.
- [ ] Configure user, token, and group minute limits.
- [ ] Configure user, token, and group hourly limits.
- [ ] Configure user, token, and group concurrency limits.
- [ ] Confirm the visible model allowlist contains only approved DeepAPI public
  names and no upstream model names.
- [ ] Confirm the customer can log in and see balance/quota, API Keys/tokens,
  and usage logs.
- [ ] Confirm an API-Key-only test record is documented as unable to self-serve
  balance/quota unless manual statements are contracted.

## Live Verification Checklist

Use `ops/verify-live-limits.example.sh` as a no-secret command template. Store
redacted evidence outside Git. Do not record prompt bodies, image URLs,
base64 payloads, full responses, bearer tokens, cookies, or one-api admin
session material.

For both an ordinary text model and `deepapi-vision`, verify:

- `/v1/models` lists only approved public model names.
- Legal model requests succeed within the configured package.
- Illegal and upstream model names fail closed.
- Minute rate limits reject excess requests.
- Hourly limits reject excess requests.
- Concurrency limits reject excess requests or queue according to the approved
  policy.
- Minute limit enforcement, hourly limit enforcement, and concurrency
  enforcement are all required.
- Successful requests deduct the correct balance/quota unit.
- Over-limit and rejected requests create no upstream provider usage and no
  customer-visible deduction.
- Text requests do not reduce vision quota, and vision requests do not reduce
  text quota.

**GO:** one-api screenshots/settings, request status summaries, usage logs,
balance/quota deltas, and provider billing evidence prove the package limits.

**NO-GO:** limits are configured only in Nginx, vision consumes text quota,
API-Key-only customers are told they can self-serve, rejected requests reach
upstream providers, or balance/quota changes cannot be reconciled.
