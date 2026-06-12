# DeepAPI Product Requirements

**Status:** Pre-launch, manual onboarding only
**Commercial pricing:** Not approved; see `COST-MODEL.md`

## Product Scope

DeepAPI is an OpenAI-compatible protocol gateway that initially provides
DeepSeek text models plus a named China vision model for image analysis.
Protocol compatibility does not mean DeepAPI provides OpenAI models or has an
official relationship with OpenAI. The initial operating mode is prepaid,
manually approved accounts.

## Public Model Contract

| Public model | Modality | Upstream provider | Upstream model |
| --- | --- | --- | --- |
| `deepapi-everyday` | Text only | DeepSeek | Admin mapping to DeepSeek fast/daily text model |
| `deepapi-advanced` | Text only | DeepSeek | Admin mapping to DeepSeek advanced/reasoning model |
| `deepapi-vision` | Image analysis plus text prompt | Approved China vision provider | Admin mapping to approved China vision model; current recommendation `qwen3-vl-flash` |

Only the three `deepapi-*` names may be visible to ordinary users or API
clients. Upstream names are private administrator mapping records and must not
appear in `/v1/models`, customer onboarding, public pricing pages, SDK examples,
or ordinary API requests. DeepAPI text models are text-only; customers who need
image analysis must request `deepapi-vision` explicitly. Automatic image
detection and model switching is a future option, not an MVP default.

The upstream names `deepseek-chat`, `deepseek-reasoner`, `deepseek-v4-*`,
`qwen-*`, `gpt-*`, `claude-*`, and `gemini-*` are not public models. Ordinary
requests using any non-allowlisted name must return 4xx and create no upstream
usage.

Official basis, independently verified on 2026-06-11:

- `https://api-docs.deepseek.com/`
- `https://api-docs.deepseek.com/quick_start/pricing`
- `https://api-docs.deepseek.com/news/news260424`
- `VISION-MODEL-RESEARCH.md` for China vision model candidates and official
  source links.

## Launch Rules

- Open registration stays disabled.
- Every non-approved channel is disabled or deleted before onboarding.
- New and launch-approved paid-user groups expose only `deepapi-everyday`,
  `deepapi-advanced`, and `deepapi-vision`.
- Upstream provider/model names are visible only to administrators in mapping,
  billing, provider approval, and incident records.
- A non-allowlisted model request must fail closed and create no upstream use.
- A DeepAPI text-model request containing image content must fail closed and
  create no upstream vision use.
- `deepapi-vision` must pass both image URL and base64 data-URI tests before
  launch.
- Vision usage must be disclosed, logged, and billed separately from DeepSeek
  text usage.
- No free trial, unlimited plan, or fixed token bundle may be advertised until
  cost scenarios and abuse limits pass the commercial gate.
- Every account has a prepaid balance, explicit quota, rate limit, enabled model
  list, and expiration or renewal date.
- Provider names and compatibility claims must not imply partnership,
  endorsement, or rights beyond the applicable upstream terms.
- Public privacy statements must describe actual gateway, application, billing,
  security, and provider logging. Never claim "no logs" while logs exist.

## Functional Requirements

| Area | Requirement | Launch gate |
| --- | --- | --- |
| Access | Manual paid-user provisioning; registration closed | Account configuration evidence |
| Billing | Text and vision usage reconciles to upstream billing by model | Cost reconciliation evidence |
| Abuse | Per-account quotas and rate limits | Paid test-account evidence |
| Reliability | Local health check, rollback procedure, external alert path | Failure drill evidence |
| Recovery | Consistent encrypted offsite backup and restore verification | Restore drill evidence |
| Privacy | Provider, image data handling, retention, deletion, and logs match published policy | Policy approval evidence |
| Legal | Terms, privacy policy, AUP, refund policy, and upstream resale review for every provider | Legal/business approval |

## Explicit Non-Goals

- Final market pricing or final plan design.
- Open self-service signup.
- Claims of high availability on a single VPS.
- Claims of automatic provider failover unless tested and evidenced.
- Unnamed provider fallback or hidden rerouting under a DeepSeek model name.
- Final vision provider approval without dated official docs, pricing,
  privacy, and resale/proxy review.
- Production launch based only on repository checks.

## Historical Credential Incident

The historical credential exposure is fixed and affected API credentials,
keys, and tokens have been rotated. Keep only non-sensitive evidence of the
rotation date, credential category, old-credential invalidation, new-credential
health check, operator, and reviewer.

## Success Criteria

Production is GO only when every required row in `PRODUCTION-READINESS.md` has a
named owner, dated evidence, and a passing result, and
`MODEL-CONTRACT-OPERATIONS.md` passes. Any missing or stale evidence is NO-GO.
