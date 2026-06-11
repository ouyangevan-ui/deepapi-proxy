# Manual Billing SOP

Use this until automated payment webhooks exist.

## Customer Ledger

Keep this in a private spreadsheet or private file. Do not commit real customer
data to Git.

| Field | Example |
| --- | --- |
| customer_email | user@example.com |
| plan | Starter |
| paid_amount_usd | 9.90 |
| paid_at | 2026-06-10 |
| payment_reference | Stripe payment id |
| one_api_username | user@example.com |
| api_key_suffix | last 6 chars only |
| quota_tokens | 50000000 |
| expires_at | 2026-07-10 |
| status | active |

## Onboarding Checklist

- [ ] Payment received.
- [ ] Customer email recorded.
- [ ] User created or enabled in one-api.
- [ ] Balance/quota added.
- [ ] API key generated.
- [ ] Customer received base URL, key, models, quota, expiry, and support email.
- [ ] Test request succeeds and usage is logged.

## Daily Check

- [ ] Export one-api usage.
- [ ] Compare usage against paid quota.
- [ ] Compare provider cost against collected revenue.
- [ ] Revoke or throttle suspicious tokens.
- [ ] Confirm backup job created a fresh archive.
