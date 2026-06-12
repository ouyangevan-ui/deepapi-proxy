#!/usr/bin/env bash
set -euo pipefail

# Example-only live verification template. Do not commit real tokens, payloads,
# prompts, images, cookies, or captured responses. This script prints only HTTP
# status summaries and response byte counts.

BASE_URL="${BASE_URL:-https://deepapi.click}"
TEXT_PAYLOAD_FILE="${TEXT_PAYLOAD_FILE:-}"
VISION_PAYLOAD_FILE="${VISION_PAYLOAD_FILE:-}"
ILLEGAL_PAYLOAD_FILE="${ILLEGAL_PAYLOAD_FILE:-}"
MINUTE_ATTEMPTS="${MINUTE_ATTEMPTS:-65}"
HOURLY_ATTEMPTS="${HOURLY_ATTEMPTS:-1005}"
CONCURRENCY_ATTEMPTS="${CONCURRENCY_ATTEMPTS:-6}"
RUN_LIVE_LIMIT_LOAD="${RUN_LIVE_LIMIT_LOAD:-0}"

if [ -z "${TEST_USER_TOKEN:-}" ]; then
  printf "TEST_USER_TOKEN: " >&2
  IFS= read -r -s TEST_USER_TOKEN
  printf "\n" >&2
fi

if [ -z "$TEST_USER_TOKEN" ]; then
  echo "TEST_USER_TOKEN is required" >&2
  exit 2
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl_common=(
  --silent
  --show-error
  --location
  --header "Authorization: Bearer ${TEST_USER_TOKEN}"
)

request() {
  local label="$1"
  local method="$2"
  local path="$3"
  local payload="${4:-}"
  local out="$tmpdir/${label}.json"
  local code

  if [ -n "$payload" ]; then
    code="$(curl "${curl_common[@]}" \
      --request "$method" \
      --header "Content-Type: application/json" \
      --data @"$payload" \
      --output "$out" \
      --write-out "%{http_code}" \
      "${BASE_URL}${path}")"
  else
    code="$(curl "${curl_common[@]}" \
      --request "$method" \
      --output "$out" \
      --write-out "%{http_code}" \
      "${BASE_URL}${path}")"
  fi

  printf "%s status=%s bytes=%s\n" "$label" "$code" "$(wc -c < "$out" | tr -d ' ')"
}

require_payload() {
  local name="$1"
  local path="$2"
  if [ -z "$path" ] || [ ! -f "$path" ]; then
    echo "$name must point to a non-sensitive payload file outside Git" >&2
    exit 2
  fi
}

echo "Base URL: ${BASE_URL}"
echo "Token: [hidden]"
echo "Do not store prompt bodies, image URLs, base64, or full responses in evidence."

request "models" GET "/v1/models"

if [ -n "$TEXT_PAYLOAD_FILE" ]; then
  require_payload "TEXT_PAYLOAD_FILE" "$TEXT_PAYLOAD_FILE"
  request "legal-text-model" POST "/v1/chat/completions" "$TEXT_PAYLOAD_FILE"
else
  echo "SKIP legal text request: set TEXT_PAYLOAD_FILE"
fi

if [ -n "$VISION_PAYLOAD_FILE" ]; then
  require_payload "VISION_PAYLOAD_FILE" "$VISION_PAYLOAD_FILE"
  request "legal-vision-model" POST "/v1/chat/completions" "$VISION_PAYLOAD_FILE"
else
  echo "SKIP legal vision request: set VISION_PAYLOAD_FILE"
fi

if [ -n "$ILLEGAL_PAYLOAD_FILE" ]; then
  require_payload "ILLEGAL_PAYLOAD_FILE" "$ILLEGAL_PAYLOAD_FILE"
  request "illegal-or-upstream-model" POST "/v1/chat/completions" "$ILLEGAL_PAYLOAD_FILE"
else
  echo "SKIP illegal model request: set ILLEGAL_PAYLOAD_FILE"
fi

if [ "$RUN_LIVE_LIMIT_LOAD" != "1" ]; then
  echo "SKIP load checks: set RUN_LIVE_LIMIT_LOAD=1 after confirming the test account and quotas."
  echo "Planned checks: minute=${MINUTE_ATTEMPTS}, hourly=${HOURLY_ATTEMPTS}, concurrency=${CONCURRENCY_ATTEMPTS}."
  exit 0
fi

require_payload "TEXT_PAYLOAD_FILE" "$TEXT_PAYLOAD_FILE"

echo "Minute limit check: expect excess requests to return 429/limited status without upstream usage."
for i in $(seq 1 "$MINUTE_ATTEMPTS"); do
  request "minute-${i}" POST "/v1/chat/completions" "$TEXT_PAYLOAD_FILE"
done

echo "Hourly limit check: use only a dedicated test account; verify rejected requests have no upstream usage."
for i in $(seq 1 "$HOURLY_ATTEMPTS"); do
  request "hour-${i}" POST "/v1/chat/completions" "$TEXT_PAYLOAD_FILE"
done

echo "Concurrency check: inspect returned statuses and one-api/provider usage afterward."
for i in $(seq 1 "$CONCURRENCY_ATTEMPTS"); do
  request "concurrent-${i}" POST "/v1/chat/completions" "$TEXT_PAYLOAD_FILE" &
done
wait

echo "After this script, compare one-api balance/quota deltas and provider billing. Rejected requests must create no upstream usage."
