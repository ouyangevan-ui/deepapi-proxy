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
| `deepapi-everyday` | Text only | DeepSeek | Admin mapping to approved fast/daily DeepSeek text model |
| `deepapi-advanced` | Text only | DeepSeek | Admin mapping to approved advanced/reasoning DeepSeek text model |
| `deepapi-vision` | Image analysis plus text prompt | Approved China vision provider | Admin mapping to approved China vision model; current recommendation `qwen3-vl-flash` |

Do not silently route image requests made with text model names to a vision
provider. If a request contains image content and the model is
`deepapi-everyday` or `deepapi-advanced`, it must fail closed until a later,
separately approved auto-switch policy exists. Auto-detect-and-switch is not an
MVP default.

Upstream names such as `deepseek-v4-flash`, `deepseek-v4-pro`,
`deepseek-chat`, `deepseek-reasoner`, `qwen3-vl-flash`, `qwen-*`, `gpt-*`,
`claude-*`, `gemini-*`, and all other non-public model names are not launch
models. Ordinary requests using non-allowlisted names must return a 4xx
response and create no upstream usage.

## 3. Configure Text Channels

Create or edit the DeepSeek text channel:

| Setting | Required value |
| --- | --- |
| Type/provider | DeepSeek |
| Status | Enabled |
| Upstream credential | Rotated credential entered privately in admin UI |
| Models | Public models `deepapi-everyday` and `deepapi-advanced` |
| Model mapping | Explicit public-to-upstream mapping only; no GPT-style or upstream-name aliases |
| Groups | Only groups intended for initial paid users |
| Priority/weight | Explicitly reviewed; no non-DeepSeek text fallback |

Use the admin UI channel test for both public text models. Record the upstream
target only in administrator evidence. Record pass/fail, timestamp, channel
name, and reviewer without recording request headers or credentials.

## 4. Configure Vision Channel

Do this only after `VISION-MODEL-RESEARCH.md`, `POLICIES-GATE.md`, and
`COST-MODEL.md` are approved for the selected upstream provider and model.

| Setting | Required value |
| --- | --- |
| Type/provider | one-api OpenAI-compatible/custom channel if staging proves it preserves multimodal content; otherwise the approved narrow shim |
| Public model | `deepapi-vision` only |
| Upstream model | One selected China vision model, recorded with dated official docs and rate card; current recommendation `qwen3-vl-flash` |
| Model mapping | `deepapi-vision` -> selected upstream model; no DeepSeek or GPT-style alias |
| Accepted input | OpenAI-compatible chat `messages[].content[]` with text plus `image_url.url` containing a public HTTPS image URL or base64 data URI |
| Required tests | One public image URL request and one base64 data-URI request |
| Access group | Test group only until vision provider, billing, privacy, and abuse evidence are GO |
| Default rate limits | `deepapi-vision`: 10 requests/minute, 100 requests/hour, concurrency 1-2 |
| Billing | Separate vision ratio/SKU; no bundling into DeepSeek text pricing |
| Disclosure | Provider, region, image data handling, logs, and retention disclosed in customer-facing privacy terms |

If one-api cannot preserve the request shape, enforce the allowlist, or produce
reconcilable usage records, keep production NO-GO and use only a narrow shim for
`deepapi-vision`. Do not implement a broad self-developed gateway for MVP.

Vision input security rules:

- Reject any `deepapi-vision` request whose content is not OpenAI-compatible
  `messages[].content[]` with text plus `image_url.url`.
- Allow only public HTTPS image URLs and base64 data URI images. Reject
  localhost, private networks, link-local ranges, metadata addresses such as
  `169.254.169.254`, non-HTTPS URLs, redirects to internal addresses, and DNS
  results that resolve to internal IPs.
- Reject or cap oversized image URLs, oversized base64 payloads, malformed
  images, malicious images, excessive image count, and requests that would
  exceed model context, quota, request-size, rate, concurrency, or cost limits.
- Treat image prompt injection as untrusted input. Vision output must not grant
  tool access, reveal hidden policy, or override the model contract.
- Do not log prompt text, image URLs, base64 bodies, image bytes, credentials,
  authorization headers, or full provider responses in tickets, screenshots, or
  acceptance evidence.
- Disclose the selected vision provider, region, retention, deletion path, and
  upstream logging behavior before exposing the model beyond the test group.

## 5. Restrict Visible Models

In system/model/group settings:

1. Remove all non-approved models from public and paid-user groups.
2. Expose only `deepapi-everyday`, `deepapi-advanced`, and, after provider
   approval, `deepapi-vision`.
3. Ensure aliases do not reintroduce a non-approved name.
4. Remove upstream names and legacy aliases from all normal groups.
5. Configure text and vision rate limits separately. This is a separate vision
   policy from text model access. `deepapi-vision` must not
   inherit or consume the same quota bucket as DeepSeek text models. Start with
   10 requests/minute, 100 requests/hour, and concurrency 1-2 for the vision
   test group unless the product owner approves a stricter value.
6. Review model ratios separately for `deepapi-everyday`, `deepapi-advanced`,
   and `deepapi-vision` against the current provider billing basis.
7. Verify cache-hit input, cache-miss input, output/reasoning-token, image-token
   or provider-specific vision charges can be reconciled. If one-api cannot
   represent the current billing dimensions accurately, keep production NO-GO.
8. Do not publish prices until the ratio-to-currency conversion has been tested
   with real low-value text and vision requests.

## 6. Upstream Name Rejection

Do not expose upstream model names or retiring aliases to customers. Requests
using `deepseek-chat`, `deepseek-reasoner`, `deepseek-v4-*`, `qwen-*`, `gpt-*`,
`claude-*`, `gemini-*`, or any other non-public model name must return 4xx and create no
upstream usage. There is no public migration path that allows customers to call
upstream model names directly.

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

Test valid text routes without printing the token:

```bash
curl --fail-with-body --silent --show-error \
  "${BASE_URL}/v1/chat/completions" \
  -H "Authorization: Bearer ${TEST_USER_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"model":"deepapi-everyday","messages":[{"role":"user","content":"Reply with OK"}],"max_tokens":8}'
```

Repeat with `deepapi-advanced`.

Test vision route with a public image URL:

```bash
curl --fail-with-body --silent --show-error \
  "${BASE_URL}/v1/chat/completions" \
  -H "Authorization: Bearer ${TEST_USER_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"model":"deepapi-vision","messages":[{"role":"user","content":[{"type":"image_url","image_url":{"url":"https://example.com/non-sensitive-test-image.png"}},{"type":"text","text":"Describe this image briefly."}]}],"max_tokens":64}'
```

Repeat with a non-sensitive base64 data URI image.

Then run blocked-input tests for:

- an illegal internal URL such as `http://127.0.0.1/`;
- a metadata address such as `http://169.254.169.254/`;
- an oversized base64 payload;
- a malformed or malicious image;
- an image request sent to `deepapi-everyday` or `deepapi-advanced`;
- a clearly unsupported model name; and
- upstream names such as `deepseek-v4-*`, `deepseek-chat`, `deepseek-reasoner`,
  or `qwen3-vl-flash`.

Force the configured `deepapi-vision` concurrency limit. Excess concurrent
requests must be rejected by one-api or handled by a documented queueing policy
that has owner approval.

For every acceptance request, record only pass/fail, request time, public model,
channel, usage counters, calculated charge, actual provider charge, and
reviewer. Do not record request/response bodies, image URLs, base64 content, or
credentials. Expected for blocked inputs, invalid models, text-model-with-image,
and upstream names: a 4xx response and no upstream usage. Any unexpected 2xx
response is NO-GO.

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
