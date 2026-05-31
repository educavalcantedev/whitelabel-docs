#!/usr/bin/env bash
# Zera whitelabel_notify após squash Flyway (só V1 — notifications).
set -euo pipefail

DB_NAME="${NOTIFY_DB_NAME:-whitelabel_notify}"
PGUSER="${DB_USERNAME:-postgres}"
PGPASSWORD="${DB_PASSWORD:-postgres}"
PGHOST="${DB_HOST:-localhost}"
PGPORT="${DB_PORT:-5432}"

export PGPASSWORD

run_sql() {
  if command -v docker >/dev/null 2>&1; then
    local container
    container="$(docker ps --format '{{.Names}}' | grep -E 'postgres|whitelabel.*postgres' | head -1 || true)"
    if [[ -n "$container" ]]; then
      docker exec -i "$container" psql -U "$PGUSER" -d "$DB_NAME" -v ON_ERROR_STOP=1 "$@"
      return 0
    fi
  fi
  psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB_NAME" -v ON_ERROR_STOP=1 "$@"
}

echo "Resetando banco ${DB_NAME} (@${PGHOST}:${PGPORT})..."

run_sql <<'SQL'
DROP TABLE IF EXISTS device_login_challenges CASCADE;
DROP TABLE IF EXISTS user_devices CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS flyway_schema_history CASCADE;
SQL

echo "Concluído. Na próxima subida do notify-service o Flyway aplicará apenas V1."
