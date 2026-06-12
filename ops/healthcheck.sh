#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-one-api}"
LOCAL_STATUS_URL="${LOCAL_STATUS_URL:-http://127.0.0.1:3000/api/status}"
DISK_PATH="${DISK_PATH:-/opt/one-api}"
DISK_MAX_PERCENT="${DISK_MAX_PERCENT:-85}"
PUBLIC_HTTPS_URL="${PUBLIC_HTTPS_URL:-}"

docker inspect --format '{{.State.Running}}' "${CONTAINER_NAME}" | grep -Fxq true
curl --fail --silent --show-error --max-time 10 --output /dev/null "${LOCAL_STATUS_URL}"

if [[ -n "${PUBLIC_HTTPS_URL}" ]]; then
  curl --fail --silent --show-error --max-time 10 --output /dev/null "${PUBLIC_HTTPS_URL}"
fi

disk_percent="$(df -P "${DISK_PATH}" | awk 'NR==2 {gsub("%","",$5); print $5}')"
[[ "${disk_percent}" =~ ^[0-9]+$ ]]
(( disk_percent < DISK_MAX_PERCENT ))
