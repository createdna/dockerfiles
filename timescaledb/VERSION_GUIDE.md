# TimescaleDB Version Guide

## Quick Reference

### Finding Available Versions

```bash
# Method 1: Accurate APT query (takes ~30 seconds, requires Docker)
./list-versions.sh 16

# Method 2: Quick GitHub check (fast, no Docker)
./list-versions-simple.sh 16
```

### Current Latest Versions (Feb 2026)

| Component | PostgreSQL 14 | PostgreSQL 15 | PostgreSQL 16 |
|-----------|---------------|---------------|---------------|
| TimescaleDB | 2.25.1~debian12-1412 | 2.25.1~debian12-1512 | 2.25.1~debian12-1612 |
| Toolkit | 1:1.22.0~debian12 | 1:1.22.0~debian12 | 1:1.22.0~debian12 |

**Note**: Toolkit versions include the `1:` epoch prefix. Always include this when specifying versions.

## Version Format Explained

### TimescaleDB Version
```
2.25.1~debian12-1612
│  │ │  │        └─── Build number (PGVERSION + build)
│  │ │  └──────────── Distribution (debian12 = Bookworm)
│  │ └─────────────── Separator
│  └───────────────── Patch version
└──────────────────── Major.minor version
```

### Toolkit Version
```
1:1.22.0~debian12
│ │ │ │  └────────── Distribution
│ │ │ └───────────── Separator
│ │ └─────────────── Patch version
│ └───────────────── Major.minor version
└─────────────────── Epoch (Debian package versioning)
```

**Important**: The `1:` prefix is **required** when specifying Toolkit versions!

## Build Examples

### Development (Latest Versions)
```bash
# Let APT choose the latest
docker build \
  --build-arg PG_VERSION=16 \
  -f Dockerfile.debian \
  -t timescaledb:dev .
```

### Production (Pinned Versions)
```bash
# Specify exact versions for reproducibility
docker build \
  --build-arg PG_VERSION=16 \
  --build-arg TIMESCALEDB_VERSION=2.25.1~debian12-1612 \
  --build-arg TOOLKIT_VERSION=1:1.22.0~debian12 \
  -f Dockerfile.debian \
  -t timescaledb:prod .
```

### CI/CD Matrix
```yaml
matrix:
  include:
    - pg_version: "14"
      timescaledb_version: "2.25.1~debian12-1412"
      toolkit_version: "1:1.22.0~debian12"
    - pg_version: "15"
      timescaledb_version: "2.25.1~debian12-1512"
      toolkit_version: "1:1.22.0~debian12"
    - pg_version: "16"
      timescaledb_version: ""  # Latest
      toolkit_version: ""      # Latest
```

## Troubleshooting

### "Version not found" Error
```
E: Version '1.22.0~debian12' for 'timescaledb-toolkit-postgresql-16' was not found
```
**Problem**: Missing the epoch prefix `1:`

**Solution**: Add the epoch prefix:
```bash
--build-arg TOOLKIT_VERSION=1:1.22.0~debian12
```

### Build Fails with "Unable to locate package"
**Problem**: Version doesn't exist or wrong PostgreSQL version

**Solution**: Check available versions:
```bash
./list-versions.sh 16
```

### How to Find Older Versions
```bash
# Run the list-versions script to see last 15 versions
./list-versions.sh 16

# Or check packagecloud directly
open https://packagecloud.io/timescale/timescaledb?filter=postgresql-16
```

## Version Compatibility

### PostgreSQL Version Support
- **PostgreSQL 14**: Supported (older, stable)
- **PostgreSQL 15**: Supported (stable)
- **PostgreSQL 16**: Supported (recommended, latest)

### TimescaleDB + Toolkit Compatibility
All TimescaleDB 2.x versions work with all Toolkit 1.x versions for the same PostgreSQL major version.

**Example - All valid combinations for PG 16**:
- TimescaleDB 2.25.1 + Toolkit 1:1.22.0 ✅
- TimescaleDB 2.24.0 + Toolkit 1:1.22.0 ✅
- TimescaleDB 2.25.1 + Toolkit 1:1.21.0 ✅

## Resources

- **Package Repository**: https://packagecloud.io/timescale/timescaledb
- **TimescaleDB Releases**: https://github.com/timescale/timescaledb/releases
- **Toolkit Releases**: https://github.com/timescale/timescaledb-toolkit/releases
- **Documentation**: https://docs.timescale.com/

## Quick Commands

```bash
# List versions for PG 16
./list-versions.sh 16

# Build latest
make build-latest PG_VERSION=16

# Build pinned
make build-pinned \
  PG_VERSION=16 \
  TIMESCALEDB_VERSION=2.25.1~debian12-1612 \
  TOOLKIT_VERSION=1:1.22.0~debian12

# Test build
make test PG_VERSION=16
```
