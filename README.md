#### PostgreSQL 18 with postgis, pgvector, pgrouting, pg_cron and timescaledb

The `latest` tag currently corresponds to `18.4`.

## Usage

Run a basic container with extensions available. Choose a tag strategy:

```bash
# Moving latest (always the newest build)
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:latest

# Track major 18 (gets 18.x updates)
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:18

# Pin exact version for reproducible builds
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:18.4
```

Compose example (uses image tags instead of local build):

```bash
# default: :18
IMAGE_TAG=18 docker compose up -d

# latest
IMAGE_TAG=latest docker compose up -d

# exact patch
IMAGE_TAG=18.4 docker compose up -d

# Alpine variant
IMAGE_TAG=18 IMAGE_FLAVOR=-alpine docker compose up -d
```

## Available extensions

- [postgis](https://github.com/postgis/postgis) - Spatial and geographic objects for PostgreSQL
- [pgvector](https://github.com/pgvector/pgvector) - Open-source vector similarity search for PostgreSQL
- [pgrouting](https://github.com/pgRouting/pgrouting) - Provides geospatial routing functionality
- [pg_cron](https://github.com/citusdata/pg_cron) - Job scheduling for PostgreSQL
- [timescaledb](https://github.com/timescale/timescaledb) - Time-series and real-time analytics for PostgreSQL

**Note:** Apache AGE is not yet compatible with PostgreSQL 18.

## Alpine variant

- Tags: `:alpine`, `:18-alpine`, `:18.4-alpine`.
- Includes: PostGIS (built from source), pgvector, pgRouting (built from source), pg_cron, timescaledb (built from source).
- To disable pgRouting build (faster/smaller), pass `--build-arg WITH_PGROUTING=0`.

Build/push locally with the provided Makefile:

```bash
# Debian-based
make build         # -> :18.4, :18, :latest

# Alpine-based
make build-alpine  # -> :18.4-alpine, :18-alpine, :alpine

# Push
make push push-alpine
```

## Enabling extensions

Once your PostgreSQL container is running, connect to it and enable the extensions you need:

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION vector;
CREATE EXTENSION pgrouting;
CREATE EXTENSION pg_cron;
CREATE EXTENSION timescaledb;
```

`timescaledb` and `pg_cron` are preloaded in the image via `shared_preload_libraries`.

## Environment variables

This image accepts all the same environment variables as the official PostgreSQL image. See the [PostgreSQL Docker documentation](https://hub.docker.com/_/postgres) for more information.yes
