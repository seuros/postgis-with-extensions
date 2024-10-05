#### PostgreSQL with postgis, pgvector and age

The `latest` tag currently corresponds to `16-3.4`.

## Usage

In order to run a basic container capable of serving a Postgres database with all extensions below available:

```bash
docker run -e POSTGRES_PASSWORD=mysecretpassword -d gr
```

## Available extensions

- [postgis](https://github.com/postgis/postgis)
- [pgvector](https://github.com/pgvector/pgvector)
- [age](https://github.com/apache/age)
