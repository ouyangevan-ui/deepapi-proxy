# DeepAPI Final Readiness Report

## Status

DeepAPI is ready for a first manually onboarded paid user after the VPS
verification checklist below passes. Do not publish live admin credentials,
provider keys, or customer API tokens in this repository.

## Fixed In Repository

- one-api is bound to `127.0.0.1:3000`.
- The one-api Docker image is pinned by digest.
- Old plaintext Nginx gateway config was removed.
- Hardened Nginx config is installed by `deploy.sh`.
- Nginx rate-limit zones are split into `nginx-rate-limit-zones.conf`, which is
  installed into `/etc/nginx/conf.d/`.
- Public docs no longer instruct operators to open registration or grant free
  signup credit.
- Manual billing and onboarding SOP has been added.

## Manual Items Before First Customer

1. Confirm every token previously committed to Git is revoked in one-api.
2. Confirm SSH password login is disabled and key-only login works.
3. Confirm upstream provider keys have been rotated.
4. Re-run `deploy.sh` on the VPS and verify Nginx reloads cleanly.
5. Do one restore test from `/root/backup/deepapi`.
6. Prepare a private customer ledger.
7. Keep registration closed and create users manually after payment.

## First Customer Go/No-Go

Go only if all commands pass on the VPS:

```bash
nginx -t
docker ps --filter name=one-api
ss -ltnp | grep 3000
ufw status verbose
curl -I https://deepapi.click
```

Expected:

- `3000` is only bound to `127.0.0.1`.
- UFW exposes only SSH, 80, and 443.
- `curl -I` shows HSTS.
- Registration is closed.
- A paid test account can complete one API call and have usage recorded.

## Manual Billing Mode

The first revenue mode is:

1. Receive payment manually.
2. Record the customer in a private ledger.
3. Create or enable the user in one-api.
4. Add prepaid quota.
5. Send the API base URL, API key, quota, expiry date, and support contact
   privately.
6. Review usage and upstream cost daily.
