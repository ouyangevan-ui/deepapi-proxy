#!/usr/bin/env bash
set -euo pipefail

BACKUP_CONFIG="${BACKUP_CONFIG:-/etc/deepapi/backup.env}"

[[ -f "${BACKUP_CONFIG}" && ! -L "${BACKUP_CONFIG}" ]] || {
  echo "Backup config must be a regular file, not a symlink: ${BACKUP_CONFIG}" >&2
  exit 1
}

owner_uid="$(stat -c '%u' "${BACKUP_CONFIG}")"
mode="$(stat -c '%a' "${BACKUP_CONFIG}")"
[[ "${owner_uid}" == "0" ]] || {
  echo "Backup config must be owned by root" >&2
  exit 1
}
(( (8#${mode} & 077) == 0 )) || {
  echo "Backup config must not grant group or other permissions" >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
. "${BACKUP_CONFIG}"
set +a
exec /usr/local/sbin/deepapi-backup
