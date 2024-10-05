#!/bin/bash
set -e

# Function to start PostgreSQL service
start_postgres() {
	echo "Starting PostgreSQL service..."
	pg_ctlcluster $PG_MAJOR main start
}

# Function to set the postgres user password
set_postgres_password() {
	# Check if the POSTGRES_PASSWORD variable is set
	if [ -z "$POSTGRES_PASSWORD" ]; then
		echo "Error: POSTGRES_PASSWORD is not set"
		exit 1
	else
		echo "Setting postgres user password..."
		psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres <<-EOSQL
		    ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD}';
		EOSQL
	fi
}

# Function to create a default database if it doesn't exist
create_default_db() {
	echo "Checking for default database..."
	if [ -z "$(psql -Atc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB:-postgres}'")" ]; then
		echo "Creating default database '${POSTGRES_DB:-postgres}'..."
		createdb -E UTF8 ${POSTGRES_DB:-postgres}
	else
		echo "Database '${POSTGRES_DB:-postgres}' already exists."
	fi
}

# Function to run initialization scripts
run_init_scripts() {
	echo "Running initialization scripts..."
	for f in /docker-entrypoint-initdb.d/*; do
		case "$f" in
			*.sql)
				echo "$0: running $f"
				psql -d ${POSTGRES_DB:-postgres} -f "$f"
				echo ;;
			*.sql.gz)
				echo "$0: running $f"
				gunzip -c "$f" | psql -d ${POSTGRES_DB:-postgres}
				echo ;;
			*)
				echo "$0: ignoring $f" ;;
		esac
		echo
	done
}

# Trap to stop PostgreSQL service when script exits
trap 'echo "Stopping PostgreSQL service..."; pg_ctlcluster $PG_MAJOR main stop' EXIT

# Start PostgreSQL
start_postgres

# Set postgres user password
set_postgres_password

# Create default database
create_default_db

# Run initialization scripts
run_init_scripts

# Keep the container running
tail -f /dev/null
