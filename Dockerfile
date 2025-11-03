##############################################################################
# Postgres 18 + PostGIS 3 + pgvector + pgrouting
# – based on the official Postgres image so the cluster is created at runtime.
# Note: Apache AGE not compatible with PG 18 yet
##############################################################################

ARG PG_MAJOR=18
ARG PG_VERSION=18.0
FROM postgres:${PG_VERSION}-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Add PGDG repo key (needed because we're installing extra PG packages)
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl gnupg2 lsb-release \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor \
    | tee /usr/share/keyrings/postgresql.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
    http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update

# ---------------------------------------------------------------------------
# Extensions + optional Kerberos libraries
# Note: Apache AGE not yet compatible with PG 18
# ---------------------------------------------------------------------------
RUN apt-get install -y --no-install-recommends \
    postgresql-${PG_MAJOR}-postgis-3 \
    postgresql-${PG_MAJOR}-postgis-3-scripts \
    postgresql-${PG_MAJOR}-pgrouting \
    postgresql-${PG_MAJOR}-pgvector \
    net-tools libkrb5-dev krb5-user libpam-krb5 \
    && rm -rf /var/lib/apt/lists/*

