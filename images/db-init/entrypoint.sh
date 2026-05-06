#!/usr/bin/env bash
#
# db-init entrypoint.
# Runs a multi-statement SQL file (mounted from a ConfigMap at
# /etc/db-init/db-init.sql) against a managed datastore from inside the
# customer's Kubernetes cluster. Used for database+user provisioning and
# teardown — the actual SQL is rendered by the provisioner before the Job
# is applied.
#
# Required env:
#   ENGINE       mysql | postgres
#   DB_HOST      datastore endpoint (private IP / DNS reachable from this pod)
#   DB_PORT      datastore port
#   DB_USER      admin username (from connection Secret, GoFr convention)
#   DB_PASSWORD  admin password (from connection Secret, GoFr convention)
#
# Optional env:
#   OPERATION   create | drop | provision | teardown — informational only,
#               echoed in logs. The SQL file decides what actually runs.
#   SQL_FILE    path to the SQL file (default /etc/db-init/db-init.sql)

set -eu
set -o pipefail

require() {
  local name=$1
  if [ -z "${!name:-}" ]; then
    echo "db-init: required env var $name is empty" >&2
    exit 2
  fi
}

require ENGINE
require DB_HOST
require DB_PORT
require DB_USER
require DB_PASSWORD

SQL_FILE="${SQL_FILE:-/etc/db-init/db-init.sql}"
OPERATION="${OPERATION:-run}"

if [ ! -f "$SQL_FILE" ]; then
  echo "db-init: SQL file not found at $SQL_FILE" >&2
  exit 2
fi

echo "db-init: running $OPERATION on $ENGINE (sql=$SQL_FILE)"

case "$ENGINE" in
  mysql)
    # Pipe SQL via stdin (NOT `-e "source ..."`) — `source` is a client
    # builtin that does not abort on error, so a bad CREATE/GRANT would
    # exit 0 and the job would report success on a half-applied script.
    MYSQL_PWD="$DB_PASSWORD" mysql \
      --protocol=TCP \
      -h "$DB_HOST" \
      -P "$DB_PORT" \
      -u "$DB_USER" \
      --connect-timeout=15 \
      < "$SQL_FILE"
    ;;
  postgres)
    PGPASSWORD="$DB_PASSWORD" psql \
      --host="$DB_HOST" \
      --port="$DB_PORT" \
      --username="$DB_USER" \
      --dbname=postgres \
      --no-password \
      --set=ON_ERROR_STOP=1 \
      -f "$SQL_FILE"
    ;;
  *)
    echo "db-init: unsupported ENGINE '$ENGINE'" >&2
    exit 2
    ;;
esac

echo "db-init: $OPERATION on $ENGINE succeeded"
