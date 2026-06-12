# China Vision Model Research

**Research date:** 2026-06-11

This record supports the DeepAPI MVP boundary: DeepSeek is used for text-only
requests, and image analysis is exposed only through the named `deepapi-vision`
model after a provider is selected and approved. OpenAI-compatible means request
and response protocol compatibility only. It does not mean OpenAI models,
feature parity, endorsement, or partnership.

## Candidate Matrix

| Candidate | Official API fit | Image URL | Base64 image | Context and pricing | Overseas availability | Commercial/resale risk |
| --- | --- | --- | --- | --- | --- | --- |
| Alibaba Cloud Model Studio Qwen vision, preferred MVP path: `qwen-vl-plus` or `qwen3-vl-flash` | Official OpenAI-compatible `/chat/completions` endpoint and OpenAI SDK examples for multimodal messages. | Supported with `image_url.url` in OpenAI-compatible examples. | Supported as `data:image/...;base64,...` in OpenAI-compatible examples. | Official model list is the rate-card source for context window, max output, and per-token pricing. Image tokens appear in usage. | Official endpoints include Singapore, US, China (Beijing), and Hong Kong compatible-mode base URLs; selected region must match account and policy. | Needs dated Alibaba Cloud terms, data-processing review, and written approval if resale/proxy rights are unclear. |
| Zhipu AI GLM vision, preferred check: `glm-5v-turbo` or `glm-4.6v` | Official HTTP API uses `/api/paas/v4/chat/completions` and OpenAI-style `messages`/`image_url` content. Verify one-api compatibility in staging because docs emphasize Zhipu SDK/HTTP rather than a separate OpenAI-compatible base URL claim. | Supported with `image_url.url` examples. | Not confirmed from the fetched official page; must pass a live base64 test before launch. | Official overview lists GLM-5V-Turbo at 200K context and 128K max output; current pricing page requires account/console confirmation. | Public endpoint documented at `https://open.bigmodel.cn/api/paas/v4`; cross-border availability and data residency need account/terms confirmation. | Needs dated Zhipu terms, data-processing review, and written approval if resale/proxy rights are unclear. |
| Moonshot/Kimi vision, preferred check: `kimi-k2.6` or `moonshot-v1-*-vision-preview` | Official API is OpenAI SDK compatible at `https://api.moonshot.ai/v1/chat/completions`. | URL-formatted images are not supported for Kimi vision; docs say use base64 or uploaded file IDs. This fails the DeepAPI URL+base64 MVP gate unless a proxy downloads URL images, which is not recommended for MVP. | Supported as `data:image/...;base64,...`. | Kimi K2.6 context is 256K. Official pricing docs state input/output token billing and dynamic image/video token calculation, but the fetched page did not expose numeric price rows; account rate-card evidence is required. | API base URL is documented globally, but availability, tax, and data-processing terms require account/terms confirmation. | Needs dated Moonshot terms, data-processing review, and written approval if resale/proxy rights are unclear. |

## Recommendation

Use Alibaba Cloud Model Studio Qwen vision as the MVP first choice, mapped to the
public DeepAPI model name `deepapi-vision`, only after staging proves all of the
following:

- one-api can route a generic OpenAI-compatible channel to the selected
  compatible-mode endpoint without rewriting multimodal `content` arrays;
- `deepapi-vision` maps to exactly one approved upstream Qwen vision model;
- image URL and base64 requests both succeed and return usage data;
- unsupported model names and image requests using DeepSeek text model names
  fail closed with no upstream usage;
- accepted input is limited to OpenAI-compatible `messages[].content[]`
  containing text plus `image_url.url` values that are either public HTTPS image
  URLs or base64 data URI images;
- SSRF protections reject localhost, private ranges, link-local ranges,
  metadata addresses, redirects to internal addresses, and DNS results that
  resolve to internal IPs before any upstream use;
- oversized image URLs, oversized base64 payloads, malformed images, malicious
  images, excessive image count, and repeated uploads are bounded by request
  size, model context, quota, rate, and concurrency controls before they can
  create vision cost explosion;
- upstream per-token/image-token cost reconciles to DeepAPI billing without
  loss under `COST-MODEL.md`; and
- provider, region, data handling, logging, and resale/proxy rights are approved
  under `POLICIES-GATE.md`.

## Vision Input Risk Boundary

`deepapi-vision` is the highest-risk input surface. Image URLs can trigger SSRF
or metadata probing, base64 images can hide very large payloads, malformed or
malicious images can exercise decoder paths, prompt injection can be embedded
inside image content, and image-token accounting can create cost spikes. Do not
accept arbitrary uploads, provider file IDs, HTML pages, non-HTTPS URLs,
redirects to private networks, or any payload shape outside OpenAI-compatible
`messages[].content[]` text plus `image_url` parts. Do not log prompts, image
URLs, base64 bodies, image bytes, credentials, or full provider responses in
acceptance evidence.

## one-api Fit

The pinned one-api image can remain the MVP gateway if staging confirms an
OpenAI-compatible/custom channel can:

1. set the provider base URL to the selected vision endpoint;
2. expose only the public model name `deepapi-vision`;
3. map `deepapi-vision` to the upstream model by identity or explicit mapping;
4. preserve OpenAI multimodal `messages[].content[]` parts, including
   `image_url.url` for URL and base64 data-URI inputs; and
5. record per-model usage in a way finance can reconcile.

If any item fails, the minimum viable fallback is a narrow pre-one-api shim for
`/v1/chat/completions` that only accepts `model: "deepapi-vision"`, validates
the allowlist and image payload shape, forwards the request unchanged to the
chosen provider, normalizes the response into OpenAI-compatible chat completion
JSON, and emits non-sensitive usage fields for billing. Do not build a broad
self-developed gateway unless one-api cannot enforce the model contract.

## Official Basis

- Alibaba Cloud Model Studio OpenAI-compatible chat documentation:
  `https://www.alibabacloud.com/help/en/model-studio/compatibility-of-openai-with-dashscope`
- Alibaba Cloud Model Studio visual understanding documentation:
  `https://www.alibabacloud.com/help/en/model-studio/vision`
- Alibaba Cloud Model Studio model list and pricing source:
  `https://www.alibabacloud.com/help/en/model-studio/models`
- Zhipu AI model overview and visual model pages:
  `https://docs.bigmodel.cn/cn/guide/start/model-overview`
  and `https://docs.bigmodel.cn/cn/guide/models/vlm/glm-5v-turbo`
- Zhipu AI API overview:
  `https://docs.bigmodel.cn/cn/api/introduction`
- Kimi API model list, chat API, vision guide, and pricing:
  `https://platform.kimi.ai/docs/models`,
  `https://platform.kimi.ai/docs/api/chat`,
  `https://platform.kimi.ai/docs/guide/use-kimi-vision-model`,
  `https://platform.kimi.ai/docs/pricing/chat`
