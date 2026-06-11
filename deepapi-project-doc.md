# DeepAPI Production Runbook

DeepAPI is an OpenAI-compatible API gateway backed by lower-cost model
providers. The first revenue mode is manual payment plus manual one-api account
provisioning.

## Deploy

Run from the VPS as root:

```bash
cd /root/deepapi-proxy
DOMAIN=deepapi.click ADMIN_EMAIL=admin@example.com bash deploy.sh
```

The deploy script:

- binds one-api to `127.0.0.1:3000`;
- installs the hardened Nginx config;
- installs the Nginx rate-limit zones;
- enables UFW for SSH, HTTP, and HTTPS only;
- configures Docker log rotation;
- creates a daily local backup cron.

## Verify After Deploy

```bash
nginx -t
docker ps --filter name=one-api
ss -ltnp | grep 3000
ufw status verbose
curl -I https://deepapi.click
```

Expected:

- `3000` appears only as `127.0.0.1:3000`.
- UFW allows SSH, 80, and 443 only.
- HTTPS responses include `Strict-Transport-Security`.
- Registration is disabled unless a paid user is being manually onboarded.

## Manual Paid User Flow

Do not enable open registration for the first customers.

1. Receive payment by Stripe Payment Link, PayPal, Wise, or bank transfer.
2. Record the payment in a private customer ledger.
3. Create or enable the user in one-api.
4. Add prepaid balance/quota for the purchased plan.
5. Generate an API key for that customer.
6. Send the customer privately:
   - Base URL: `https://deepapi.click/v1`
   - API key
   - Enabled models
   - Purchased quota
   - Expiration or renewal date
   - Support contact
7. Review usage and upstream cost daily.

## Starter Plans

| Plan | Price | Included Usage | Overage |
| --- | ---: | ---: | ---: |
| Starter | $9.90/mo | 50M tokens | $0.60/M |
| Pro | $29/mo | 300M tokens | $0.45/M |
| Scale | $99/mo | 1.2B tokens | $0.35/M |

No unlimited plans. No free trial without payment, verified email, and abuse
controls.

## Backup

The deploy script creates local daily backups under `/root/backup/deepapi` and
keeps 14 days. Before accepting users, copy at least one backup off the VPS and
test restoring `/opt/one-api/data` on a disposable machine.

## Incident Checklist

If abuse, billing mismatch, or key leakage is suspected:

1. Disable the affected user token.
2. Disable registration.
3. Rotate upstream provider keys if needed.
4. Export one-api logs for the affected window.
5. Compare customer quota, one-api usage, and provider billing.
