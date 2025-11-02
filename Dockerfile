##############################################################################
# Postgres 18 + PostGIS 3 + pgvector + Apache AGE + pgrouting
# – based on the official Postgres image so the cluster is created at runtime.
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
# ---------------------------------------------------------------------------
RUN apt-get install -y --no-install-recommends \
    postgresql-${PG_MAJOR}-postgis-3 \
    postgresql-${PG_MAJOR}-postgis-3-scripts \
    postgresql-${PG_MAJOR}-pgrouting \
    postgresql-${PG_MAJOR}-pgvector \
    net-tools libkrb5-dev krb5-user libpam-krb5 \
    # Build dependencies for AGE (source build)
    build-essential git \
    postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Build Apache AGE from source (package not available for PG 18 yet)
# ---------------------------------------------------------------------------
ARG AGE_REF=PG18
RUN set -eux; \
    mkdir -p /tmp/build && cd /tmp/build && \
    git clone --depth 1 --branch ${AGE_REF} https://github.com/apache/age.git && \
    cd age && make -j "$(nproc)" PG_CONFIG=/usr/bin/pg_config && \
    make install && \
    test -f "$(pg_config --sharedir)/extension/age.control" && \
    test -f "$(pg_config --pkglibdir)/age.so" && \
    cd / && rm -rf /tmp/build && \
    # Clean up build dependencies
    apt-get purge -y build-essential git postgresql-server-dev-${PG_MAJOR} && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

