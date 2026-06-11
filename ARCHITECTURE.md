# DeepAPI — 技术架构文档 (ARCHITECTURE)

**版本:** v1.0  
**状态:** MVP  
**前置文档:** [PRD.md](./PRD.md)

---

## 1. 系统架构图

```
                          ┌────────────────────────────────┐
                          │       Cloudflare DNS            │
                          │   api.yourdomain.com → VPS IP  │
                          └──────────────┬─────────────────┘
                                         │ HTTPS :443
                                         ▼
┌──────────────────────────────────────────────────────────────────┐
│  VPS (RackNerd DC2 Los Angeles, Ubuntu 22.04, 1C/1G/20G)        │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  Nginx (systemd)                                              │ │
│  │  - SSL 终止 (Let's Encrypt / certbot)                        │ │
│  │  - 反向代理 :443 → 127.0.0.1:3000                             │ │
│  │  - client_max_body_size: 50m                                  │ │
│  │  - 限流: 待 v1.1                                              │ │
│  └──────────────────────────┬───────────────────────────────────┘ │
│                              │ TCP :3000 (localhost only)          │
│                              ▼                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  one-api (Docker, pinned ghcr.io/songquanpeng/one-api digest)│ │
│  │                                                                │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐  │ │
│  │  │ 用户管理  │  │ 模型路由  │  │ 计费引擎  │  │ 渠道池管理  │  │ │
│  │  │          │  │          │  │          │  │             │  │ │
│  │  │ - 注册   │  │ model→   │  │ - 按token │  │ - 多Key轮换 │  │ │
│  │  │ - 登录   │  │  channel │  │   扣费   │  │ - 健康检查  │  │ │
│  │  │ - APIKey │  │  映射    │  │ - 余额    │  │ - 故障转移  │  │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────┬──────┘  │ │
│  │                                                    │         │ │
│  └────────────────────────────────────────────────────┼─────────┘ │
│                                                       │           │
└───────────────────────────────────────────────────────┼───────────┘
                                                        │ HTTPS
                                        ┌───────────────┼───────────┐
                                        │               │           │
                                        ▼               ▼           ▼
                                  ┌──────────┐  ┌──────────┐ ┌──────────┐
                                  │ DeepSeek │  │ Silicon  │ │ 阿里云   │
                                  │ API      │  │ Flow API │ │ DashScope│
                                  └──────────┘  └──────────┘ └──────────┘
```

---

## 2. 组件详解

### 2.1 反向代理层：Nginx

| 配置项 | 值 | 原因 |
|--------|-----|------|
| 监听端口 | 80, 443 | 80 仅做 301→HTTPS |
| SSL 证书 | Let's Encrypt (certbot) | 免费、自动续期 |
| proxy_pass | http://127.0.0.1:3000 | one-api 容器映射 |
| 请求体限制 | 50m | 兼容大型 JSON payload |
| Gzip | on | 减少带宽 |
| HTTP/2 | on | 多路复用，减少延迟 |

### 2.2 API 网关：one-api

**仓库:** [songquanpeng/one-api](https://github.com/songquanpeng/one-api)  
**协议:** MIT  
**运行方式:** Docker 容器， `--restart=always`

#### 核心模块

| 模块 | 功能 | MVP 状态 |
|------|------|---------|
| 用户系统 | 注册/登录/API Key 生成/角色管理 | ✅ |
| 渠道管理 | 添加/编辑/删除模型供应商 | ✅ |
| 模型路由 | 用户请求 model → 映射到实际渠道 | ✅ |
| 计费引擎 | 按 token 计费，余额扣减 | ✅ |
| 速率限制 | 每用户 / 每 Key 频率控制 | ✅ |
| 调用日志 | 请求/响应记录，扣费明细 | ✅ |
| 充值系统 | 后台手动充值 | ✅ v1 手动 |

#### 数据存储

one-api 使用 **SQLite** 嵌入式数据库（文件位于 `/opt/one-api/data/one-api.db`），MV
无需额外数据库服务——简单到极简。

| 表 | 用途 |
|----|------|
| users | 用户账号 + 余额 |
| tokens | 用户 API Key |
| channels | 模型供应商配置 |
| logs | 每次 API 调用的完整记录 |
| options | 系统设置 |

### 2.3 模型渠道层

#### 渠道模型映射

| 用户请求 model | 实际渠道 | 实际模型 |
|---------------|---------|---------|
| gpt-4o / deepseek-chat | DeepSeek | deepseek-chat |
| gpt-4 / qwen-max | 阿里云 | qwen-max |
| gpt-3.5-turbo / qwen-plus | 阿里云 | qwen-plus |
| qwen2.5-7b | 硅基流动 | Qwen/Qwen2.5-7B-Instruct |

> **设计原则:** 用户调用标准 OpenAI model 名，one-api 内部路由到对应国产模型，用户无感知。

---

## 3. 数据流

```
用户发送 POST /v1/chat/completions
    │
    ▼
Nginx :443 (SSL 解密)
    │
    ▼
one-api :3000
    │
    ├─ 1. 解析 Authorization: Bearer <user_token>
    ├─ 2. 查 tokens 表 → 获取 user_id
    ├─ 3. 查 users 表 → 余额是否充足
    ├─ 4. 解析 body.model → 路由到 channel
    ├─ 5. 从渠道池选一个可用的 API Key
    ├─ 6. 转发请求到国产模型 API
    ├─ 7. 接收响应 → 计算 token 用量
    ├─ 8. 扣减用户余额
    ├─ 9. 写入 logs 表
    └─ 10. 返回响应给用户
```

---

## 4. 安全模型

### 4.1 网络层

```
公网开放:
  - SSH :22  (仅密钥登录，禁止密码登录)
  - HTTP :80  (→ 301 HTTPS)
  - HTTPS :443 (Nginx, rate-limited)

防火墙封禁:
  - :3000 (one-api 直接端口)
  - 除 22/80/443 外的所有端口

UFW 规则:
  ufw default deny incoming
  ufw allow 22
  ufw allow 80
  ufw allow 443
  ufw enable
```

### 4.2 应用层

| 风险 | 措施 |
|------|------|
| SQLite 被下载 | Nginx 禁止访问 `*.db` 文件 |
| 暴力破解 | one-api 自带登录频率限制 |
| API Key 泄露 | 用户后台可随时重置 |
| 渠道 Key 泄露 | 定期轮换，one-api 支持批量替换 |
| 中间人 | 强制 HTTPS，HSTS 头 |

### 4.3 密钥管理

```
国产模型 API Key 存储:
  - 仅存在 one-api SQLite 数据库内
  - 管理后台可见（仅 root 账号）
  - 不外泄，不在日志中出现

GitHub PAT (deepapi-project):
  - 仅存储在 Windows 凭据管理器
  - 不在代码仓库中
  - 仅 repo 权限（最小权限原则）
```

---

## 5. 部署架构

### 5.1 单机部署（MVP）

```
VPS 资源配置:
  CPU: 1 vCore (Intel Xeon)
  RAM: 1 GB
  Disk: 20 GB SSD
  Bandwidth: 2 TB / month
  OS: Ubuntu 22.04 LTS

预计承载:
  - 50-200 并发请求
  - 100-1000 注册用户
  - 日均 10k-100k API 调用
```

### 5.2 目录结构

```
/opt/one-api/
├── data/
│   └── one-api.db          # SQLite 数据库（核心！）
│   └── one-api.db-shm      # SQLite WAL
│   └── one-api.db-wal      # SQLite WAL
│
/etc/nginx/
├── sites-available/
│   └── api-gateway         # Nginx 配置
├── sites-enabled/
│   └── api-gateway → ../sites-available/api-gateway
│
/etc/letsencrypt/           # SSL 证书（certbot 自动管理）
```

---

## 6. 运维

### 6.1 监控命令

```bash
# 容器状态
docker ps | grep one-api

# 实时日志
docker logs -f one-api

# 磁盘空间（SQLite 可能增长）
df -h /opt

# 数据库大小
ls -lh /opt/one-api/data/one-api.db
```

### 6.2 备份策略

```bash
# 每日备份（加入 crontab）
# 0 3 * * * tar -czf /root/backup/one-api-$(date +\%Y\%m\%d).tar.gz /opt/one-api/data

# 手动备份
tar -czf one-api-backup-$(date +%Y%m%d).tar.gz /opt/one-api/data
```

**备份内容:** 仅 `/opt/one-api/data/` 目录（含 SQLite 数据库，所有配置和用户数据）
**频率:** 建议每日自动 + 每次配置变更后手动备份
**恢复:** 停止容器 → 还原 data 目录 → 启动容器

### 6.3 更新流程

```bash
docker pull ghcr.io/songquanpeng/one-api@sha256:a55fb5181854aa0823cc04797ee875dfc5a953c0deb5e7e7ec39a8148e70cbc3
docker stop one-api
docker rm one-api
# 重新运行 deploy.sh 中的 docker run 命令
```

> 更新前务必先备份！

---

## 7. 技术债务 & 后续优化

| 项目 | 现状 | 目标 |
|------|------|------|
| 数据库 | SQLite 单文件 | v2.0 → PostgreSQL（高并发时） |
| 支付 | 手动充值 | v1.1 → Stripe 自动充值 |
| 缓存 | 无 | v1.2 → Redis 缓存热点请求 |
| 监控 | 手动 docker logs | v1.2 → Prometheus + Grafana |
| 日志 | SQLite logs 表 | v1.2 → 结构化日志 + 导出 |
| 高可用 | 单机 | v2.0 → 双机热备 + 负载均衡 |
| CDN | 无 | v2.0 → Cloudflare CDN 加速 |

---

## 8. 附录

### A. 端口规划

| 端口 | 服务 | 公网 | 用途 |
|------|------|------|------|
| 22 | SSH | ✅ | 管理登录 |
| 80 | Nginx | ✅ | HTTP → 301 HTTPS |
| 443 | Nginx | ✅ | HTTPS API |
| 3000 | one-api | ❌ | 仅 localhost |

### B. 环境变量（one-api Docker）

| 变量 | 值 | 说明 |
|------|-----|------|
| TZ | Asia/Shanghai | 日志时区 |

---

**文档版本:** v1.0  
**下次更新:** 部署完成后的实际端口和域名确认
