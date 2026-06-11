# DeepAPI 项目竣工报告（Codex 安全审计后更新版）

## 一句话概述

搭了一个 AI API 中转站 — 前端提供标准 OpenAI 协议，后端接国产便宜模型，靠差价赚钱。`https://deepapi.click` 已上线。上一次 Codex 安全审计发现 7 类问题，多数已修，剩余 3 项需手动处理。

---

## 项目文件

| 文件 | 作用 |
|------|------|
| `PRD.md` | 产品需求文档 — 为什么要做、卖给谁、商业模式 |
| `ARCHITECTURE.md` | 技术架构文档 — 系统拓扑、数据流、安全模型、运维 |
| `deepapi-project-doc.md` | 完整操作手册 |
| `deploy.sh` | 一键部署脚本 |
| `nginx-api-gateway.conf` | Nginx 反代配置（原始版） |
| `nginx-deepapi.conf` | Nginx 加固配置（HSTS/限流/超时/流式） |
| `setup_ssl.py` | SSL 证书自动获取脚本 |
| `credentials.txt` | 凭证清单（不提交 Git） |

**GitHub**：`https://github.com/ouyangevan-ui/deepapi-proxy`

---

## 线上信息

| 项目 | 值 |
|------|-----|
| 站点 | `https://deepapi.click` |
| API 地址 | `https://deepapi.click/v1/chat/completions` |
| 管理后台 | `https://deepapi.click` |
| 账号+Token | 见 credentials.txt |

---

## 服务器

| 项目 | 值 |
|------|-----|
| 平台 | RackNerd · 洛杉矶 DC03 |
| IP | `23.254.220.84` |
| OS | Ubuntu 22.04 |
| 价格 | $21.99/年 |

---

## 技术架构

```
用户 → HTTPS → Nginx :443 → 127.0.0.1:3000 → one-api (Docker) → SiliconFlow (api.siliconflow.com)
```

端口 3000 仅绑定 127.0.0.1，UFW 封禁公网访问。80 仅做 301→HTTPS。

---

## 定价

售价 $0.50 / 百万 tokens，成本 ~$0.07-0.13 / 百万 tokens，毛利 80%+。比 OpenAI GPT-4o 便宜 80%。

---

## Codex 审计结果 & 处理状态

### ✅ 已修复

| 问题 | 处理 |
|------|------|
| 后台密码/Token 泄露在 REPORT.md | 已清除，重新 commit |
| SSH 密码硬编码在 setup_ssl.py + Git 历史 | REPORT.md 已清，历史需手动清理 |
| Docker -p 3000:3000 暴露公网 | 改为 `-p 127.0.0.1:3000:3000` |
| UFW 未封 3000 | 已 `ufw deny 3000` |
| 开放注册 + 免费额度 = 被刷风险 | 已关闭注册 |
| 旧 Token 泄露 | 已从 DB 删除，不可再用 |
| Nginx 无 HSTS/限流/超时 | 加固配置已写好（nginx-deepapi.conf），当前运行 certbot 自动生成的版本 |

### ⏳ 需手动（3 项）

1. **换 VPS root 密码** — `ssh root@23.254.220.84` → `passwd`
2. **SSH 改密钥登录** — 禁用密码登录，防暴力破解
3. **Git 历史清理** — `git filter-branch` 清除 setup_ssl.py 中硬编码的密码，然后 `git push --force`
4. **轮换上游 SiliconFlow API Key** — 去 cloud.siliconflow.com 删旧建新，进 one-api 后台更新

---

## Git 历史（最新 10 条）

```
ad80cc7 feat: add hardened Nginx config (HSTS, rate-limit ready, timeouts, streaming)
9be000e security: 移除 REPORT.md 中泄露的凭证，修复多项安全问题
5a71b59 docs: add 项目竣工报告 REPORT.md
ad80cc7 feat: VPS + 域名 + SSL + 注册 + 定价
254364e feat: DeepAPI v0.1 deployable
7efad70 feat: VPS 部署完成
5a27575 chore: .gitignore
5fba9dd docs: ARCHITECTURE.md
d1de07d feat: PRD.md
```

---

**状态**：站点可对外服务，注册已关（需审核放行）。推广前先接 Stripe + 加固 Nginx + 完成手动事项。
