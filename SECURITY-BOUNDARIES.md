# Security Boundaries

This table is the product safety boundary for DeepAPI operations. It is not a
credential record; keep credentials, tokens, keys, request bodies, and full
provider responses out of Git, chat, screenshots, logs, and acceptance evidence.

Required anchors:
`one-api-admin-is-production-boundary`,
`nginx-ip-guardrail-not-commercial-rate-limit`,
`commercial-limits-by-user-token-group`,
`no-credentials-in-git-chat-screenshots-logs`,
`redacted-admin-screenshots-only`,
`no-default-or-shared-admin`,
`unique-admin`,
`strong-password`,
`recommend-2fa-and-recovery-path`,
`ssh-key-only-or-strongly-restricted`.

| interface_input | login_state | permission_design | password_rule | data_ownership | risk_type | handling_logic | verification_method |
| --- | --- | --- | --- | --- | --- | --- | --- |
| admin_login | Admin only | unique-admin; no-default-or-shared-admin; one-api-admin-is-production-boundary | strong-password; recommend-2fa-and-recovery-path | Operator account data | Account takeover | Unique admin access, recovery path, redacted-admin-screenshots-only | Redacted settings and recovery test |
| user_console | Authenticated user | User sees only assigned group and public model names | User-managed secret outside Git | User account and balance | Unauthorized access | Registration closed; manual provisioning | Test account settings screenshot |
| api_key_call | Authenticated API key | commercial-limits-by-user-token-group | Key is never displayed in evidence | Customer traffic | Abuse and spend | Per-token group, quota, rate, and expiry controls | Redacted one-api settings plus rejected over-limit requests |
| model_selection | API request | Public allowlist only | Not applicable | Model routing metadata | Hidden provider switch | Only `deepapi-everyday`, `deepapi-advanced`, `deepapi-vision`; upstream names fail closed | `verify-model-contract.sh` |
| text_request | API request | Text models only | Not applicable | Prompt and usage data | Modality confusion | Image content sent to text models returns 4xx; no auto-switch | DeepAPI text-model-with-image rejection test |
| vision_request | Test group only | `deepapi-vision` only; 10/min, 100/hour, concurrency 1-2 separate from text quota | Not applicable | Image URL/base64, prompt, usage, provider metadata | SSRF, metadata probing, oversized base64, malformed or malicious images, prompt injection, privacy leak, vision cost explosion | Accept only OpenAI-compatible `messages[].content[]` text plus public HTTPS `image_url.url` or base64 data URI; reject localhost, private ranges, link-local ranges, metadata addresses, redirects/DNS to internal IPs, oversized payloads, malformed images, invalid models; do not log bodies | Public URL pass, base64 pass, internal URL reject, metadata address reject, oversized base64 reject, malformed image reject, concurrency reject or approved queue, provider usage check |
| channel_credentials | Admin only | no-credentials-in-git-chat-screenshots-logs | Secret entered only in approved admin/secret system | Provider secrets | Credential exposure | Do not paste credentials into Git, tickets, screenshots, shell history, or logs | Redacted rotation and health evidence |
| user_group_permissions | Admin only | Group controls model visibility, quota, rate, concurrency | Admin password policy applies | Account access and billing | Privilege drift | Launch/test users receive only approved groups | Redacted group inventory |
| balance_billing | Admin/finance | Manual prepaid balance and model-specific pricing | Private finance system | Payment and usage records | Loss, refund, chargeback | Reconcile gateway deductions, provider usage, and payments | Dated private worksheet |
| usage_logs | Operator only | Least-privilege log access | Host/admin controls | Metadata, usage counters | Privacy and retention mismatch | Never promise no logs; minimize, redact, and expire logs | Retention/deletion matrix |
| nginx_boundary | Public edge | nginx-ip-guardrail-not-commercial-rate-limit | Not applicable | IP and HTTP metadata | Spoofing, volumetric abuse | Nginx is edge guardrail; commercial limits live in one-api user/token/group settings | Independent client rate test |
| rate_concurrency | API request | commercial-limits-by-user-token-group | Not applicable | Usage and balance | Cost spike | one-api user/token/group settings enforce text and vision limits separately | Over-limit 429/rejection/queue evidence and provider no-usage check |
| static_pricing_page | Public page | Read-only static content | Not applicable | Published prices | Misleading pricing | Publish only approved model-specific pricing | Static content review |
| backup_restore | Infrastructure owner | Root-only backup evidence | ssh-key-only-or-strongly-restricted | SQLite data and encrypted backups | Data loss or disclosure | Encrypted offsite backup plus restore drill | Restore verification output |
| deploy_script | Infrastructure owner | Root deploy only | ssh-key-only-or-strongly-restricted | Runtime config | Unsafe release | No online deploy without gates; rollback protected | Staging rollback drill |
| historical_credential_incident | Security owner | Redacted evidence only | Not applicable | Historical secret category, not values | Secret recurrence | Store only non-sensitive rotation and invalidation evidence | Redacted audit record |
| legal_privacy | Business/privacy owners | Approved terms before launch | Not applicable | Customer data and provider processing | Terms/privacy mismatch | Provider, region, retention, deletion, resale/proxy rights approved | Dated policy and terms evidence |
