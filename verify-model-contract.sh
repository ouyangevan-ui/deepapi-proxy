#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://deepapi.click}"
MODEL_POLICY="${MODEL_POLICY:-launch}"
: "${TEST_USER_TOKEN:?Set TEST_USER_TOKEN securely without printing or committing it.}"

response_file="$(mktemp)"
trap 'rm -f "${response_file}"' EXIT

curl --fail-with-body --silent --show-error \
  "${BASE_URL%/}/v1/models" \
  -H "Authorization: Bearer ${TEST_USER_TOKEN}" \
  >"${response_file}"

python3 - "${response_file}" "${MODEL_POLICY}" <<'PY'
from datetime import datetime, timezone
import json
import sys

policy = sys.argv[2]
text_models = {"deepseek-v4-flash", "deepseek-v4-pro"}
vision_models = {"deepapi-vision"}
legacy_aliases = {"deepseek-chat", "deepseek-reasoner"}
legacy_cutoff = datetime(2026, 7, 17, 15, 59, tzinfo=timezone.utc)

if policy == "launch":
    allowed = text_models | vision_models
elif policy == "legacy-migration":
    if datetime.now(timezone.utc) >= legacy_cutoff:
        print("FAIL legacy-migration policy expired at 2026-07-17 15:59 UTC", file=sys.stderr)
        raise SystemExit(1)
    allowed = text_models | vision_models | legacy_aliases
else:
    print(f"FAIL unknown MODEL_POLICY={policy!r}", file=sys.stderr)
    raise SystemExit(1)

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)

models = {item["id"] for item in payload.get("data", []) if "id" in item}
unexpected = sorted(models - allowed)
missing = sorted(allowed - models)

if unexpected or missing:
    print(f"FAIL unexpected={unexpected} missing={missing}", file=sys.stderr)
    raise SystemExit(1)

print(f"PASS: visible models match {policy} policy: {sorted(allowed)}")
PY
