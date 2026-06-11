# Commercial Cost Model Gate

This is a calculation framework, not final pricing.

## Required Inputs

Model every upstream model and customer plan separately using dated provider
invoices or published rate cards:

For the current product, model `deepseek-v4-flash`, `deepseek-v4-pro`, and
`deepapi-vision` as separate SKUs. Treat `deepapi-vision` as a separate vision
SKU. Do not price or launch using the retiring `deepseek-chat` or
`deepseek-reasoner` names. Do not bundle vision usage into a DeepSeek text price
unless the workbook proves the bundle cannot lose money under maximum-quota and
abuse scenarios.

| Input | Unit |
| --- | --- |
| Cache-miss input cost, cache-hit input cost, output/reasoning-token cost | USD per million tokens |
| Vision input pricing basis, image-token calculation, image URL/base64 cost behavior, and minimum charge | Provider rate-card unit |
| Typical and worst-case input/output token mix | Percent and tokens |
| Retries, failed requests, and unbilled upstream usage | Percent of upstream cost |
| Payment processing fixed and percentage fees | USD and percent |
| Refund rate and chargeback rate/fees | Percent and USD |
| Taxes, currency conversion, and payout fees | Percent and USD |
| VPS, monitoring, backup storage, support, and labor | USD per month |
| Fraud/abuse reserve and provider price-change reserve | Percent |

## Required Formula

```text
model_cost =
  cache_miss_input_tokens * cache_miss_input_rate
  + cache_hit_input_tokens * cache_hit_input_rate
  + output_and_reasoning_tokens * output_rate
  + vision_image_units * vision_image_rate
  + retry_and_failed_request_cost

net_collected =
  gross_collected
  - payment_percentage_fee
  - payment_fixed_fee
  - refunds
  - chargebacks_and_fees
  - taxes_and_currency_fees

contribution_margin =
  net_collected
  - model_cost
  - allocated_infrastructure
  - allocated_backup_and_monitoring
  - allocated_support_and_operations
  - abuse_and_price_change_reserve
```

## Scenarios And Gate

Calculate typical, high-output, maximum-quota, abuse, refund, chargeback, and
provider-price-increase scenarios. Include output tokens and actual upstream
invoice reconciliation; gateway quota units alone are not evidence of cost.
Run every scenario separately for V4 Flash and V4 Pro, and verify thinking-mode
usage does not bypass output/reasoning-token billing.
Run every scenario separately for `deepapi-vision`, including small images,
large images, repeated base64 uploads, public URL fetches, retries, failed
requests, and provider-side image-token accounting.

**Owner:** Business owner
**Evidence:** Dated private workbook plus provider invoice reconciliation
**GO:** Every offered plan remains within the owner-approved contribution margin
and loss cap in all required scenarios.
**NO-GO:** Any missing input, unreconciled billing delta, negative scenario, or
unapproved assumption.
