#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://deepapi.click}"
: "${TEST_USER_TOKEN:?Set TEST_USER_TOKEN securely without printing or committing it.}"

response_file="$(mktemp)"
trap 'rm -f "${response_file}"' EXIT

curl --fail-with-body --silent --show-error \
  "${BASE_URL%/}/v1/models" \
  -H "Authorization: Bearer ${TEST_USER_TOKEN}" \
  >"${response_file}"

python3 - "${response_file}" <<'PY'
import json
import sys

allowed = {"deepapi-everyday", "deepapi-advanced", "deepapi-vision"}

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)

models = {item["id"] for item in payload.get("data", []) if "id" in item}
unexpected = sorted(models - allowed)
missing = sorted(allowed - models)

if unexpected or missing:
    print(f"FAIL unexpected={unexpected} missing={missing}", file=sys.stderr)
    raise SystemExit(1)

print(f"PASS: visible models match public contract: {sorted(allowed)}")
PY
