#!/bin/bash
set -e

# Start PostgreSQL service
pg_ctlcluster $PG_MAJOR main start

# Create a default database if it doesn't exist
if [ -z "$(psql -Atc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB:-postgres}'")" ]; then
    createdb -E UTF8 ${POSTGRES_DB:-postgres}
fi

# Run any custom initialization scripts
for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
        *.sql)    echo "$0: running $f"; psql -d ${POSTGRES_DB:-postgres} -f "$f"; echo ;;
        *.sql.gz) echo "$0: running $f"; gunzip -c "$f" | psql -d ${POSTGRES_DB:-postgres}; echo ;;
        *)        echo "$0: ignoring $f" ;;
    esac
    echo
done

# Keep the container running
tail -f /dev/null
