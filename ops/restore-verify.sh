#!/usr/bin/env bash
set -euo pipefail

BACKUP_FILE="${1:?Usage: restore-verify.sh BACKUP_FILE}"
BACKUP_AGE_IDENTITY_FILE="${BACKUP_AGE_IDENTITY_FILE:?Set BACKUP_AGE_IDENTITY_FILE to the private age identity path}"

[[ -f "${BACKUP_FILE}" ]] || { echo "Backup not found: ${BACKUP_FILE}" >&2; exit 1; }
[[ -f "${BACKUP_FILE}.sha256" ]] || { echo "Checksum not found: ${BACKUP_FILE}.sha256" >&2; exit 1; }
[[ -r "${BACKUP_AGE_IDENTITY_FILE}" ]] || { echo "Age identity file is not readable" >&2; exit 1; }

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

(cd "$(dirname "${BACKUP_FILE}")" && sha256sum --check "$(basename "${BACKUP_FILE}").sha256")
age --decrypt --identity "${BACKUP_AGE_IDENTITY_FILE}" --output "${work_dir}/backup.tar.gz" "${BACKUP_FILE}"
tar -C "${work_dir}" -xzf "${work_dir}/backup.tar.gz"
[[ "$(sqlite3 "${work_dir}/one-api.db" 'PRAGMA integrity_check;')" == "ok" ]] || {
  echo "Restored SQLite integrity check failed" >&2
  exit 1
}

echo "Restore verification passed for encrypted backup."
