# Manual Billing SOP

Use this only after the cost and policy gates are GO. Store customer and payment
records in an approved private system, never in Git.

## Required Ledger Fields

| Category | Fields |
| --- | --- |
| Customer | Internal customer ID, verified contact, status |
| Payment | Gross amount, currency, processor reference, fees, net received, date |
| Service | Approved offer/version, quota, enabled models, rate limit, expiry |
| Usage | Input tokens, output tokens, gateway charge, provider cost, billing delta |
| Adjustments | Refund amount/reason, dispute status/fee, manual credit, approver |

## Onboarding

- [ ] Applicable terms, privacy policy, AUP, and refund policy were presented.
- [ ] Payment settled and fraud/abuse review passed.
- [ ] Registration remains closed; operator created one approved account.
- [ ] Quota, model access, rate limit, and expiry match the approved offer.
- [ ] Model access is limited to the approved contract:
  `deepseek-v4-flash`, `deepseek-v4-pro`, and, after provider approval,
  `deepapi-vision`.
- [ ] `verify-model-contract.sh` reports no non-approved visible models.
- [ ] No new account can see `deepseek-chat` or `deepseek-reasoner`.
- [ ] Non-sensitive text and vision test requests succeeded and billing
  reconciled.
- [ ] Text requests routed to DeepSeek and quota deduction matches the reviewed
  V4 model rules and DeepSeek billing, including cache-hit, cache-miss, and
  output/reasoning usage.
- [ ] Vision requests routed to the approved vision provider, image URL and
  base64 tests passed, and vision usage is charged separately without loss.
- [ ] Customer received support, refund, and acceptable-use contacts.

## Daily Reconciliation

- [ ] Compare input and output usage to provider billing.
- [ ] Investigate retries, failed requests, credits, and unbilled upstream cost.
- [ ] Compare gross payment, fees, refunds, disputes, and net collected.
- [ ] Review suspicious usage and suspend under the approved AUP when necessary.
- [ ] Confirm health alerting and a fresh encrypted offsite backup.
- [ ] Confirm no non-approved channel, model, or alias became enabled.
- [ ] Confirm DeepSeek text models did not accept or reroute image payloads.
- [ ] Confirm retiring aliases are absent, or remain only in a dated migration
  group before 2026-07-17 15:59 UTC.

## Refunds And Chargebacks

Apply only the approved public refund policy. Record the request, eligibility
decision, delivered usage, refund amount, approver, processor result, and
customer communication. Preserve evidence required by the payment processor
for disputes while following the privacy retention schedule.
