# Manual Billing SOP

Use this only after the cost and policy gates are GO. Store customer and payment
records in an approved private system, never in Git.

## Required Ledger Fields

| Category | Fields |
| --- | --- |
| Customer | Internal customer ID, verified contact, status |
| Payment | Gross amount, currency, processor reference, fees, net received, date |
| Service | Approved offer/version, one-api quota or balance unit, enabled models, rate limit, expiry |
| Usage | Input tokens, output tokens, cache-hit input, cache-miss input, image units, gateway charge, provider cost, balance/quota delta, billing delta |
| Adjustments | Refund amount/reason, dispute status/fee, manual credit, approver |

## Onboarding

- [ ] Applicable terms, privacy policy, AUP, and refund policy were presented.
- [ ] Payment settled and fraud/abuse review passed.
- [ ] Registration remains closed; operator created one approved account.
- [ ] Quota/balance unit, model access, rate limit, and expiry match the
  approved offer and `BALANCE-BILLING-LIMITS.md`.
- [ ] one-api user, token, and group limits were configured using
  `ONEAPI-LIMITS-RUNBOOK.md`; no live configuration evidence is stored in Git.
- [ ] If one-api displays quota instead of USD balance, customer-facing copy
  says quota rather than USD balance.
- [ ] Paid customer has a one-api user login for balance/quota, API Key, and
  usage-log self-service. If only an API Key is issued, the contract states
  that DeepAPI provides manual statements and the customer cannot self-serve a
  balance page.
- [ ] one-api user/token/group limits are configured. Nginx is an IP-layer
  guardrail; commercial limits must be configured by user, token, and group in
  one-api.
- [ ] Test users: 60/min, 1000/hour, concurrency 3.
- [ ] Starter: 120/min, 3000/hour, concurrency 5.
- [ ] Vision: 10/min, 100/hour, concurrency 1-2.
- [ ] Model access is limited to the approved contract:
  `deepapi-everyday`, `deepapi-advanced`, and, after provider approval,
  `deepapi-vision`; upstream model names are not visible to users.
- [ ] `verify-model-contract.sh` reports no non-approved visible models.
- [ ] No new account can see any upstream model name, including `deepseek-*`,
  `qwen-*`, `gpt-*`, `claude-*`, or `gemini-*`.
- [ ] Non-sensitive text and vision test requests succeeded and billing
  reconciled.
- [ ] Test key verification covered an ordinary model and `deepapi-vision`:
  rate limit, concurrency limit, balance deduction, and over-limit behavior.
- [ ] `ops/verify-live-limits.example.sh` or equivalent no-secret commands
  verified minute, hourly, concurrency, balance/quota, illegal-model, and
  rejected-request behavior.
- [ ] Text requests routed to DeepSeek and quota deduction matches the reviewed
  V4 model rules and DeepSeek billing, including cache-hit, cache-miss, and
  output/reasoning usage.
- [ ] Vision requests routed to the approved vision provider, image URL and
  base64 tests passed, and vision usage is charged separately without loss.
- [ ] Customer received support, refund, and acceptable-use contacts.

## Daily Reconciliation

- [ ] Compare gateway charge, provider cost, input tokens, output/reasoning
  tokens, cache-hit input, cache-miss input, image units, and balance/quota
  changes to provider billing.
- [ ] Investigate retries, failed requests, credits, and unbilled upstream cost.
- [ ] Confirm over-limit and rejected requests created no upstream provider
  usage and no customer-visible deduction.
- [ ] Confirm over-limit and rejected requests created no upstream provider usage.
- [ ] Compare gross payment, fees, refunds, disputes, and net collected.
- [ ] Review suspicious usage and suspend under the approved AUP when necessary.
- [ ] Confirm health alerting and a fresh encrypted offsite backup.
- [ ] Confirm no non-approved channel, model, or alias became enabled.
- [ ] Confirm DeepSeek text models did not accept or reroute image payloads.
- [ ] Confirm upstream names are absent from all ordinary user-visible model
  lists and requests using them fail closed.

## Refunds And Chargebacks

Apply only the approved public refund policy. Record the request, eligibility
decision, delivered usage, refund amount, approver, processor result, and
customer communication. Preserve evidence required by the payment processor
for disputes while following the privacy retention schedule.
