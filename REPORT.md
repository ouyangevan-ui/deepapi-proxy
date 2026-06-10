# DeepAPI 项目竣工报告

## 一句话概述

搭了一个 AI API 中转站 — 前端提供标准 OpenAI 协议，后端接国产便宜模型，靠差价赚钱。`https://deepapi.click` 已上线，随时接用户收钱。

---

## 项目文件（都在 api-proxy-project 目录）

| 文件 | 作用 |
|------|------|
| `PRD.md` | 产品需求文档 — 为什么要做、卖给谁、商业模式 |
| `ARCHITECTURE.md` | 技术架构文档 — 系统拓扑、数据流、安全模型、运维 |
| `deepapi-project-doc.md` | 完整操作手册 — Codex 照着就能重装一套 |
| `deploy.sh` | 一键部署脚本 — SSH 到 VPS 跑就行 |
| `nginx-api-gateway.conf` | Nginx 反代配置 |
| `setup_ssl.py` | SSL 证书自动获取脚本 |
| `credentials.txt` | 密码/Key/账号清单（不提交 Git） |

**GitHub 仓库**：`https://github.com/ouyangevan-ui/deepapi-proxy`

---

## 线上信息

| 项目 | 值 |
|------|-----|
| **站点** | `https://deepapi.click` |
| **API 地址** | `https://deepapi.click/v1/chat/completions` |
| **管理后台** | `https://deepapi.click` |
| **管理账号** | root（密码见 credentials.txt） |
| **测试 Token** | 见 credentials.txt |

---

## 服务器

| 项目 | 值 |
|------|-----|
| **平台** | RackNerd |
| **机房** | 洛杉矶 DC03 |
| **IP** | `23.254.220.84` |
| **OS** | Ubuntu 22.04 |
| **价格** | $21.99/年（已关自动续费） |
| **SSH** | `ssh root@23.254.220.84` |

---

## 域名

| 项目 | 值 |
|------|-----|
| **域名** | `deepapi.click` |
| **平台** | NameSilo |
| **价格** | $2.19/年（未保存支付方式） |
| **DNS** | A 记录 → `23.254.220.84` |
| **SSL** | Let's Encrypt（已配好，certbot 自动续期） |

---

## 技术架构

```
用户访问 https://deepapi.click
    ↓ HTTPS
Nginx :443 → 反代到 localhost:3000
    ↓
one-api (Docker 容器)
    ├── 用户管理（注册 / 登录 / API Key）
    ├── 计费引擎（按 token 扣费）
    ├── 模型路由（用户选模型 → 映射到国产后端）
    └── 渠道池
         └── SiliconFlow API (api.siliconflow.com)
              ├── Qwen/Qwen2.5-7B-Instruct (免费额度)
              ├── Qwen/Qwen3.6-27B
              ├── deepseek-ai/DeepSeek-V4-Flash ($0.13/M)
              └── deepseek-ai/DeepSeek-V3
```

---

## 定价

**售出价**：$0.50 / 百万 input tokens  
**成本价**：$0.07 — $0.13 / 百万 tokens（视模型）  
**毛利率**：80%+

对比 OpenAI：GPT-4o 价格 $2.50/M，DeepAPI 便宜 **80%**。

---

## 测试

使用 credentials.txt 中的 Token 调用 API。公共文档中不暴露凭证。

---

## 已做 & 待做

| 已完成 | 待做 |
|--------|------|
| VPS + 域名 + SSL | 接入 Stripe 自动付款 |
| one-api 网关部署 | 添加更多模型渠道 |
| SiliconFlow 渠道配好 | 写英文 Landing Page |
| 用户注册已开放 | Reddit/HN 推广 |
| 定价 $0.50/M | — |
| 自动扣款已关 | — |

---

## Git 历史

```
fb2f18a feat: DeepAPI v0.2 — 域名+注册+定价全面上线
254364e feat: DeepAPI v0.1 deployable — one-api + SiliconFlow 全链路通过
7efad70 feat: VPS 部署完成 — one-api 网关上线
5a27575 chore: add .gitignore
5fba9dd docs: add ARCHITECTURE.md — 技术架构文档 v1.0
d1de07d feat: add PRD.md — 产品需求文档 v1.0
```

---

**报告生成时间**：2026-06-10  
**当前状态**：✅ 全链路可对外服务
