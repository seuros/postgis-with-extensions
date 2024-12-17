# Allow configurable PostgreSQL major version using a build-time argument
ARG PG_MAJOR=17

# Stage 1: Build Apache AGE and other dependencies
FROM debian:bookworm-slim AS builder

# Declare and reapply ARG in this stage
ARG PG_MAJOR
ENV PG_MAJOR=${PG_MAJOR}
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
   "postgresql-server-dev-${PG_MAJOR}" \
   "postgresql-${PG_MAJOR}" \
   && rm -rf /var/lib/apt/lists/*  # Cleanup APT cache

# Build and install Apache AGE if PG_MAJOR is not 17
WORKDIR /tmp/age
RUN if [ "$PG_MAJOR" != "17" ]; then \
	   ASSET_NAME=$(basename $(curl -LIs -o /dev/null -w %{url_effective} https://github.com/apache/age/releases/latest)) \
	   && curl --fail -L "https://github.com/apache/age/archive/PG${PG_MAJOR}%2F${ASSET_NAME}.tar.gz" | tar -zx --strip-components=1 -C . \
	   && make \
	   && make install; \
   else \
	   echo "Skipping Apache AGE installation for PostgreSQL $PG_MAJOR"; \
   fi \
   && cd / \
   && rm -rf /tmp/age  # Remove build directory after installation


# Stage 2: Runtime with PostgreSQL and installed extensions
FROM debian:bookworm-slim

# Declare and reapply ARG in this stage
ARG PG_MAJOR
ENV PG_MAJOR=${PG_MAJOR}
ENV DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL repository
RUN apt-get update && apt-get install -y curl gnupg2 lsb-release \
   && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null \
   && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
   && apt-get update

# Install PostgreSQL and necessary extensions without build tools
RUN apt-get install -y --no-install-recommends \
   "postgresql-${PG_MAJOR}" \
   "postgresql-${PG_MAJOR}-postgis-3" \
   "postgresql-${PG_MAJOR}-postgis-3-scripts" \
   "postgresql-${PG_MAJOR}-pgvector" \
   net-tools \
   curl \
   && rm -rf /var/lib/apt/lists/*  # Cleanup APT cache

# Set environment variables for PostgreSQL
ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin
ENV POSTGRES_PORT=5432

# Copy the built Apache AGE files from the builder stage (if built)
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

# Expose the PostgreSQL port
EXPOSE ${POSTGRES_PORT}

# Start PostgreSQL using the modified configuration
CMD ["docker-entrypoint.sh"]
