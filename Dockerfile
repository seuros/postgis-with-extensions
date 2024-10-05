# Stage 1: Build Apache AGE and other dependencies
FROM debian:bookworm-slim AS builder

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary build tools and PostgreSQL repository
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    build-essential \
    git \
    cmake \
    libssl-dev \
    liblz4-dev \
    zlib1g-dev \
    flex \
    bison \
    libreadline-dev \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get install -y \
    postgresql-server-dev-16 \
    postgresql-16 \
    && rm -rf /var/lib/apt/lists/*  # Cleanup APT cache

# Set environment variables
ENV PG_MAJOR=16

# Build and install Apache AGE
WORKDIR /tmp/age
RUN ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/apache/age/releases/latest)) \
    && curl --fail -L "https://github.com/apache/age/archive/PG16%2F${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/age  # Remove build directory after installation

# Stage 2: Runtime with PostgreSQL and installed extensions
FROM debian:bookworm-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL repository
RUN apt-get update && apt-get install -y curl gnupg2 lsb-release \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update

# Install PostgreSQL 16 and necessary extensions without build tools
RUN apt-get install -y --no-install-recommends \
    postgresql-16 \
    postgresql-16-postgis-3 \
    postgresql-16-postgis-3-scripts \
    postgresql-16-pgvector \
    net-tools \
    curl \
    && rm -rf /var/lib/apt/lists/*  # Cleanup APT cache

# Set environment variables
ENV PG_MAJOR=16
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin
ENV POSTGRES_PORT=5432

# Copy the built Apache AGE files from the builder stage
COPY --from=builder /usr/lib/postgresql/ /usr/lib/postgresql/
COPY --from=builder /usr/share/postgresql/ /usr/share/postgresql/

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
