# DeepAPI Model Contract Operations

Use this procedure on the live one-api instance before onboarding users and
after any restore, migration, provider, channel, model, or billing change.

Never paste real credentials into Git, tickets, chat, screenshots, shell
history, or acceptance records. Enter upstream credentials only in the one-api
admin UI or an approved secret manager.

## 1. Take a Protected Backup

1. Close public registration and pause onboarding.
2. Create a one-api data backup using the existing protected backup process.
3. Record only the backup timestamp and restore-test result. Do not attach the
   database to a ticket because it contains sensitive values.

## 2. Product Model Contract

Launch-approved users may see only these public model names:

| Public model | Modality | Upstream provider | Upstream model |
| --- | --- | --- | --- |
| `deepseek-v4-flash` | Text only | DeepSeek | `deepseek-v4-flash` |
| `deepseek-v4-pro` | Text only | DeepSeek | `deepseek-v4-pro` |
| `deepapi-vision` | Image analysis plus text prompt | Approved China vision provider | Pending final selection; MVP recommendation is Alibaba Cloud Model Studio Qwen vision |

Do not silently route image requests made with DeepSeek model names to a vision
provider. If a request contains image content and the model is
`deepseek-v4-flash` or `deepseek-v4-pro`, it must fail closed until a later,
separately approved auto-switch policy exists. Auto-detect-and-switch is not an
MVP default.

`deepseek-chat`, `deepseek-reasoner`, GPT-style aliases, and all other model
names are not launch models. Requests using non-allowlisted names must return a
4xx response and create no upstream usage.

## 3. Configure Text Channels

Create or edit the DeepSeek text channel:

| Setting | Required value |
| --- | --- |
| Type/provider | DeepSeek |
| Status | Enabled |
| Upstream credential | Rotated credential entered privately in admin UI |
| Models | `deepseek-v4-flash`, `deepseek-v4-pro`; add legacy names temporarily only if an existing-caller migration group is required |
| Model mapping | Identity mapping only; no GPT-style aliases |
| Groups | Only groups intended for initial paid users |
| Priority/weight | Explicitly reviewed; no non-DeepSeek text fallback |

Use the admin UI channel test for both V4 models. Record pass/fail, timestamp,
channel name, and reviewer without recording request headers or credentials.

## 4. Configure Vision Channel

Do this only after `VISION-MODEL-RESEARCH.md`, `POLICIES-GATE.md`, and
`COST-MODEL.md` are approved for the selected upstream provider and model.

| Setting | Required value |
| --- | --- |
| Type/provider | one-api OpenAI-compatible/custom channel if staging proves it preserves multimodal content; otherwise the approved narrow shim |
| Public model | `deepapi-vision` only |
| Upstream model | One selected China vision model, recorded with dated official docs and rate card |
| Model mapping | `deepapi-vision` -> selected upstream model; no DeepSeek or GPT-style alias |
| Accepted input | OpenAI-compatible chat `messages[].content[]` with text plus `image_url` |
| Required tests | One public image URL request and one base64 data-URI request |
| Access group | Test group only until vision provider, billing, privacy, and abuse evidence are GO |
| Default rate limits | `deepapi-vision`: 10 requests/minute, 100 requests/hour, concurrency 1-2 |
| Billing | Separate vision ratio/SKU; no bundling into DeepSeek text pricing |
| Disclosure | Provider, region, image data handling, logs, and retention disclosed in customer-facing privacy terms |

If one-api cannot preserve the request shape, enforce the allowlist, or produce
reconcilable usage records, keep production NO-GO and use only a narrow shim for
`deepapi-vision`. Do not implement a broad self-developed gateway for MVP.

## 5. Restrict Visible Models

In system/model/group settings:

1. Remove all non-approved models from public and paid-user groups.
2. Expose only `deepseek-v4-flash`, `deepseek-v4-pro`, and, after provider
   approval, `deepapi-vision`.
3. Ensure aliases do not reintroduce a non-approved name.
4. Remove `deepseek-chat` and `deepseek-reasoner` from all normal groups.
5. Configure text and vision rate limits separately. `deepapi-vision` must not
   inherit or consume the same quota bucket as DeepSeek text models. Start with
   10 requests/minute, 100 requests/hour, and concurrency 1-2 for the vision
   test group unless the product owner approves a stricter value.
6. Review model ratios separately for DeepSeek V4 Flash, DeepSeek V4 Pro, and
   `deepapi-vision` against the current provider billing basis.
7. Verify cache-hit input, cache-miss input, output/reasoning-token, image-token
   or provider-specific vision charges can be reconciled. If one-api cannot
   represent the current billing dimensions accurately, keep production NO-GO.
8. Do not publish prices until the ratio-to-currency conversion has been tested
   with real low-value text and vision requests.

## 6. Legacy Alias Migration

DeepSeek will fully retire `deepseek-chat` and `deepseek-reasoner` on
**2026-07-24 15:59 UTC**. DeepAPI's internal cutoff is
**2026-07-17 15:59 UTC**.

- Do not enable legacy aliases for new users.
- If the inventory finds no existing legacy callers, do not create or retain a
  migration group.
- If an existing caller needs migration time, place it in a dedicated
  `legacy-migration` group with an owner and migration deadline.
- During the migration window, route legacy names unchanged to DeepSeek:
  `deepseek-chat` currently selects V4 Flash non-thinking mode and
  `deepseek-reasoner` selects V4 Flash thinking mode.
- Do not map legacy aliases to `deepapi-vision` or any non-DeepSeek provider.
- At the internal cutoff, disable/remove both aliases from all groups. Requests
  using either old name must return 4xx and create no upstream usage.

## 7. Safe Acceptance Commands

Run from a trusted shell. Set the test user token through an approved secret
manager or hidden prompt; never put its value in the command or shell history.

```bash
export BASE_URL="https://your-domain.example"
read -r -s -p "Test user token: " TEST_USER_TOKEN
echo
export TEST_USER_TOKEN
```

Check a launch user. The command fails unless exactly the approved launch model
names are visible:

```bash
./verify-model-contract.sh
```

During the temporary migration window only, separately check an existing
migration user:

```bash
MODEL_POLICY=legacy-migration ./verify-model-contract.sh
```

Test valid text routes without printing the token:

```bash
curl --fail-with-body --silent --show-error \
  "${BASE_URL}/v1/chat/completions" \
  -H "Authorization: Bearer ${TEST_USER_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"Reply with OK"}],"thinking":{"type":"disabled"},"max_tokens":8}'
```

Repeat with `deepseek-v4-pro` using the intended thinking mode.

Test vision route with a public image URL:

```bash
curl --fail-with-body --silent --show-error \
  "${BASE_URL}/v1/chat/completions" \
  -H "Authorization: Bearer ${TEST_USER_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"model":"deepapi-vision","messages":[{"role":"user","content":[{"type":"image_url","image_url":{"url":"https://example.com/non-sensitive-test-image.png"}},{"type":"text","text":"Describe this image briefly."}]}],"max_tokens":64}'
```

Repeat with a non-sensitive base64 data-URI image. Record only pass/fail,
request time, model, channel, usage counters, calculated charge, actual provider
charge, and reviewer.

Then send blocked-model tests for a clearly unsupported name, each legacy alias,
and an image request using a DeepSeek text model. Confirm all are rejected
without upstream usage.

Expected for a launch user and for every user after the internal cutoff: a 4xx
response. Any 2xx response is NO-GO.

## 8. Verify Routing and Billing in Admin UI

For each allowed-model test request:

1. Locate the request in one-api logs by time and test user.
2. Confirm the selected channel is the intended DeepSeek or approved vision
   channel.
3. Confirm the recorded public model and upstream model mapping.
4. Confirm input, output, cache, reasoning, image-token, or provider-specific
   vision usage fields are present where the upstream response exposes them.
5. Compare the one-api deduction with the configured per-model billing rules.
6. Compare the request with the provider usage/billing view.
7. Confirm blocked-model tests produced no provider usage.

Record only request time, model, channel name, token/image usage counters,
calculated charge, actual charge, pass/fail, and reviewer. Do not record tokens,
credentials, authorization headers, or full request/response bodies.

## 9. Go/No-Go

Go only when:

- launch users see exactly the approved public model names;
- DeepSeek model names are text-only and never route to a vision provider;
- `deepapi-vision` maps to one approved China vision model with clear provider
  and privacy disclosure;
- image URL and base64 vision tests pass;
- `deepapi-vision` is initially limited to a test group with 10 requests/minute,
  100 requests/hour, and concurrency 1-2;
- text and vision models use separate rate-limit and quota policies, so vision
  cannot use the text-model allowance;
- excess concurrent vision requests are rejected by one-api or a documented
  queueing policy is approved before launch;
- invalid model names, expired legacy aliases, and DeepSeek-with-image requests
  fail closed with no upstream usage;
- vision pricing is separate, reconciled, and non-loss-making;
- registration is closed; and
- the historical credential exposure record says fixed and rotated, with
  non-sensitive invalidation and health-check evidence.
