#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   ./scripts/restore.sh backups/dba_starter_YYYYMMDD_HHMMSS.dump
#
# Nota: Restaura SOBRE la BD existente.
# Usa --clean para borrar objetos antes de recrearlos.

CONTAINER="pg_dba_starter_db"
DB="dba_starter"
USER="postgres"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path_to_dump_file>"
  exit 1
fi

DUMP_FILE="$1"

if [ ! -f "$DUMP_FILE" ]; then
  echo "[restore] Dump file not found: $DUMP_FILE"
  exit 1
fi

echo "[restore] Restoring from: ${DUMP_FILE}"

# Pasa el archivo local al pg_restore dentro del contenedor por stdin
cat "$DUMP_FILE" | docker exec -i "$CONTAINER" pg_restore -U "$USER" -d "$DB" --clean --if-exists

echo "[restore] Done."
