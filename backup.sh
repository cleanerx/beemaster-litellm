#!/bin/bash
# Beemaster LiteLLM — Backup Script
# Führt pg_dump auf der LiteLLM PostgreSQL DB aus.
# Cron: 0 2 * * * /home/jens/dev/git/beemaster-litellm/backup.sh

set -e

BACKUP_DIR="/home/jens/dev/git/beemaster-litellm/backups"
TIMESTAMP=$(date +%F)
BACKUP_FILE="${BACKUP_DIR}/litellm_${TIMESTAMP}.sql"
RETENTION_DAYS=7

mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Starting LiteLLM database backup..."

docker exec litellm-db-1 pg_dump -U litellm litellm > "${BACKUP_FILE}"

echo "[$(date)] Backup saved to ${BACKUP_FILE}"
echo "[$(date)] Size: $(du -h "${BACKUP_FILE}" | cut -f1)"

# Rotation: Behalte nur die letzten N Tage
find "${BACKUP_DIR}" -name "litellm_*.sql" -mtime +${RETENTION_DAYS} -delete
echo "[$(date)] Cleaned up backups older than ${RETENTION_DAYS} days"

echo "[$(date)] Backup complete."
