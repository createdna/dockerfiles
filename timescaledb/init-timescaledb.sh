#!/bin/bash
set -e

echo "Initializing TimescaleDB extensions..."

# Create extensions
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS timescaledb;
    CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
EOSQL

echo ""
echo "✓ Extensions installed successfully:"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT
        extname AS "Extension",
        extversion AS "Version"
    FROM pg_extension
    WHERE extname LIKE 'timescaledb%'
    ORDER BY extname;
EOSQL
