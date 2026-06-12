#!/usr/bin/env bash
set -euo pipefail

HEALTHCHECK_COMMAND="${HEALTHCHECK_COMMAND:-/usr/local/sbin/deepapi-healthcheck}"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:?Set ALERT_WEBHOOK_URL in the runtime environment}"
ALERT_SERVICE_NAME="${ALERT_SERVICE_NAME:-DeepAPI production}"
ALERT_WEBHOOK_TIMEOUT_SECONDS="${ALERT_WEBHOOK_TIMEOUT_SECONDS:-10}"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if "${HEALTHCHECK_COMMAND}" >/dev/null 2>&1; then
  exit 0
fi

message="${ALERT_SERVICE_NAME} health check failed. Inspect one-api, HTTPS, disk, and recent deploy state."
payload="$(printf '{"text":"%s"}' "$(json_escape "${message}")")"

curl --fail --silent --show-error --max-time "${ALERT_WEBHOOK_TIMEOUT_SECONDS}" \
  --header "Content-Type: application/json" \
  --data "${payload}" \
  "${ALERT_WEBHOOK_URL}" >/dev/null

echo "Alert notification sent."
