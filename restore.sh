#!/bin/bash
# Beemaster LiteLLM — Restore Script
# Usage: ./restore.sh litellm_2026-06-28.sql

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-filename>"
    echo "Example: $0 litellm_2026-06-28.sql"
    exit 1
fi

BACKUP_DIR="/home/jens/dev/git/beemaster-litellm/backups"
BACKUP_FILE="${BACKUP_DIR}/$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "[$(date)] Starting restore from ${BACKUP_FILE}..."

echo "[$(date)] Stopping containers..."
docker compose down

echo "[$(date)] Removing old postgres volume..."
docker volume rm beemaster-litellm_postgres_data 2>/dev/null || true

echo "[$(date)] Starting database container..."
docker compose up -d db

echo "[$(date)] Waiting for database to be ready..."
sleep 10

echo "[$(date)] Restoring database..."
cat "${BACKUP_FILE}" | docker exec -i litellm-db-1 psql -U litellm litellm

echo "[$(date)] Starting all containers..."
docker compose up -d

echo "[$(date)] Restore complete."
echo "[$(date)] Verify with: curl https://beemaster.myfritz.net/health"
