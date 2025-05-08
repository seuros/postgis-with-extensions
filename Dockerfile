##############################################################################
# Postgres 17 + PostGIS 3 + pgvector + Apache AGE
# – based on the official Postgres image so the cluster is created at runtime.
##############################################################################

ARG PG_MAJOR=17
FROM postgres:${PG_MAJOR}-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Add PGDG repo key (needed because we’re installing extra PG packages)
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
# ---------------------------------------------------------------------------
RUN apt-get install -y --no-install-recommends \
    postgresql-${PG_MAJOR}-postgis-3 \
    postgresql-${PG_MAJOR}-postgis-3-scripts \
    postgresql-${PG_MAJOR}-pgrouting \
    postgresql-${PG_MAJOR}-pgvector \
    postgresql-${PG_MAJOR}-age \
    net-tools libkrb5-dev krb5-user libpam-krb5 \
    && rm -rf /var/lib/apt/lists/*


