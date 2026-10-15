# syntax=docker/dockerfile:1
##############################################################################
# PostgreSQL 18 + PostGIS 3 + pgvector + pgRouting + pg_cron + TimescaleDB
# Debian (trixie) flavour, based on the official postgres image so the cluster
# is created at runtime by the upstream entrypoint.
#
# The FROM line is the single source of truth for the published tags
# (CI and the Makefile parse it); Dependabot bumps it.
##############################################################################
FROM postgres:18.6-trixie

# Build-time only: krb5-config asks for a default realm otherwise.
ARG DEBIAN_FRONTEND=noninteractive

# Default libpq user so client tools (psql, pg_isready) don't fall back to
# the runtime OS user (root in many CI environments), which avoids noisy
# "role \"root\" does not exist" connection attempts. Users can override.
ENV PGUSER=postgres

# The base image already ships the PGDG apt source. TimescaleDB comes from
# Timescale's own repo because PGDG's build is Apache-only (no compression,
# continuous aggregates, ...).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey \
      -o /usr/share/keyrings/timescaledb.asc; \
    . /etc/os-release; \
    echo "deb [signed-by=/usr/share/keyrings/timescaledb.asc] https://packagecloud.io/timescale/timescaledb/debian/ ${VERSION_CODENAME} main" \
      > /etc/apt/sources.list.d/timescaledb.list; \
    # packagecloud's by-hash index is flaky under BuildKit; retry until the
    # timescaledb package metadata is actually visible before moving on.
    for i in 1 2 3 4 5; do \
      apt-get -o Acquire::Retries=3 update \
        && apt-cache show "timescaledb-2-postgresql-${PG_MAJOR}" >/dev/null 2>&1 \
        && break; \
      echo "timescaledb index not ready (attempt $i), retrying..."; sleep 3; \
    done; \
    apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-postgis-3" \
      "postgresql-${PG_MAJOR}-postgis-3-scripts" \
      "postgresql-${PG_MAJOR}-pgrouting" \
      "postgresql-${PG_MAJOR}-pgvector" \
      "postgresql-${PG_MAJOR}-cron" \
      "timescaledb-2-postgresql-${PG_MAJOR}" \
      # Kerberos client + PAM module for GSSAPI/PAM auth setups
      krb5-user libpam-krb5; \
    rm -rf /var/lib/apt/lists/*

USER postgres

# timescaledb must be listed in shared_preload_libraries; pg_cron alongside it.
CMD ["postgres", "-c", "shared_preload_libraries=timescaledb,pg_cron"]
