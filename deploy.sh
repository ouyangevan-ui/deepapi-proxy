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
