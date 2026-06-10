
# DeepAPI 中转站 - 完整项目文档

## 一、项目目标

搭建一个 AI API 中转服务，前端对海外用户提供标准 OpenAI API 格式，后端调用国产大模型（DeepSeek / 通义千问 / 硅基流动），利用国内外模型价格差盈利。

**核心指标：**
- 用户每月 $9.9 起订阅
- 毛利 80%+（国产模型成本仅 OpenAI 的 1/10 到 1/5）
- 10 个付费用户即可实现月收入 $99

---

## 二、技术架构

```
用户（海外开发者）
    ↓ 标准 OpenAI API 协议，https://api.yourdomain.com
    ↓
Cloudflare DNS（域名解析 → 你的 VPS IP）
    ↓
Nginx（SSL 终止 + 反向代理到 one-api:3000）
    ↓
one-api（开源 API 网关，Docker 运行）
    ├── 用户管理（注册 / API Key 管理 / 余额管理）
    ├── 模型路由（用户调 gpt-4 → 实际走 DeepSeek）
    ├── 计费系统（按 token 扣费 / 速率限制）
    └── 渠道池（轮换多个国产模型 Key）
    ↓
国产模型 API（DeepSeek / 通义千问 / 硅基流动）
```

**关键开源项目：**
- [one-api](https://github.com/songquanpeng/one-api)——MIT 协议，20k+ star，稳定

---

## 三、你需要买的东西（一次性）

| 物品 | 平台 | 价格 | 步骤 |
|------|------|------|------|
| VPS | racknerd.com | $17.98/年 | 选 Los Angeles 机房 / Ubuntu 22.04 / 1核1G |
| 域名 | namesilo.com | ~$10/年 | 买最便宜的，如 `cheap-ai-api.com` |

**购买完成你会得到：**
- 服务器 IP（如 192.168.1.100）
- root 密码
- 你的域名

---

## 四、一键部署脚本

把以下内容保存为 `deploy.sh`，上传到 VPS 的 `/root/` 目录：

```bash
#!/bin/bash
set -e

echo "=========================================="
echo " DeepAPI 一键部署脚本"
echo "=========================================="

# --- 基础环境 ------------------------------------------------
echo "[1/6] 更新系统…"
apt update -y && apt upgrade -y

echo "[2/6] 安装 Docker…"
apt install -y docker.io docker-compose
systemctl enable docker
systemctl start docker

echo "[3/6] 安装 Nginx 和 certbot…"
apt install -y nginx certbot python3-certbot-nginx

# --- 部署 one-api ------------------------------------------------
echo "[4/6] 部署 one-api 容器…"
mkdir -p /opt/one-api/data

docker run -d \
  --name one-api \
  --restart=always \
  -p 3000:3000 \
  -v /opt/one-api/data:/data \
  -v /etc/localtime:/etc/localtime:ro \
  -e TZ=Asia/Shanghai \
  ghcr.io/songquanpeng/one-api:latest

sleep 3
echo "one-api 容器已启动，初始账号: root  密码: 123456"

# --- 写 Nginx 配置模板 ------------------------------------------------
echo "[5/6] 写 Nginx 配置…"
cat /dev/null
read -p "请输入你的域名（如 api.yourdomain.com）: " DOMAIN

cat > /etc/nginx/sites-available/api-gateway <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # 上传限制 50MB
        client_max_body_size 50m;
    }
}
EOF

ln -sf /etc/nginx/sites-available/api-gateway /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# --- SSL 证书 ------------------------------------------------
echo "[6/6] 配置 SSL 证书…"
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos \
  --email admin@${DOMAIN} --redirect

echo ""
echo "=========================================="
echo " 部署完成！"
echo " 访问: https://${DOMAIN}"
echo " 初始账号: root"
echo " 初始密码: 123456"
echo " 务必立刻修改密码！！！"
echo "=========================================="
```

---

## 五、Codex 部署操作指令

Codex 登录 VPS 后按以下步骤执行：

### Step 1：SSH 登录 VPS

```bash
ssh root@你的VPS的IP
# 输入密码
```

### Step 2：上传部署脚本

在 VPS 上执行：

```bash
nano /root/deploy.sh
# 把上面的 deploy.sh 内容粘贴进去
# Ctrl+O 保存，Ctrl+X 退出
chmod +x /root/deploy.sh
```

### Step 3：跑脚本

```bash
bash /root/deploy.sh
```

脚本运行中会提示输入域名，填入你买好的域名（如 `api.yourdomain.com`）。

### Step 4：脚本跑完后验证

```bash
# 确认 one-api 容器在运行
docker ps | grep one-api

# 确认 Nginx 正常
systemctl status nginx

# 确认端口监听
netstat -tlnp | grep -E "80|443|3000"
```

---

## 六、DNS 域名解析配置

脚本跑完后，你需要去域名商那里加 DNS 记录：

**类型:** A  
**名称:** @ （或 api，取决于你想用 api.xxx.com 还是直接用根域名）  
**值:** 你的 VPS IP  
**TTL:** 自动或 3600

等 2-10 分钟 DNS 生效后，浏览器访问 `https://你的域名` 能打开 one-api 后台登录页，即成功。

---

## 七、one-api 后台配置（人工操作）

### 7.1 登录并改密码
1. 访问 `https://你的域名`
2. 账号: `root`，密码: `123456`
3. **立刻**去右上角个人设置改密码

### 7.2 添加国产模型渠道

进「渠道」页面，逐个添加：

#### 渠道 1：DeepSeek
| 字段 | 值 |
|------|-----|
| 渠道名称 | DeepSeek-V3 |
| API 类型 | OpenAI |
| 渠道类型 | 自定义渠道 |
| Base URL | `https://api.deepseek.com` |
| 模型匹配 | deepseek-chat |
| 密钥 | 你的 DeepSeek API Key |
| 分组 | default |

#### 渠道 2：硅基流动（SiliconFlow）
| 字段 | 值 |
|------|-----|
| 渠道名称 | SiliconFlow |
| API 类型 | OpenAI |
| 渠道类型 | 自定义渠道 |
| Base URL | `https://api.siliconflow.cn/v1` |
| 模型匹配 | Qwen/Qwen2.5-7B-Instruct；Qwen/Qwen2.5-72B-Instruct |
| 密钥 | 你的硅基流动 API Key |
| 分组 | default |

> 硅基流动注册即送 14 元额度，无需手机验证，推荐多注册几个。

#### 渠道 3：通义千问（可选）
| 字段 | 值 |
|------|-----|
| 渠道名称 | Qwen-Max |
| API 类型 | OpenAI |
| 渠道类型 | 自定义渠道 |
| Base URL | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| 模型匹配 | qwen-max；qwen-plus |
| 密钥 | 你的阿里云 API Key |
| 分组 | default |

### 7.3 设置定价

进「设置」→「运营设置」：

| 设置项 | 推荐值 |
|--------|--------|
| 模型价格设置 | 自定义 |
| 输入价格 | $0.50 / 1M tokens |
| 输出价格 | $0.80 / 1M tokens |
| 新用户注册赠送额度 | $0.50 |
| 注册方式 | 开放注册 |

> 这个定价 vs OpenAI：便宜 75-85%，同时你的毛利 60-80%

### 7.4 启用用户注册

进「设置」→「系统设置」：
- 关闭「禁止用户注册」开关
- 设置「用户注册后初始额度」: 500000（约 $0.25 价值的 token）

---

## 八、测试全流程

### 8.1 注册一个测试用户
访问 `https://你的域名`，用不同邮箱注册一个新账号，登录后拿到用户 API Key。

### 8.2 用 curl 测试

```bash
curl -X POST https://你的域名/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 用户APIKey" \
  -d '{
    "model": "deepseek-chat",
    "messages": [{"role": "user", "content": "Hello, who are you?"}]
  }'
```

预期返回：DeepSeek 的正常回复。

### 8.3 确认计费
回 one-api 管理后台 → 「日志」页面查看刚才的调用记录和扣费是否正确。

---

## 九、推广材料（英文）

### Reddit r/SideProject 帖子模板

```
Title: I built an API that costs 1/5 of GPT-4o and performs almost the same

Hi everyone,

I was sick of paying $200+/month for GPT-4o API for my side projects.
So I built a simple API gateway that connects you to affordable models.

Pricing:
- $9.9/mo = 50M tokens
- $29/mo = 300M tokens
- Pay-as-you-go available

It's drop-in compatible with OpenAI's API — just change your base URL and API key.
My cost is transparent, and the service just works.

Check it out: https://your-domain.com

Happy to take feedback!
```

### Indie Hackers 帖子模板

```
How I built an AI API proxy in 2 weeks and why I think the market is still wide open

- Used open-source API gateway (one-api)
- One VPS, one domain, $30 total upfront
- $9.9/mo pricing — way below every mainstream provider
- Target: indie devs who don't need the strongest reasoning

Ask me anything about the tech or the business model.
```

---

## 十、日常维护

### 换 Key（被封后）
1. 去 DeepSeek / 硅基流动重新注册一个号拿 Key
2. 进 one-api 后台 → 渠道 → 编辑 → 替换密钥
3. 用户无感知

### 监控
```bash
# 看容器状态
docker ps

# 看 one-api 日志
docker logs -f one-api

# 看磁盘
df -h
```

### 备份
```bash
# one-api 的所有配置都在这里，定期备份这个目录
tar -czf one-api-backup-$(date +%Y%m%d).tar.gz /opt/one-api/data
# 把备份文件下载到你本机保存
```

---

## 十一、安全注意事项

1. **必须改默认密码**：one-api 的 root/123456 是公开的，部署完第一时间改
2. **Server 端口只开 22/80/443**：
   ```bash
   ufw allow 22
   ufw allow 80
   ufw allow 443
   ufw enable
   ```
3. **不要对外暴露 3000 端口**——所有流量应该走 Nginx
4. **定期更新 one-api 镜像**：
   ```bash
   docker pull ghcr.io/songquanpeng/one-api:latest
   docker stop one-api && docker rm one-api
   # 重新跑上面的 docker run 命令
   ```

---

## 十二、文件清单

给 Codex 的任务清单：

- [ ] 登录 VPS
- [ ] 创建并执行 deploy.sh
- [ ] 确认 Docker 容器运行
- [ ] 配置 DNS A 记录
- [ ] 验证 HTTPS 可访问
- [ ] 登录 one-api 修改密码
- [ ] 添加至少 2 个模型渠道
- [ ] 配置定价
- [ ] 开启用户注册
- [ ] curl 测试全链路
- [ ] 确认计费日志正常
- [ ] 放出推广帖

---

**文档版本:** v1.0  
**更新时间:** 2025-01  
**适用范围:** RackNerd VPS + Ubuntu 22.04 + one-api + DeepSeek/硅基流动
