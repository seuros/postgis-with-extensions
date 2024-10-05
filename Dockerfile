# Start from Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL repository and key
RUN apt-get update && apt-get install -y curl gnupg2 lsb-release \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install PostgreSQL 16, PostGIS, pgvector, and build dependencies
RUN apt-get update && apt-get install -y \
    postgresql-16 \
    postgresql-server-dev-16 \
    postgresql-16-postgis-3 \
    postgresql-16-postgis-3-scripts \
    postgresql-16-pgvector \
    build-essential \
    git \
    curl \
    cmake \
    libssl-dev \
    liblz4-dev \
    zlib1g-dev \
    flex \
    bison \
    libreadline-dev \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PG_MAJOR=16
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin
ENV POSTGRES_PORT=5432

# Build and install Apache AGE
WORKDIR /tmp/age
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/apache/age/releases/latest)) \
    && curl --fail -L "https://github.com/apache/age/archive/PG16%2F${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/age

# Modify PostgreSQL configuration to listen on all IP addresses and set port
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '0.0.0.0'/" /etc/postgresql/$PG_MAJOR/main/postgresql.conf \
    && sed -i "s/#port = 5432/port = ${POSTGRES_PORT}/" /etc/postgresql/$PG_MAJOR/main/postgresql.conf \
    && echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/$PG_MAJOR/main/pg_hba.conf

# Create a directory for custom initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Add a custom entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /app/

# Switch to the postgres user
USER postgres

EXPOSE ${POSTGRES_PORT}

# Start PostgreSQL using the modified configuration
CMD ["docker-entrypoint.sh"]
