#!/bin/bash
# Simple version listing using web scraping (no Docker required)
# This is faster but less accurate than list-versions.sh

PG_VERSION="${1:-16}"

echo "================================================"
echo "TimescaleDB Package Versions (PostgreSQL ${PG_VERSION})"
echo "================================================"
echo ""
echo "Fetching from packagecloud.io..."
echo ""

echo "Visit this URL to see all available packages:"
echo "https://packagecloud.io/timescale/timescaledb?q=postgresql-${PG_VERSION}"
echo ""

echo "================================================"
echo "Recent versions (from GitHub releases):"
echo "================================================"

# Fetch recent releases from GitHub
echo ""
echo "TimescaleDB releases:"
curl -s https://api.github.com/repos/timescale/timescaledb/releases | \
  grep '"tag_name":' | \
  sed -E 's/.*"tag_name": "([^"]+)".*/\1/' | \
  head -10 | \
  nl -w2 -s'. '

echo ""
echo "Toolkit releases:"
curl -s https://api.github.com/repos/timescale/timescaledb-toolkit/releases | \
  grep '"tag_name":' | \
  sed -E 's/.*"tag_name": "([^"]+)".*/\1/' | \
  head -10 | \
  nl -w2 -s'. '

echo ""
echo "================================================"
echo "Note: GitHub versions may differ from APT package versions"
echo "For exact APT versions, use: ./list-versions.sh ${PG_VERSION}"
echo "================================================"
echo ""
echo "Quick build examples:"
echo ""
echo "# Latest (recommended for development):"
echo "docker build --build-arg PG_VERSION=${PG_VERSION} -t timescaledb:latest ."
echo ""
echo "# With specific versions (replace X.Y.Z with versions above):"
echo "docker build \\"
echo "  --build-arg PG_VERSION=${PG_VERSION} \\"
echo "  --build-arg TIMESCALEDB_VERSION=2.25.1~debian12-1612 \\"
echo "  --build-arg TOOLKIT_VERSION=1:1.22.0~debian12 \\"
echo "  -t timescaledb:pinned ."
echo ""
