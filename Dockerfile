##############################################################################
# Postgres 18 + PostGIS 3 + pgvector + pgrouting + pg_cron + timescaledb
# – based on the official Postgres image so the cluster is created at runtime.
# Note: Apache AGE not compatible with PG 18 yet
##############################################################################

ARG PG_MAJOR=18
ARG PG_VERSION=18.6
FROM postgres:${PG_VERSION}-bookworm

# Default libpq user so client tools (psql, pg_isready) don't fall back to
# the runtime OS user (root in many CI environments), which avoids noisy
# "role \"root\" does not exist" connection attempts. Users can override.
ENV DEBIAN_FRONTEND=noninteractive \
    PGUSER=postgres

# ---------------------------------------------------------------------------
# Add PGDG + TimescaleDB repo keys (needed for the extra PG packages)
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl gnupg2 lsb-release ca-certificates \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor \
    | tee /usr/share/keyrings/postgresql.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
    http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list \
    && curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor \
    | tee /usr/share/keyrings/timescaledb.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/timescaledb.gpg] \
    https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/timescaledb.list \
    # packagecloud's by-hash index is flaky under buildkit; retry until the
    # timescaledb package metadata is actually visible before moving on.
    && for i in $(seq 1 5); do \
         apt-get -o Acquire::Retries=3 update \
         && apt-cache show timescaledb-2-postgresql-${PG_MAJOR} >/dev/null 2>&1 \
         && break; \
         echo "timescaledb index not ready (attempt $i), retrying..."; sleep 3; \
       done \
    && apt-cache show timescaledb-2-postgresql-${PG_MAJOR} >/dev/null 2>&1

# ---------------------------------------------------------------------------
# Extensions + optional Kerberos libraries
# Note: Apache AGE not yet compatible with PG 18
# ---------------------------------------------------------------------------
RUN apt-get install -y --no-install-recommends \
    postgresql-${PG_MAJOR}-postgis-3 \
    postgresql-${PG_MAJOR}-postgis-3-scripts \
    postgresql-${PG_MAJOR}-pgrouting \
    postgresql-${PG_MAJOR}-pgvector \
    postgresql-${PG_MAJOR}-cron \
    timescaledb-2-postgresql-${PG_MAJOR} \
    net-tools libkrb5-dev krb5-user libpam-krb5 \
    && rm -rf /var/lib/apt/lists/*

USER postgres

# timescaledb must be listed in shared_preload_libraries; pg_cron alongside it.
CMD ["postgres", "-c", "shared_preload_libraries=timescaledb,pg_cron"]
