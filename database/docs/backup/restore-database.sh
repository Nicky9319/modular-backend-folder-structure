#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/database.dump" >&2
  echo >&2
  echo "Set PGHOST, PGPORT, PGDATABASE, PGUSER, and PGPASSWORD for the target PostgreSQL instance." >&2
  exit 1
fi

DUMP_PATH="$(cd -- "$(dirname -- "$1")" && pwd)/$(basename -- "$1")"

if [[ ! -f "$DUMP_PATH" ]]; then
  echo "Dump file not found: $DUMP_PATH" >&2
  exit 1
fi

: "${PGHOST:=localhost}"
: "${PGPORT:=5432}"
: "${PGDATABASE:=trainme}"
: "${PGUSER:=trainme}"
: "${PGPASSWORD:=trainme}"
export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD

echo "Restoring $DUMP_PATH into $PGUSER@$PGHOST:$PGPORT/$PGDATABASE"
echo "Existing objects with matching names will be replaced."

pg_restore \
  --dbname="$PGDATABASE" \
  --format=custom \
  --clean \
  --if-exists \
  --no-owner \
  --exit-on-error \
  "$DUMP_PATH"

echo "Database restore completed."
