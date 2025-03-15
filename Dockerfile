# Allow configurable PostgreSQL major version using a build-time argument
ARG PG_MAJOR=17

# Single-stage build since we're using pre-built packages
FROM debian:bookworm-slim

# Declare and apply ARG
ARG PG_MAJOR
ENV PG_MAJOR=${PG_MAJOR}
ENV DEBIAN_FRONTEND=noninteractive
ENV POSTGRES_PORT=5432

# Install PostgreSQL repository
RUN apt-get update && apt-get install -y curl gnupg2 lsb-release \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update

# Install PostgreSQL and necessary extensions
RUN apt-get install -y --no-install-recommends \
    "postgresql-${PG_MAJOR}" \
    "postgresql-${PG_MAJOR}-age" \
    "postgresql-${PG_MAJOR}-postgis-3" \
    "postgresql-${PG_MAJOR}-postgis-3-scripts" \
    "postgresql-${PG_MAJOR}-pgvector" \
    libkrb5-dev \
    krb5-user \
    libpam-krb5 \
    net-tools \
    curl \
    && rm -rf /var/lib/apt/lists/*  # Cleanup APT cache

# Set environment variables for PostgreSQL
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

# Modify PostgreSQL configuration to listen on all IP addresses and set port
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '0.0.0.0'/" /etc/postgresql/$PG_MAJOR/main/postgresql.conf \
    && sed -i "s/#port = 5432/port = ${POSTGRES_PORT}/" /etc/postgresql/$PG_MAJOR/main/postgresql.conf \
    && echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/$PG_MAJOR/main/pg_hba.conf \
    && echo "# Kerberos authentication" >> /etc/postgresql/$PG_MAJOR/main/pg_hba.conf \
    && echo "hostgssenc all all 0.0.0.0/0 gss include_realm=0 krb_realm=DOCKER.DEV" >> /etc/postgresql/$PG_MAJOR/main/pg_hba.conf

# Update PostgreSQL config for GSSAPI
RUN echo "krb_server_keyfile = '/etc/postgresql-keytab'" >> /etc/postgresql/$PG_MAJOR/main/postgresql.conf

# Create a directory for custom initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Create a directory for Kerberos configuration
RUN mkdir -p /etc/krb5 && chmod 755 /etc/krb5

# Add a custom entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
WORKDIR /app/

# Switch to the postgres user
USER postgres

# Expose the PostgreSQL port
EXPOSE ${POSTGRES_PORT}

# Start PostgreSQL using the modified configuration
CMD ["docker-entrypoint.sh"]
