# syntax=docker/dockerfile:1
##############################################################################
# PostgreSQL 18 + PostGIS 3 + pgvector + pgRouting + pg_cron
#   + H3 + pg_partman + pgTAP + HypoPG + pg_repack
# Debian (trixie) flavour, based on the official postgres image so the cluster
# is created at runtime by the upstream entrypoint.
#
# The FROM line is the single source of truth for the published tags
# (CI and the Makefile parse it); Dependabot bumps it.
##############################################################################
FROM postgres:18.6-trixie

# Build-time only: krb5-config asks for a default realm otherwise.
ARG DEBIAN_FRONTEND=noninteractive

# Pinned to the versions Amazon RDS for PostgreSQL 18 ships, so nothing here
# depends on a feature RDS doesn't have yet. Keep in sync with
# Dockerfile.alpine. apt fails the build once PGDG drops a pinned version.
ARG H3_VERSION=4.2.3
ARG PGPARTMAN_VERSION=5.4.3
ARG PGTAP_VERSION=1.3.4
ARG HYPOPG_VERSION=1.4.2
ARG PGREPACK_VERSION=1.5.3

# Default libpq user so client tools (psql, pg_isready) don't fall back to
# the runtime OS user (root in many CI environments), which avoids noisy
# "role \"root\" does not exist" connection attempts. Users can override.
ENV PGUSER=postgres

# Everything comes from PGDG; the base image already ships its apt source.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-postgis-3" \
      "postgresql-${PG_MAJOR}-postgis-3-scripts" \
      "postgresql-${PG_MAJOR}-pgrouting" \
      "postgresql-${PG_MAJOR}-pgvector" \
      "postgresql-${PG_MAJOR}-cron" \
      "postgresql-${PG_MAJOR}-h3=${H3_VERSION}-*" \
      "postgresql-${PG_MAJOR}-partman=${PGPARTMAN_VERSION}-*" \
      "postgresql-${PG_MAJOR}-pgtap=${PGTAP_VERSION}-*" \
      "postgresql-${PG_MAJOR}-hypopg=${HYPOPG_VERSION}-*" \
      "postgresql-${PG_MAJOR}-repack=${PGREPACK_VERSION}-*" \
      ca-certificates \
      # Kerberos client + PAM module for GSSAPI/PAM auth setups
      krb5-user libpam-krb5; \
    rm -rf /var/lib/apt/lists/*

USER postgres

# pg_cron must be listed in shared_preload_libraries.
CMD ["postgres", "-c", "shared_preload_libraries=pg_cron"]
