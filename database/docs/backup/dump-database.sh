#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="${1:-$SCRIPT_DIR/exports}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_NAME="trainme-${TIMESTAMP}.dump"
ARCHIVE_PATH="$OUTPUT_DIR/$ARCHIVE_NAME"
CONTAINER_TMP_PATH="/tmp/$ARCHIVE_NAME"

mkdir -p "$OUTPUT_DIR"

cleanup() {
  docker compose -f "$REPO_ROOT/docker-compose.yml" exec -T postgres \
    rm -f "$CONTAINER_TMP_PATH" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Creating PostgreSQL dump: $ARCHIVE_PATH"
docker compose -f "$REPO_ROOT/docker-compose.yml" exec -T postgres \
  pg_dump -U "${POSTGRES_USER:-trainme}" \
  -d "${POSTGRES_DB:-trainme}" \
  --format=custom \
  --file="$CONTAINER_TMP_PATH"

docker compose -f "$REPO_ROOT/docker-compose.yml" cp \
  "postgres:$CONTAINER_TMP_PATH" "$ARCHIVE_PATH"

sha256sum "$ARCHIVE_PATH" > "$ARCHIVE_PATH.sha256"

echo "Dump created: $ARCHIVE_PATH"
echo "Checksum created: $ARCHIVE_PATH.sha256"
