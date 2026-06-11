#!/usr/bin/env bash
set -euo pipefail

# DeepAPI production deploy script.
#
# Usage on the VPS:
#   DOMAIN=deepapi.click ADMIN_EMAIL=admin@example.com bash deploy.sh

DOMAIN="${DOMAIN:-deepapi.click}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"
ONE_API_IMAGE="${ONE_API_IMAGE:-ghcr.io/songquanpeng/one-api@sha256:a55fb5181854aa0823cc04797ee875dfc5a953c0deb5e7e7ec39a8148e70cbc3}"
APP_DIR="${APP_DIR:-/opt/one-api}"
CONTAINER_NAME="${CONTAINER_NAME:-one-api}"

if [[ "$(id -u)" != "0" ]]; then
  echo "Run as root on the VPS." >&2
  exit 1
fi

if [[ "${ONE_API_IMAGE}" == *":latest" ]]; then
  echo "Refusing to deploy :latest. Use a pinned tag or sha256 digest." >&2
  exit 1
fi

echo "[1/8] Installing system packages"
apt-get update -y
apt-get install -y docker.io nginx certbot python3-certbot-nginx ufw logrotate
systemctl enable --now docker nginx

echo "[2/8] Configuring firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 3000/tcp || true
ufw --force enable

echo "[3/8] Configuring Docker log rotation"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5"
  }
}
EOF
systemctl restart docker

echo "[4/8] Preparing data and backup directories"
mkdir -p "${APP_DIR}/data" /root/backup/deepapi
chmod 700 "${APP_DIR}" "${APP_DIR}/data" /root/backup/deepapi

echo "[5/8] Starting one-api on 127.0.0.1 only"
if docker ps -a --format '{{.Names}}' | grep -Fxq "${CONTAINER_NAME}"; then
  docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart=always \
  -p 127.0.0.1:3000:3000 \
  -v "${APP_DIR}/data:/data" \
  -v /etc/localtime:/etc/localtime:ro \
  -e TZ=Asia/Shanghai \
  "${ONE_API_IMAGE}"

if [[ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
  echo "[6/8] Installing temporary HTTP config for certificate issuance"
  cat > /etc/nginx/sites-available/deepapi <<EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
  ln -sf /etc/nginx/sites-available/deepapi /etc/nginx/sites-enabled/deepapi
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl reload nginx

  echo "[7/8] Requesting Let's Encrypt certificate"
  certbot certonly --nginx -d "${DOMAIN}" -d "www.${DOMAIN}" \
    --non-interactive --agree-tos --email "${ADMIN_EMAIL}"
else
  echo "[6/8] Existing certificate found"
fi

echo "[7/8] Installing hardened Nginx config"
install -m 0644 nginx-rate-limit-zones.conf /etc/nginx/conf.d/deepapi-rate-limit-zones.conf
install -m 0644 nginx-deepapi.conf /etc/nginx/sites-available/deepapi
ln -sf /etc/nginx/sites-available/deepapi /etc/nginx/sites-enabled/deepapi
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "[8/8] Installing daily local backup cron"
cat > /etc/cron.d/deepapi-backup <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
15 3 * * * root tar -czf /root/backup/deepapi/one-api-\$(date +\%Y\%m\%d).tar.gz -C ${APP_DIR} data && find /root/backup/deepapi -type f -name 'one-api-*.tar.gz' -mtime +14 -delete
EOF

echo "DeepAPI deploy complete."
echo "Verify:"
echo "  docker ps --filter name=${CONTAINER_NAME}"
echo "  ss -ltnp | grep 3000     # must show 127.0.0.1:3000 only"
echo "  ufw status verbose"
echo "  curl -I https://${DOMAIN}"
