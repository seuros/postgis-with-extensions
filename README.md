#### PostgreSQL 18 with PostGIS, pgvector, pgRouting, pg_cron and TimescaleDB

Multi-arch (`linux/amd64`, `linux/arm64`) images built on the official
`postgres` image, so every [upstream environment variable and init hook](https://hub.docker.com/_/postgres)
works unchanged. The `latest` tag currently corresponds to PostgreSQL `18.6`.

| Flavour | Base                       | Tags                                  |
|---------|----------------------------|---------------------------------------|
| Debian  | `postgres:18.6-trixie`     | `:18.6`, `:18`, `:latest`             |
| Alpine  | `postgres:18.6-alpine3.24` | `:18.6-alpine`, `:18-alpine`, `:alpine` |

Images are rebuilt weekly to pick up base-image and package security updates.

## Usage

```bash
# Moving latest (always the newest build)
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:latest

# Track major 18 (gets 18.x updates)
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:18

# Pin exact version for reproducible builds
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:18.6
```

Compose example (uses the published image tags):

```bash
# default: :18
IMAGE_TAG=18 docker compose up -d

# latest
IMAGE_TAG=latest docker compose up -d

# exact patch
IMAGE_TAG=18.6 docker compose up -d

# Alpine variant
IMAGE_TAG=18 IMAGE_FLAVOR=-alpine docker compose up -d
```

## Available extensions

| Extension | Debian (PGDG / Timescale apt) | Alpine (built from source) |
|-----------|-------------------------------|----------------------------|
| [postgis](https://github.com/postgis/postgis) (+ raster, sfcgal, topology, tiger geocoder) | 3.6.x | 3.6.4 |
| [pgvector](https://github.com/pgvector/pgvector) | 0.8.x | 0.8.7 |
| [pgrouting](https://github.com/pgRouting/pgrouting) | 4.0.x | 4.0.2 |
| [pg_cron](https://github.com/citusdata/pg_cron) | 1.6.x | 1.6.8 |
| [timescaledb](https://github.com/timescale/timescaledb) (incl. TSL features: columnstore, continuous aggregates) | 2.30.x | 2.30.2 |

Debian packages track the latest release in their apt repos at build time;
Alpine versions are pinned via build args in `Dockerfile.alpine`
(`POSTGIS_VERSION`, `PGVECTOR_VERSION`, `PGROUTING_VERSION`, `PGCRON_VERSION`,
`TIMESCALEDB_VERSION`). Pass `--build-arg WITH_PGROUTING=0` to skip the
pgRouting build on Alpine.

## Enabling extensions

Once your PostgreSQL container is running, connect to it and enable the extensions you need:

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;
CREATE EXTENSION vector;
CREATE EXTENSION pgrouting;
CREATE EXTENSION timescaledb;
CREATE EXTENSION pg_cron; -- in the database named by cron.database_name (default: postgres)
```

`timescaledb` and `pg_cron` are preloaded via `shared_preload_libraries` in the
image's default command. If you override the command, keep
`-c shared_preload_libraries=timescaledb,pg_cron` (or set it in your
`postgresql.conf`).

The containers run as the `postgres` user and default `PGUSER=postgres` for
client tools.

## Building and testing locally

```bash
make build          # Debian -> :18.6, :18, :latest
make build-alpine   # Alpine -> :18.6-alpine, :18-alpine, :alpine

make test           # build + run tests/create_extensions.sql against the Debian image
make test-alpine    # same for Alpine
make test-all

make push push-alpine   # multi-arch buildx build + push (CI normally does this)
```

The PostgreSQL version comes from the `FROM` line of `Dockerfile`; both
Dockerfiles must agree (`make check-versions`, also enforced in CI).
Dependabot bumps the base image and GitHub Actions weekly.

CI (`.github/workflows/docker-images.yml`) builds each flavour natively on
amd64 and arm64 runners, runs the SQL suite against every image, and only then
pushes and assembles the multi-arch tags. Pull requests build and test without
publishing.

## Environment variables

This image accepts all the same environment variables as the official PostgreSQL image. See the [PostgreSQL Docker documentation](https://hub.docker.com/_/postgres) for more information.
