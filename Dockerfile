ARG PG_MAJOR=16
FROM postgres:${PG_MAJOR}

# Install PostGIS and pgvector from official packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-${PG_MAJOR}-postgis-3 \
        postgresql-${PG_MAJOR}-postgis-3-scripts \
        postgresql-${PG_MAJOR}-pgvector \
    && rm -rf /var/lib/apt/lists/*

# Install build dependencies for AGE
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/*

# Build and install AGE
WORKDIR /tmp/age
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/apache/age/releases/latest)) \
    && curl --fail -L "https://github.com/apache/age/archive/PG16%2F${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/age

# Clean up build dependencies
RUN apt-get update \
    && apt-get remove -y \
        build-essential \
        git \
        postgresql-server-dev-${PG_MAJOR} \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
