#### PostgreSQL with postgis, pgvector and age

The `latest` tag currently corresponds to `17.6`.

## Usage

Run a basic container with extensions available. Choose a tag strategy:

```bash
# Moving latest (always the newest build)
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:latest

# Track major 17 (gets 17.x updates)
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:17

# Pin exact version for reproducible builds
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:17.6
```

Compose example (uses image tags instead of local build):

```bash
# default: :17
IMAGE_TAG=17 docker compose up -d

# latest
IMAGE_TAG=latest docker compose up -d

# exact patch
IMAGE_TAG=17.6 docker compose up -d

# Alpine variant
IMAGE_TAG=17 IMAGE_FLAVOR=-alpine docker compose up -d
```

## Available extensions

- [postgis](https://github.com/postgis/postgis) - Spatial and geographic objects for PostgreSQL
- [pgvector](https://github.com/pgvector/pgvector) - Open-source vector similarity search for PostgreSQL
- [age](https://github.com/apache/age) - Graph database extension for PostgreSQL
- [pgrouting](https://github.com/pgRouting/pgrouting) - Provides geospatial routing functionality

## Alpine variant

- Tags: `:alpine`, `:17-alpine`, `:17.6-alpine`.
- Includes: PostGIS (built from source), pgvector, AGE, pgRouting (built from source).
- To disable pgRouting build (faster/smaller), pass `--build-arg WITH_PGROUTING=0`.

Build/push locally with the provided Makefile:

```bash
# Debian-based
make build         # -> :17.6, :17, :latest

# Alpine-based
make build-alpine  # -> :17.6-alpine, :17-alpine, :alpine

# Push
make push push-alpine
```

## Enabling extensions

Once your PostgreSQL container is running, connect to it and enable the extensions you need:

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION pgvector;
CREATE EXTENSION age;
CREATE EXTENSION pgrouting;
```

## Environment variables

This image accepts all the same environment variables as the official PostgreSQL image. See the [PostgreSQL Docker documentation](https://hub.docker.com/_/postgres) for more information.yes
