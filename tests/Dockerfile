# Use the official Alpine Linux image
FROM alpine:latest

# Install PostgreSQL client
RUN apk update && \
    apk add postgresql-client && \
    rm -rf /var/cache/apk/*

COPY . /tests
RUN chmod +x /tests/wait-for-postgres.sh
