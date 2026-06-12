# Monitoring And Alerting Runbook

Repository checks do not prove live monitoring. Production is NO-GO until an
external alert reaches a responsible person when one-api, HTTPS, or disk health
fails.

## Runtime Configuration

Install `ops/healthcheck.sh` as `/usr/local/sbin/deepapi-healthcheck` and
`ops/healthcheck-notify.sh` as `/usr/local/sbin/deepapi-healthcheck-notify`.
Configure secrets outside Git, for example in a root-only systemd environment
file:

```text
ALERT_WEBHOOK_URL=https://example.invalid/redacted-webhook
ALERT_SERVICE_NAME=DeepAPI production
PUBLIC_HTTPS_URL=https://deepapi.example.invalid/api/status
DISK_PATH=/opt/one-api
DISK_MAX_PERCENT=85
```

The webhook URL above is a placeholder. Never commit or paste the real webhook,
token, password, SSH key, API key, or alert screenshot containing secrets.

## Verification

1. Run the plain health check and confirm it fails closed on container, local
   one-api status, HTTPS, and disk threshold failures.
2. Run `deepapi-healthcheck-notify` with a test webhook and forced failure,
   such as an unreachable `LOCAL_STATUS_URL`.
3. Confirm the alert reaches the on-call owner with timestamp, service name,
   and no request bodies, image URLs, API keys, or customer data.
4. Store redacted evidence in the private operations log and link it from the
   production readiness checklist.

## Go/No-Go

GO requires an external notification for one-api process failure, HTTPS failure,
and disk threshold failure. Local-only logs, terminal output, or repository test passes are NO-GO for production alerting.
