#### PostgreSQL with postgis, pgvector and age

The `latest` tag currently corresponds to `17-4`.

## Usage

In order to run a basic container capable of serving a Postgres database with all extensions below available:

```bash
docker run -e POSTGRES_PASSWORD=mysecretpassword -d ghcr.io/seuros/postgis-with-extensions:17-4
```

## Available extensions

- [postgis](https://github.com/postgis/postgis) - Spatial and geographic objects for PostgreSQL
- [pgvector](https://github.com/pgvector/pgvector) - Open-source vector similarity search for PostgreSQL
- [age](https://github.com/apache/age) - Graph database extension for PostgreSQL
- [pgrouting](https://github.com/pgRouting/pgrouting) - Provides geospatial routing functionality

## Enabling extensions

Once your PostgreSQL container is running, connect to it and enable the extensions you need:

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION pgvector;
CREATE EXTENSION age;
CREATE EXTENSION pgrouting;
```

## Environment variables

This image accepts all the same environment variables as the official PostgreSQL image. See the [PostgreSQL Docker documentation](https://hub.docker.com/_/postgres) for more information.
