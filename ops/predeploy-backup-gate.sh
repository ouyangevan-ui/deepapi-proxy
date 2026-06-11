#!/usr/bin/env bash
set -euo pipefail

PREDEPLOY_BACKUP_EVIDENCE="${PREDEPLOY_BACKUP_EVIDENCE:-/etc/deepapi/predeploy-backup.evidence}"
EVIDENCE_MAX_AGE_SECONDS="${EVIDENCE_MAX_AGE_SECONDS:-2592000}"

fail() {
  echo "Pre-deploy backup gate failed: $*" >&2
  exit 1
}

read_evidence() {
  local key="$1"
  local value
  value="$(awk -F= -v key="${key}" '$1 == key {sub(/^[^=]*=/, ""); print; exit}' "${PREDEPLOY_BACKUP_EVIDENCE}")"
  [[ -n "${value}" ]] || fail "missing evidence field: ${key}"
  printf '%s' "${value}"
}

[[ -f "${PREDEPLOY_BACKUP_EVIDENCE}" && ! -L "${PREDEPLOY_BACKUP_EVIDENCE}" ]] \
  || fail "evidence must be a regular file, not a symlink: ${PREDEPLOY_BACKUP_EVIDENCE}"
[[ "$(stat -c '%u' "${PREDEPLOY_BACKUP_EVIDENCE}")" == "0" ]] || fail "evidence must be owned by root"
[[ "$(stat -c '%a' "${PREDEPLOY_BACKUP_EVIDENCE}")" == "600" ]] || fail "evidence mode must be 0600"

status="$(read_evidence status)"
restore_result="$(read_evidence restore_test_result)"
offsite_result="$(read_evidence offsite_transfer_result)"
restore_verified_at_epoch="$(read_evidence restore_verified_at_epoch)"
offsite_verified_at_epoch="$(read_evidence offsite_verified_at_epoch)"
evidence_expires_at_epoch="$(read_evidence evidence_expires_at_epoch)"
evidence_mount_target="$(read_evidence offsite_mount_target)"
restored_backup_sha256="$(read_evidence restored_backup_sha256)"
restore_evidence_reference="$(read_evidence restore_evidence_reference)"
offsite_evidence_reference="$(read_evidence offsite_evidence_reference)"
reviewed_by="$(read_evidence reviewed_by)"

[[ "${status}" == "PASS" ]] || fail "evidence status is not PASS"
[[ "${restore_result}" == "PASS" ]] || fail "restore test is not PASS"
[[ "${offsite_result}" == "PASS" ]] || fail "offsite transfer test is not PASS"
[[ "${restored_backup_sha256}" =~ ^[0-9a-fA-F]{64}$ ]] || fail "restored backup SHA-256 is invalid"
for value in "${restore_evidence_reference}" "${offsite_evidence_reference}" "${reviewed_by}"; do
  [[ "${value}" != replace-with-* ]] || fail "evidence still contains an example placeholder"
done
for value in "${restore_verified_at_epoch}" "${offsite_verified_at_epoch}" "${evidence_expires_at_epoch}" "${EVIDENCE_MAX_AGE_SECONDS}"; do
  [[ "${value}" =~ ^[0-9]+$ ]] || fail "evidence timestamps and max age must be integer epoch seconds"
done

now="$(date +%s)"
(( restore_verified_at_epoch <= now )) || fail "restore evidence is dated in the future"
(( offsite_verified_at_epoch <= now )) || fail "offsite evidence is dated in the future"
(( evidence_expires_at_epoch >= now )) || fail "evidence is expired"
(( now - restore_verified_at_epoch <= EVIDENCE_MAX_AGE_SECONDS )) || fail "restore evidence is too old"
(( now - offsite_verified_at_epoch <= EVIDENCE_MAX_AGE_SECONDS )) || fail "offsite evidence is too old"

backup_file="$(/usr/local/sbin/deepapi-backup-job)"
[[ "${backup_file}" == /* && -f "${backup_file}" ]] || fail "fresh encrypted backup artifact was not created"
[[ "${backup_file}" == *.age ]] || fail "fresh backup artifact is not encrypted"
[[ -f "${backup_file}.sha256" ]] || fail "fresh backup checksum is missing"
(cd "$(dirname "${backup_file}")" && sha256sum --check "$(basename "${backup_file}").sha256") >/dev/null \
  || fail "fresh encrypted backup checksum failed"

actual_mount_target="$(findmnt -n -o TARGET -T "${backup_file}")"
[[ -n "${actual_mount_target}" && "${actual_mount_target}" != "/" ]] || fail "fresh backup is not on a separate mount"
[[ "${actual_mount_target}" == "${evidence_mount_target}" ]] \
  || fail "fresh backup mount does not match the manually verified offsite target"

echo "Pre-deploy backup gate passed with fresh encrypted artifact and current manual recovery evidence."
