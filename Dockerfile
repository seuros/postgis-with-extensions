# Start from Ubuntu 22.04 as the base image
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
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PG_MAJOR=16
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

# Build and install Apache AGE
RUN git clone https://github.com/apache/age.git \
    && cd age \
    && git checkout PG16 \
    && make \
    && make install \
    && cd .. \
    && rm -rf age



# Create a directory for custom initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Add a custom entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to the postgres user
USER postgres

EXPOSE 5432
CMD ["docker-entrypoint.sh"]
