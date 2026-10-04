# TimescaleDB with Toolkit Docker Images

This directory contains Docker images for TimescaleDB with the TimescaleDB Toolkit extension included.

## Available Dockerfiles

### 1. Dockerfile.debian (Recommended for CI/CD)
**Base:** PostgreSQL 16 on Debian Bookworm
**Size:** ~200-300MB
**Build time:** Fast (~2-3 minutes)
**Reliability:** High (uses official APT packages)

**Pros:**
- Uses official TimescaleDB APT packages
- Fast and reliable builds
- Well-tested package versions
- Simpler troubleshooting

**Cons:**
- Slightly larger image size compared to Alpine
- Debian-based instead of Alpine

### 2. Dockerfile / Dockerfile.alpine
**Base:** TimescaleDB official Alpine image
**Size:** ~150-200MB (smaller)
**Build time:** Slow (~10-15 minutes)
**Reliability:** Medium (builds from source)

**Pros:**
- Smaller image size
- Based on official TimescaleDB Alpine image

**Cons:**
- Long build times (Rust compilation)
- More complex build process
- Potential build failures
- Requires more maintenance

## Build Instructions

### Debian version (recommended):

#### Latest versions (simplest):
```bash
cd timescaledb
docker build -f Dockerfile.debian -t timescaledb-toolkit:latest .
```

#### Specific PostgreSQL version:
```bash
# PostgreSQL 14
docker build --build-arg PG_VERSION=14 -f Dockerfile.debian -t timescaledb-toolkit:pg14 .

# PostgreSQL 15
docker build --build-arg PG_VERSION=15 -f Dockerfile.debian -t timescaledb-toolkit:pg15 .

# PostgreSQL 16 (default)
docker build --build-arg PG_VERSION=16 -f Dockerfile.debian -t timescaledb-toolkit:pg16 .
```

#### Pinned versions (for reproducible builds):
```bash
docker build \
  --build-arg PG_VERSION=16 \
  --build-arg TIMESCALEDB_VERSION=2.17.2~debian12 \
  --build-arg TOOLKIT_VERSION=1.18.0~debian12 \
  -f Dockerfile.debian \
  -t timescaledb-toolkit:pg16-pinned .
```

#### Using Makefile (easiest):
```bash
# Build with latest versions
make build-latest

# Build for specific PostgreSQL version
make build-pg14
make build-pg15
make build-pg16

# Build all versions
make build-all

# Build with pinned versions
make build-pinned PG_VERSION=16 TIMESCALEDB_VERSION=2.17.2~debian12 TOOLKIT_VERSION=1.18.0~debian12

# Test the image
make test PG_VERSION=16
```

### Alpine version:
```bash
cd timescaledb
docker build -f Dockerfile.alpine -t timescaledb-toolkit:alpine .
```

Or using the default Dockerfile:
```bash
cd timescaledb
docker build -t timescaledb-toolkit:alpine .
```

## Usage

### Using Docker directly:
```bash
docker run -d \
  --name timescaledb \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=password \
  timescaledb-toolkit:pg16-latest
```

### Using docker-compose:
```bash
# Start default (PostgreSQL 16 latest)
docker-compose up -d

# Start with pinned versions
docker-compose --profile pinned up -d timescaledb-pinned

# Start PostgreSQL 15
docker-compose --profile pg15 up -d timescaledb-pg15

# Start PostgreSQL 14
docker-compose --profile pg14 up -d timescaledb-pg14

# Start all versions
docker-compose --profile pg14 --profile pg15 --profile pinned up -d
```

### Connect and verify:
```bash
# Connect to database
docker exec -it timescaledb-latest psql -U postgres

# Or directly
psql -h localhost -U postgres -d timescale
```

```sql
-- Check installed extensions
\dx

-- Extensions are created automatically via init script
-- Verify versions
SELECT extname, extversion FROM pg_extension WHERE extname LIKE 'timescaledb%';

-- Verify toolkit functions are available
\df timescaledb_toolkit.*

-- Create a test hypertable
CREATE TABLE test_metrics (
  time TIMESTAMPTZ NOT NULL,
  device_id INTEGER,
  temperature DOUBLE PRECISION
);

SELECT create_hypertable('test_metrics', 'time');
```

## Version Discovery

### Finding available versions:

#### Method 1: Using the helper script (recommended, accurate):
```bash
# Query APT repository directly (requires Docker, takes ~30 seconds)
./list-versions.sh 16

# For other PostgreSQL versions
./list-versions.sh 14
./list-versions.sh 15
```

#### Method 2: Quick GitHub check (faster, but versions may differ):
```bash
# Quick check using GitHub releases (no Docker required)
./list-versions-simple.sh 16
```

#### Method 3: Using Makefile:
```bash
make list-versions PG_VERSION=16
```

#### Method 4: Browse packagecloud directly:
Visit: https://packagecloud.io/timescale/timescaledb?filter=postgresql-16

### Version format:
- **TimescaleDB**: `2.25.1~debian12-1612` (version~distribution-build)
- **Toolkit**: `1:1.22.0~debian12` (epoch:version~distribution)
- **PostgreSQL**: `14`, `15`, or `16`

**Important**: Toolkit versions include a `1:` epoch prefix in APT. Include this prefix when specifying versions.

### Current versions (as of Feb 2026):

| PostgreSQL | Latest TimescaleDB | Latest Toolkit |
|------------|-------------------|----------------|
| 16 | 2.25.1~debian12-1612 | 1:1.22.0~debian12 |
| 15 | 2.25.1~debian12-1512 | 1:1.22.0~debian12 |
| 14 | 2.25.1~debian12-1412 | 1:1.22.0~debian12 |

### Tested version combinations:

| PostgreSQL | TimescaleDB | Toolkit | Status |
|------------|-------------|---------|--------|
| 16 | latest | latest | ✅ Recommended |
| 16 | 2.25.1~debian12-1612 | 1:1.22.0~debian12 | ✅ Latest Stable |
| 16 | 2.24.0~debian12-1611 | 1:1.21.0~debian12 | ✅ Stable |
| 15 | latest | latest | ✅ Supported |
| 14 | latest | latest | ✅ Supported |

**Note**: Run `./list-versions.sh 16` to see all available versions, or check [packagecloud.io/timescale/timescaledb](https://packagecloud.io/timescale/timescaledb).

## Build Arguments Reference

| Argument | Default | Description | Example |
|----------|---------|-------------|---------|
| `PG_VERSION` | `16` | PostgreSQL major version | `14`, `15`, `16` |
| `TIMESCALEDB_VERSION` | _(latest)_ | TimescaleDB version | `2.17.2~debian12` |
| `TOOLKIT_VERSION` | _(latest)_ | Toolkit version | `1.18.0~debian12` |

**Note**: Leave version arguments empty to install the latest available version.

## CI/CD Integration

### GitHub Actions with version matrix:

See `.github-workflow-example.yml` for a complete example with:
- Multi-version matrix builds (PG 14, 15, 16)
- Version pinning support
- Integration testing
- Container registry push

#### Simple example:
```yaml
services:
  postgres:
    image: your-registry/timescaledb-toolkit:pg16-latest
    env:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: testdb
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

#### Matrix build example:
```yaml
strategy:
  matrix:
    pg_version: ["14", "15", "16"]
    timescaledb_version: ["2.17.2~debian12", ""]  # Empty = latest

steps:
  - uses: docker/build-push-action@v5
    with:
      build-args: |
        PG_VERSION=${{ matrix.pg_version }}
        TIMESCALEDB_VERSION=${{ matrix.timescaledb_version }}
```

## Image Size Comparison

- **Debian version:** ~280MB
- **Alpine version:** ~180MB
- **Build time (Debian):** ~2-3 minutes
- **Build time (Alpine):** ~10-15 minutes

## Recommendation

**Use Dockerfile.debian** for:
- CI/CD pipelines
- Production environments
- When reliability > size
- When build time matters

**Use Dockerfile.alpine** for:
- When image size is critical
- When you have time for longer builds
- Development environments where you can afford build failures

## Quick Reference

### Build commands:
```bash
# Latest everything
docker build -f Dockerfile.debian -t timescaledb:latest .

# Specific PG version
docker build --build-arg PG_VERSION=15 -f Dockerfile.debian -t timescaledb:pg15 .

# Pinned versions (reproducible) - note the 1: prefix for toolkit
docker build \
  --build-arg PG_VERSION=16 \
  --build-arg TIMESCALEDB_VERSION=2.25.1~debian12-1612 \
  --build-arg TOOLKIT_VERSION=1:1.22.0~debian12 \
  -f Dockerfile.debian -t timescaledb:pg16-pinned .
```

### Using Makefile:
```bash
make build-latest              # PG 16 latest
make build-pg15                # PG 15 latest
make build-all                 # All versions
make test PG_VERSION=16        # Test build
```

### Finding versions:
```bash
# Check packagecloud
curl -s https://packagecloud.io/timescale/timescaledb/packages.json | \
  jq -r '.[] | select(.name | contains("postgresql-16")) | .version' | \
  sort -V -r | head -10

# Or visit: https://packagecloud.io/timescale/timescaledb
```

## Troubleshooting

### Version not found error:
```
E: Version '2.17.2~debian12' for 'timescaledb-2-postgresql-16' was not found
```
**Solution**: Check available versions or omit version to use latest:
```bash
docker build --build-arg PG_VERSION=16 -f Dockerfile.debian .
```

### Extension not loaded:
```sql
ERROR: extension "timescaledb" is not available
```
**Solution**: The extensions are loaded automatically via `init-timescaledb.sh`. Ensure the init script is copied correctly.

### Build time too long:
- Use Debian version (fast) instead of Alpine (slow source compilation)
- Use Docker layer caching with `--cache-from`
- Use pre-built images in CI instead of building every time

## Sources

- [TimescaleDB Toolkit GitHub](https://github.com/timescale/timescaledb-toolkit)
- [TimescaleDB Installation Docs](https://docs.timescale.com/self-hosted/latest/tooling/install-toolkit/)
- [Building from Source](https://github.com/timescale/timescaledb-toolkit#-installing-from-source)
- [PackageCloud Repository](https://packagecloud.io/timescale/timescaledb)
- [APT Installation Guide](https://docs.timescale.com/self-hosted/latest/install/installation-linux/)
