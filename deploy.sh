#!/usr/bin/env bash
set -euo pipefail

# DeepAPI production deploy script. Run from a checked-out repository on the VPS.

DOMAIN="${DOMAIN:-}"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"
ONE_API_IMAGE="${ONE_API_IMAGE:-ghcr.io/songquanpeng/one-api@sha256:a55fb5181854aa0823cc04797ee875dfc5a953c0deb5e7e7ec39a8148e70cbc3}"
APP_DIR="${APP_DIR:-/opt/one-api}"
CONTAINER_NAME="${CONTAINER_NAME:-one-api}"
ROLLBACK_NAME="${CONTAINER_NAME}-rollback"
ENABLE_WWW="${ENABLE_WWW:-0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BRAND_DIR="/var/www/deepapi-brand"
SITE_DIR="/var/www/deepapi-site"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

container_exists() {
  docker container inspect "$1" >/dev/null 2>&1
}

rollback_container() {
  echo "New container failed health checks; restoring rollback container." >&2
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  if container_exists "${ROLLBACK_NAME}"; then
    docker rename "${ROLLBACK_NAME}" "${CONTAINER_NAME}"
    docker start "${CONTAINER_NAME}" >/dev/null
  fi
}

restore_nginx_config() {
  if [[ -f /etc/nginx/sites-available/deepapi.rollback ]]; then
    mv /etc/nginx/sites-available/deepapi.rollback /etc/nginx/sites-available/deepapi
  else
    rm -f /etc/nginx/sites-available/deepapi /etc/nginx/sites-enabled/deepapi
  fi
  if [[ -f /etc/nginx/conf.d/deepapi-rate-limit-zones.conf.rollback ]]; then
    mv /etc/nginx/conf.d/deepapi-rate-limit-zones.conf.rollback /etc/nginx/conf.d/deepapi-rate-limit-zones.conf
  else
    rm -f /etc/nginx/conf.d/deepapi-rate-limit-zones.conf
  fi
}

[[ "$(id -u)" == "0" ]] || fail "Run as root on the VPS."
[[ -n "${DOMAIN}" ]] || fail "Set DOMAIN explicitly."
[[ -n "${ADMIN_EMAIL}" ]] || fail "Set ADMIN_EMAIL explicitly."
[[ "${DOMAIN}" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]] \
  || fail "DOMAIN is not a valid DNS name."
[[ "${ADMIN_EMAIL}" == *"@"* ]] || fail "ADMIN_EMAIL is not valid."
[[ "${ENABLE_WWW}" == "0" || "${ENABLE_WWW}" == "1" ]] || fail "ENABLE_WWW must be 0 or 1."
[[ "${ONE_API_IMAGE}" == *@sha256:* ]] || fail "ONE_API_IMAGE must be pinned by sha256 digest."
[[ "${APP_DIR}" == /* ]] || fail "APP_DIR must be an absolute path."
[[ -f "${SCRIPT_DIR}/nginx-deepapi.conf" ]] || fail "Missing nginx-deepapi.conf."
[[ -f "${SCRIPT_DIR}/nginx-rate-limit-zones.conf" ]] || fail "Missing nginx-rate-limit-zones.conf."
[[ -f "${SCRIPT_DIR}/ops/backup.sh" ]] || fail "Missing ops/backup.sh."
[[ -f "${SCRIPT_DIR}/ops/backup-job.sh" ]] || fail "Missing ops/backup-job.sh."
[[ -f "${SCRIPT_DIR}/ops/predeploy-backup-gate.sh" ]] || fail "Missing ops/predeploy-backup-gate.sh."
[[ -f "${SCRIPT_DIR}/ops/restore-verify.sh" ]] || fail "Missing ops/restore-verify.sh."
[[ -f "${SCRIPT_DIR}/ops/healthcheck.sh" ]] || fail "Missing ops/healthcheck.sh."
[[ -f "${SCRIPT_DIR}/static/pricing/index.html" ]] || fail "Missing static/pricing/index.html."
[[ -f "${SCRIPT_DIR}/brand/deepapi-logo.png" ]] || fail "Missing brand/deepapi-logo.png."
[[ -f "${SCRIPT_DIR}/brand/deepapi-logo.svg" ]] || fail "Missing brand/deepapi-logo.svg."
[[ -f "${SCRIPT_DIR}/brand/deepapi-icon.svg" ]] || fail "Missing brand/deepapi-icon.svg."
[[ -f "${SCRIPT_DIR}/brand/favicon.svg" ]] || fail "Missing brand/favicon.svg."

if container_exists "${ROLLBACK_NAME}"; then
  fail "Rollback container ${ROLLBACK_NAME} already exists; investigate before deploying."
fi

SERVER_NAMES="${DOMAIN}"
CERTBOT_DOMAINS=(-d "${DOMAIN}")
if [[ "${ENABLE_WWW}" == "1" ]]; then
  SERVER_NAMES="${SERVER_NAMES} www.${DOMAIN}"
  CERTBOT_DOMAINS+=(-d "www.${DOMAIN}")
fi

echo "[1/9] Installing required packages"
apt-get update -y
apt-get install -y age certbot curl nginx python3-certbot-nginx sqlite3 ufw
if ! command -v docker >/dev/null 2>&1; then
  apt-get install -y docker.io
  systemctl enable --now docker
fi
systemctl is-active --quiet docker || fail "Docker is not running."
systemctl enable --now nginx

echo "[2/9] Configuring firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 3000/tcp || true
ufw --force enable

echo "[3/9] Installing operations scripts and brand assets"
install -m 0750 "${SCRIPT_DIR}/ops/backup.sh" /usr/local/sbin/deepapi-backup
install -m 0750 "${SCRIPT_DIR}/ops/backup-job.sh" /usr/local/sbin/deepapi-backup-job
install -m 0750 "${SCRIPT_DIR}/ops/predeploy-backup-gate.sh" /usr/local/sbin/deepapi-predeploy-backup-gate
install -m 0750 "${SCRIPT_DIR}/ops/restore-verify.sh" /usr/local/sbin/deepapi-restore-verify
install -m 0750 "${SCRIPT_DIR}/ops/healthcheck.sh" /usr/local/sbin/deepapi-healthcheck
install -d -m 0755 "${BRAND_DIR}"
install -d -m 0755 "${SITE_DIR}/pricing"
install -m 0644 "${SCRIPT_DIR}/brand/deepapi-logo.png" "${BRAND_DIR}/deepapi-logo.png"
install -m 0644 "${SCRIPT_DIR}/brand/deepapi-logo.svg" "${BRAND_DIR}/deepapi-logo.svg"
install -m 0644 "${SCRIPT_DIR}/brand/deepapi-icon.svg" "${BRAND_DIR}/deepapi-icon.svg"
install -m 0644 "${SCRIPT_DIR}/brand/favicon.svg" "${BRAND_DIR}/favicon.svg"
install -m 0644 "${SCRIPT_DIR}/static/pricing/index.html" "${SITE_DIR}/pricing/index.html"

echo "[4/9] Preparing data directory and image"
install -d -m 0700 "${APP_DIR}" "${APP_DIR}/data"
docker pull "${ONE_API_IMAGE}"

echo "[5/9] Replacing container with rollback protection"
if container_exists "${CONTAINER_NAME}"; then
  echo "Running pre-deploy backup and recovery-evidence gate"
  /usr/local/sbin/deepapi-predeploy-backup-gate
  docker stop "${CONTAINER_NAME}" >/dev/null
  docker rename "${CONTAINER_NAME}" "${ROLLBACK_NAME}"
fi

if ! docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart=unless-stopped \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --log-opt max-size=10m \
  --log-opt max-file=5 \
  -p 127.0.0.1:3000:3000 \
  -v "${APP_DIR}/data:/data" \
  -v /etc/localtime:/etc/localtime:ro \
  -e TZ=Asia/Shanghai \
  "${ONE_API_IMAGE}"; then
  rollback_container
  fail "Could not start the new container."
fi

healthy=0
for _ in $(seq 1 30); do
  if CONTAINER_NAME="${CONTAINER_NAME}" /usr/local/sbin/deepapi-healthcheck; then
    healthy=1
    break
  fi
  sleep 2
done
if [[ "${healthy}" != "1" ]]; then
  rollback_container
  fail "New container did not become healthy."
fi

if container_exists "${ROLLBACK_NAME}"; then
  docker rm "${ROLLBACK_NAME}" >/dev/null
fi

echo "[6/9] Rendering Nginx config for ${DOMAIN}"
sed -e "s/__DOMAIN__/${DOMAIN}/g" -e "s/__SERVER_NAMES__/${SERVER_NAMES}/g" "${SCRIPT_DIR}/nginx-deepapi.conf" \
  > /etc/nginx/sites-available/deepapi.candidate

if [[ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
  cat > /etc/nginx/sites-available/deepapi-bootstrap <<EOF
server {
    listen 80;
    server_name ${SERVER_NAMES};
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
  ln -sfn /etc/nginx/sites-available/deepapi-bootstrap /etc/nginx/sites-enabled/deepapi
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl reload nginx
  certbot certonly --nginx "${CERTBOT_DOMAINS[@]}" \
    --non-interactive --agree-tos --email "${ADMIN_EMAIL}"
fi

echo "[7/9] Activating Nginx config"
install -m 0644 "${SCRIPT_DIR}/nginx-rate-limit-zones.conf" /etc/nginx/conf.d/deepapi-rate-limit-zones.conf.candidate
if [[ -f /etc/nginx/conf.d/deepapi-rate-limit-zones.conf ]]; then
  cp -a /etc/nginx/conf.d/deepapi-rate-limit-zones.conf /etc/nginx/conf.d/deepapi-rate-limit-zones.conf.rollback
fi
mv /etc/nginx/conf.d/deepapi-rate-limit-zones.conf.candidate /etc/nginx/conf.d/deepapi-rate-limit-zones.conf
if [[ -f /etc/nginx/sites-available/deepapi ]]; then
  cp -a /etc/nginx/sites-available/deepapi /etc/nginx/sites-available/deepapi.rollback
fi
mv /etc/nginx/sites-available/deepapi.candidate /etc/nginx/sites-available/deepapi
ln -sfn /etc/nginx/sites-available/deepapi /etc/nginx/sites-enabled/deepapi
rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/deepapi-bootstrap
if ! nginx -t; then
  restore_nginx_config
  nginx -t || true
  fail "Nginx candidate configuration failed validation."
fi
if ! systemctl reload nginx; then
  restore_nginx_config
  nginx -t && systemctl reload nginx || true
  fail "Nginx reload failed; previous configuration was restored."
fi
rm -f /etc/nginx/sites-available/deepapi.rollback /etc/nginx/conf.d/deepapi-rate-limit-zones.conf.rollback

echo "[8/9] Installing health and backup schedules"
cat > /etc/cron.d/deepapi-ops <<'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root /usr/local/sbin/deepapi-healthcheck >/dev/null || logger -p daemon.crit "DeepAPI health check failed"
15 3 * * * root /usr/local/sbin/deepapi-backup-job
EOF
chmod 0644 /etc/cron.d/deepapi-ops

echo "[9/9] Final local checks"
CONTAINER_NAME="${CONTAINER_NAME}" /usr/local/sbin/deepapi-healthcheck
nginx -t

echo "Deploy complete. Production remains NO-GO until every gate in PRODUCTION-READINESS.md has evidence."
