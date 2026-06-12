#!/usr/bin/env bash
set -euo pipefail

DB_PATH="${DB_PATH:-/opt/one-api/data/one-api.db}"
BACKUP_OFFSITE_DIR="${BACKUP_OFFSITE_DIR:?Set BACKUP_OFFSITE_DIR to an encrypted offsite mount}"
AGE_RECIPIENTS_FILE="${AGE_RECIPIENTS_FILE:?Set AGE_RECIPIENTS_FILE to a root-owned age recipients file}"
BACKUP_LOCAL_TMP="${BACKUP_LOCAL_TMP:-/var/tmp/deepapi-backup}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

[[ "${BACKUP_OFFSITE_DIR}" == /* ]] || { echo "BACKUP_OFFSITE_DIR must be absolute" >&2; exit 1; }
[[ "${BACKUP_LOCAL_TMP}" == /* ]] || { echo "BACKUP_LOCAL_TMP must be absolute" >&2; exit 1; }
[[ -d "${BACKUP_OFFSITE_DIR}" ]] || { echo "Backup destination does not exist: ${BACKUP_OFFSITE_DIR}" >&2; exit 1; }
[[ -f "${DB_PATH}" ]] || { echo "Database not found: ${DB_PATH}" >&2; exit 1; }
[[ -f "${AGE_RECIPIENTS_FILE}" && ! -L "${AGE_RECIPIENTS_FILE}" ]] || {
  echo "AGE_RECIPIENTS_FILE must be a regular file, not a symlink" >&2
  exit 1
}
[[ "$(stat -c '%u' "${AGE_RECIPIENTS_FILE}")" == "0" ]] || {
  echo "AGE_RECIPIENTS_FILE must be owned by root" >&2
  exit 1
}
(( (8#$(stat -c '%a' "${AGE_RECIPIENTS_FILE}") & 022) == 0 )) || {
  echo "AGE_RECIPIENTS_FILE must not be group/other writable" >&2
  exit 1
}

mount_target="$(findmnt -n -o TARGET -T "${BACKUP_OFFSITE_DIR}")"
[[ -n "${mount_target}" && "${mount_target}" != "/" ]] || {
  echo "BACKUP_OFFSITE_DIR must be on a separately mounted offsite filesystem" >&2
  exit 1
}

install -d -m 0700 "${BACKUP_LOCAL_TMP}"
work_dir="$(mktemp -d "${BACKUP_LOCAL_TMP%/}/run.XXXXXX")"
trap 'rm -rf "${work_dir}"' EXIT
snapshot="${work_dir}/one-api.db"
archive="${work_dir}/deepapi-backup.tar.gz"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
destination="${BACKUP_OFFSITE_DIR}/deepapi-${timestamp}.tar.gz.age"

sqlite3 "${DB_PATH}" ".timeout 30000" ".backup '${snapshot}'"
[[ "$(sqlite3 "${snapshot}" 'PRAGMA integrity_check;')" == "ok" ]] || {
  echo "SQLite integrity check failed" >&2
  exit 1
}

tar -C "${work_dir}" -czf "${archive}" one-api.db
age --encrypt --recipients-file "${AGE_RECIPIENTS_FILE}" --output "${destination}.tmp" "${archive}"
chmod 0600 "${destination}.tmp"
mv "${destination}.tmp" "${destination}"
(cd "${BACKUP_OFFSITE_DIR}" && sha256sum "$(basename "${destination}")" > "$(basename "${destination}").sha256")

find "${BACKUP_OFFSITE_DIR}" -maxdepth 1 -type f \
  \( -name 'deepapi-*.tar.gz.age' -o -name 'deepapi-*.tar.gz.age.sha256' \) \
  -mtime "+${BACKUP_RETENTION_DAYS}" -delete

echo "${destination}"
