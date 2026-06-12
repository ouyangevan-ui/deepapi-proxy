# Restore Drill Runbook

Repository tests do not prove live backup readiness. A local tarball is NO-GO
for production. Production needs an offsite encrypted backup, checksum evidence,
and a successful restore drill on a disposable directory or alternate host.

## Inputs

- Root-owned `/etc/deepapi/backup.env` based on `ops/backup.env.example`.
- Root-owned age recipients file referenced by `AGE_RECIPIENTS_FILE`.
- Private age identity available only to the restore operator, never in Git,
  chat, screenshots, shell history, or logs.
- Offsite encrypted backup file and matching `.sha256` file.

## Drill

1. Confirm the artifact is off host or on the approved offsite mount:
   `findmnt -T "$BACKUP_OFFSITE_DIR"` and non-sensitive provider/storage proof.
2. Verify the checksum from the backup directory:
   `sha256sum --check "$(basename "$BACKUP_FILE").sha256"`.
3. Decrypt and validate SQLite in a temporary directory:
   `BACKUP_AGE_IDENTITY_FILE=/secure/path/identity.txt deepapi-restore-verify "$BACKUP_FILE"`.
4. On a disposable host or isolated one-api data directory, restore the verified
   `one-api.db` and start one-api without public traffic.
5. Verify admin login, user/group/channel/model inventory, API key presence,
   quota/balance state, and usage logs with screenshots or notes that redact
   all credentials and customer request data.
6. Run `verify-model-contract.sh` and the rate/concurrency checks from
   `PRODUCTION-READINESS.md`.
7. Record restore time, reviewer, backup SHA-256, offsite evidence reference,
   and restore evidence reference in the private operations log.

## Go/No-Go

GO only when checksum verification, age decryption, SQLite integrity, and
one-api recoverability all pass on an isolated target. Any missing offsite proof,
missing encryption, failed integrity check, untested one-api recovery, or
unredacted evidence is NO-GO.
