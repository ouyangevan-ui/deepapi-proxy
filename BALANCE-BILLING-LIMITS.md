# Balance, Billing, And Limit Gates

This file defines the commercial acceptance boundary for DeepAPI accounts,
balances, billing, and rate limits. It is a product and finance gate, not a
deployment runbook.

For live one-api configuration and no-secret verification commands, use
`ONEAPI-LIMITS-RUNBOOK.md` and `ops/verify-live-limits.example.sh`.

## User Console Capabilities

Logged-in paid users must be able to see their own:

- one-api quota or balance value, using the exact unit exposed by one-api.
- API Keys/tokens that belong to their account.
- Usage logs and quota deduction history for their own requests.
- Enabled models and applicable package expiry or renewal date.

If one-api displays quota instead of a USD balance, all customer-facing copy,
support messages, invoices, and screenshots must call it **quota**, not USD
balance. Do not claim a live USD balance page exists unless the deployed UI
actually shows USD-denominated balance.

Customers who receive only an API Key and no one-api login cannot self-serve a
balance/quota page, API Key management, or usage-log review. Paid customers
must be provisioned as one-api user accounts unless the contract explicitly
states that DeepAPI will provide manual statements instead of self-service.

Policy: Paid customers must be provisioned as one-api user accounts.

## Limit Layers

Nginx protects the shared edge only:

- `/v1` average 10r/s/IP with burst 120.
- Web UI average 2r/s/IP with burst 20.

Policy: /v1 average 10r/s/IP with burst 120.

Nginx limits are not a commercial package boundary because many customers can
share an IP and one customer can use many IPs. Commercial limits must be
configured in one-api at the user, token, and group layers.

Policy: Commercial limits must be configured in one-api at the user, token, and group layers.

Initial package limits:

| Package | Minute limit | Hourly limit | Concurrency |
| --- | ---: | ---: | ---: |
| Test users | 60/min | 1000/hour | 3 |
| Starter | 120/min | 3000/hour | 5 |
| Vision | 10/min | 100/hour | 1-2 |

Vision limits apply to `deepapi-vision` separately from text model limits.
Launch evidence must show text and vision quotas are separate.

## Live Acceptance Tests

Before production launch or a paid plan change, test keys must verify an
ordinary model and `deepapi-vision`:

Policy: ordinary model and deepapi-vision must both be verified before payment.

- Minute limit enforcement.
- Hourly limit enforcement.
- Concurrency enforcement.
- Balance/quota deduction after successful requests.
- Over-limit response behavior.
- Rejected requests create no upstream usage and no provider-side billable
  usage.

Use non-sensitive prompts and images only. Store redacted request windows,
one-api settings screenshots, usage logs, balance/quota deltas, and provider
billing evidence outside Git.

## Billing Reconciliation

Each reconciliation period must tie these fields together:

- Gateway charge by account, token, group, model, and request.
- Provider cost by upstream provider and model.
- Input tokens, output/reasoning tokens, cache-hit input, cache-miss input,
  image units, and minimum image charges where applicable.
- Starting balance/quota, manual credits, refunds, chargebacks, ending
  balance/quota, and customer-visible deductions.
- Difference between gateway charge and provider bill, with an approved
  explanation for retries, failed requests, free credits, rounding, or unbilled
  upstream cost.

**GO:** Self-service users can see the correct one-api unit, limits match their
offer, successful requests deduct balance/quota correctly, rejected requests do
not create upstream usage, and reconciliation differences are explained.

**NO-GO:** USD balance is promised when only quota is displayed, a paid customer
has only an API Key without an agreed manual-statement process, commercial
limits exist only in Nginx, rejected requests reach the upstream provider, or
gateway and provider billing cannot be reconciled.
