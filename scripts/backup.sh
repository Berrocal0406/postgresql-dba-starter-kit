#!/usr/bin/env bash
set -euo pipefail

# === Config ===
CONTAINER="pg_dba_starter_db"
DB="dba_starter"
USER="postgres"

# === Output file ===
mkdir -p backups
TS="$(date +%Y%m%d_%H%M%S)"
OUT="backups/${DB}_${TS}.dump"

echo "[backup] Creating backup: ${OUT}"

# Ejecuta pg_dump dentro del contenedor y lo manda a un archivo local
docker exec -i "$CONTAINER" pg_dump -U "$USER" -d "$DB" -F c > "$OUT"

echo "[backup] Done."
echo "[backup] File: ${OUT}"
