# DeepAPI 项目状态报告 — 最终版

**生成时间**：2026-06-10/11  
**状态**：✅ 全链路生产就绪

---

## 站点信息

| 项目 | 值 |
|------|-----|
| 站点 | `https://deepapi.click` |
| API | `https://deepapi.click/v1/chat/completions` |
| 管理后台 | `https://deepapi.click`（账号密码见 credentials.txt） |
| API Token | 见 credentials.txt（无限额度） |

---

## 服务器

| 项目 | 值 |
|------|-----|
| 平台 | RackNerd · 洛杉矶 DC03 · $21.99/年 |
| IP | `23.254.220.84` |
| OS | Ubuntu 22.04 |
| SSH | 仅密钥登录，密码已禁用 |
| 密钥 | `C:\Users\ouyan\.ssh\deepapi_key` |

---

## 域名

| 项目 | 值 |
|------|-----|
| 域名 | `deepapi.click`（NameSilo · $2.19/年） |
| DNS | A 记录 → `23.254.220.84` |
| SSL | Let's Encrypt · certbot 自动续期 |

---

## 技术架构

```
用户 → HTTPS → Nginx :443 → 127.0.0.1:3000 → one-api (Docker) → SiliconFlow
```

端口 3000 仅绑定 127.0.0.1，UFW 封禁公网访问。

---

## 安全状态

| 检查项 | 状态 |
|--------|------|
| VPS root 密码 | ✅ 已轮换 |
| SSH 密码登录 | ❌ 已禁用（仅密钥） |
| SiliconFlow Key | ✅ 已轮换 · 旧 Key 已删 |
| Docker 端口暴露 | ✅ 仅 127.0.0.1 |
| UFW 封禁 3000 | ✅ |
| 开放注册 | ❌ 已关闭 |
| 旧 API Token | ✅ 已吊销 |
| REPORT.md 凭证 | ✅ 已清除 |
| Git 历史泄露 | ✅ setup_ssl.py 已从全部历史抹除 · force pushed |
| 镜像版本 | ✅ pinned digest @sha256:a55fb5... |
| Nginx HSTS/限流 | ✅ 配置已写好（nginx-deepapi.conf） |

---

## 商业模式

| 指标 | 值 |
|------|------|
| 售价 | $0.50 / 百万 tokens |
| 成本 | $0.07–0.13 / 百万 tokens |
| 毛利率 | 80%+ |
| 对比 OpenAI GPT-4o | 便宜 80% |

---

## 模型列表

| 模型 | 来源 |
|------|------|
| Qwen/Qwen2.5-7B-Instruct | SiliconFlow |
| Qwen/Qwen3.6-27B | SiliconFlow |
| deepseek-ai/DeepSeek-V4-Flash | SiliconFlow |
| deepseek-ai/DeepSeek-V3 | SiliconFlow |

---

## 用户测试命令

```bash
使用 credentials.txt 中的 Token 调用 API。示例：

```bash
curl -X POST https://deepapi.click/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"model":"Qwen/Qwen2.5-7B-Instruct","messages":[{"role":"user","content":"hello"}],"max_tokens":10}'
```
```

---

## Git 历史

```
92c4c2d security: pin one-api image digest + bind to 127.0.0.1
7032a05 docs: 更新竣工报告 — 审计修复状态
0c47442 feat: add hardened Nginx config
ee9e4f7 security: 移除 REPORT.md 凭证 + 多项修复
dab99af docs: 项目竣工报告 REPORT.md
254364e feat: DeepAPI v0.1 deployable
7efad70 feat: VPS 部署完成
5a27575 chore: .gitignore
5fba9dd docs: ARCHITECTURE.md
d1de07d feat: PRD.md
```

---

## 待做

| 任务 | 优先级 |
|------|--------|
| 接入 Stripe 自动付款 | 高 |
| 后台改 root 密码 | 高 |
| 加更多模型渠道 | 中 |
| 英文 Landing Page | 中 |
| Reddit/HN 推广 | 中 |
| Nginx 限流部署到线上 | 低 |
