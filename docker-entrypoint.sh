#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Configuration (all are optional except POSTGRES_PASSWORD when -U = postgres)
# ---------------------------------------------------------------------------
: "${PG_MAJOR:?PG_MAJOR env var must be baked into the image}"
: "${POSTGRES_USER:=postgres}"                     # default superuser
: "${POSTGRES_DB:=$POSTGRES_USER}"                 # default database
: "${POSTGRES_PASSWORD:=$POSTGRES_USER}"           # default password
: "${POSTGRES_INITDB_ARGS:=}"                      # extra flags for initdb
: "${POSTGRES_HOST_AUTH_METHOD:=md5}"              # trust / md5 / scram‑sha‑256

PGDATA="/var/lib/postgresql/${PG_MAJOR}/main"
CONF="/etc/postgresql/${PG_MAJOR}/main/postgresql.conf"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo "[entrypoint] $*"; }

psql_nopass() { psql --username "$POSTGRES_USER" --no-password "$@"; }

# ---------------------------------------------------------------------------
# Init (first run only)
# ---------------------------------------------------------------------------
first_run() { [[ ! -s "${PGDATA}/PG_VERSION" ]]; }

if first_run; then
  log "Empty data dir – initialising cluster 🔧"

  initdb -D "$PGDATA" $POSTGRES_INITDB_ARGS

  # Start in the background just for provisioning --------------------------
  pg_ctl -D "$PGDATA" -o "-c listen_addresses='localhost'" -w start

  # postgres user -----------------------------------------------------------
  if [[ "$POSTGRES_USER" = "postgres" ]]; then
    [[ -n "$POSTGRES_PASSWORD" ]] || { log "ERROR: POSTGRES_PASSWORD not set"; exit 1; }
    psql -v ON_ERROR_STOP=1 <<-SQL
      ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';
SQL
  else
    psql -v ON_ERROR_STOP=1 <<-SQL
      CREATE USER "${POSTGRES_USER}" WITH PASSWORD '${POSTGRES_PASSWORD:-}';
      ALTER USER "${POSTGRES_USER}" WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN;
SQL
  fi

  # database ---------------------------------------------------------------
  if [[ "$POSTGRES_DB" != "postgres" || "$POSTGRES_USER" != "postgres" ]]; then
    psql -v ON_ERROR_STOP=1 <<-SQL
      CREATE DATABASE "${POSTGRES_DB}" OWNER "${POSTGRES_USER}";
SQL
  fi

  # run any user‑supplied init scripts -------------------------------------
  for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sql)    log "running $f"; psql_nopass -v ON_ERROR_STOP=1 -d "$POSTGRES_DB" -f "$f" ;;
      *.sql.gz) log "running $f"; gunzip -c "$f" | psql_nopass -v ON_ERROR_STOP=1 -d "$POSTGRES_DB" ;;
      *)        log "ignoring $f" ;;
    esac
  done

  pg_ctl -D "$PGDATA" -m fast -w stop
  log "Initialisation complete ✅"
fi

# ---------------------------------------------------------------------------
# Adjust pg_hba.conf every run (user may mount own file)
# ---------------------------------------------------------------------------
HBA="/etc/postgresql/${PG_MAJOR}/main/pg_hba.conf"
if ! grep -q "^host *all *all *0.0.0.0/0 " "$HBA"; then
  echo "host all all 0.0.0.0/0 ${POSTGRES_HOST_AUTH_METHOD}" >>"$HBA"
fi

# ---------------------------------------------------------------------------
# hand off to postgres (PID 1)
# ---------------------------------------------------------------------------
exec postgres -D "$PGDATA" -c config_file="$CONF"
