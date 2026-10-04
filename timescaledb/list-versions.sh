#!/bin/bash
# Helper script to list available TimescaleDB and Toolkit versions
# Uses apt-cache inside a Docker container (no authentication required)

set -e

PG_VERSION="${1:-16}"
DEBIAN_VERSION="${2:-bookworm}"

echo "================================================"
echo "TimescaleDB Versions for PostgreSQL ${PG_VERSION}"
echo "Debian: ${DEBIAN_VERSION}"
echo "================================================"
echo ""
echo "Querying APT repository (this may take 30 seconds)..."
echo ""

# Use Docker to query apt-cache (no auth needed, more reliable)
docker run --rm debian:${DEBIAN_VERSION} bash -c "
set -e

# Update and add TimescaleDB repo
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1
apt-get install -y -qq curl gnupg lsb-release > /dev/null 2>&1

# Add TimescaleDB repository
curl -fsSL https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh 2>/dev/null | bash > /dev/null 2>&1

# Update cache
apt-get update -qq > /dev/null 2>&1

echo '================================================'
echo 'Available TimescaleDB versions:'
echo '================================================'
apt-cache madison timescaledb-2-postgresql-${PG_VERSION} 2>/dev/null | \
  awk '{print \$3}' | \
  head -15 | \
  nl -w2 -s'. '

echo ''
echo '================================================'
echo 'Available Toolkit versions:'
echo '================================================'
apt-cache madison timescaledb-toolkit-postgresql-${PG_VERSION} 2>/dev/null | \
  awk '{print \$3}' | \
  head -15 | \
  nl -w2 -s'. '
"

echo ""
echo "================================================"
echo "Usage Examples:"
echo "================================================"
echo ""
echo "# Latest versions (recommended for development):"
echo "docker build --build-arg PG_VERSION=${PG_VERSION} -f Dockerfile.debian -t timescaledb:pg${PG_VERSION} ."
echo ""
echo "# Or with make:"
echo "make build-latest PG_VERSION=${PG_VERSION}"
echo ""
echo "# Specific versions (recommended for production/CI):"
echo "docker build \\"
echo "  --build-arg PG_VERSION=${PG_VERSION} \\"
echo "  --build-arg TIMESCALEDB_VERSION=2.17.2~debian12 \\"
echo "  --build-arg TOOLKIT_VERSION=1.18.0~debian12 \\"
echo "  -f Dockerfile.debian -t timescaledb:pg${PG_VERSION}-pinned ."
echo ""
echo "================================================"
echo "For other PostgreSQL versions, run:"
echo "  ./list-versions.sh 14    # PostgreSQL 14"
echo "  ./list-versions.sh 15    # PostgreSQL 15"
echo "  ./list-versions.sh 16    # PostgreSQL 16"
echo "================================================"
echo ""
