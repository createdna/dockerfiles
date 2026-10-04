# PostgreSQL Extension Versioning Explained

## Quick Answer

**The APT package includes MULTIPLE versions for upgrade path compatibility, but uses the latest by default.**

```bash
# Install APT package
apt-get install timescaledb-2-postgresql-16=2.25.1~debian12-1612

# This installs 35+ versions (2.13.0 through 2.25.1)
# But default_version = 2.25.1

# Later when init script runs
CREATE EXTENSION timescaledb;  # → Creates version 2.25.1 (default)
CREATE EXTENSION timescaledb VERSION '2.24.0';  # → Can create 2.24.0 explicitly
```

## How It Works

### 1. APT Package = Multiple Versions!
```
timescaledb-2-postgresql-16=2.25.1~debian12-1612
                            └─────────┬─────────┘
                                      │
                            APT package version (latest)
                                      │
                                      ↓
        Installs versions 2.13.0 → 2.25.1 (35+ versions)
                                      │
                                      ↓
                            default_version = 2.25.1
```

### 2. Files Installed on Disk (35+ Versions!)
```
/usr/lib/postgresql/16/lib/
  ├── timescaledb-2.13.0.so          ← Binary libraries
  ├── timescaledb-2.14.0.so          ← For all versions
  ├── timescaledb-2.15.0.so          ← 2.13.0 through
  ├── ...                            ← 2.25.1
  ├── timescaledb-2.24.0.so
  └── timescaledb-2.25.1.so          ← Latest

/usr/share/postgresql/16/extension/
  ├── timescaledb.control            ← Control file (default_version = 2.25.1)
  ├── timescaledb--2.13.0.sql        ← Install scripts for each version
  ├── timescaledb--2.24.0.sql
  ├── timescaledb--2.25.1.sql
  ├── timescaledb--2.24.0--2.25.1.sql  ← Upgrade paths between versions
  └── timescaledb--2.23.0--2.25.1.sql  ← (~100+ upgrade scripts)
```

### 3. CREATE EXTENSION Behavior
```sql
-- Without version specified (default)
CREATE EXTENSION timescaledb;
-- → Uses default_version from timescaledb.control
-- → Which is 2.25.1 (from the APT package)

-- With explicit version
CREATE EXTENSION timescaledb VERSION '2.25.1';
-- → Same result, but explicit
```

## Version Verification

### Check What's Available Before Creating
```sql
-- List available extension versions
SELECT * FROM pg_available_extensions WHERE name LIKE 'timescaledb%';
```

Output:
```
     name         | default_version | installed_version | comment
------------------+-----------------+-------------------+----------
 timescaledb      | 2.25.1         |                   | ...
 timescaledb_toolkit | 1.22.0      |                   | ...
```

### Check What's Installed After Creating
```sql
-- List installed extensions
SELECT extname, extversion FROM pg_extension WHERE extname LIKE 'timescaledb%';
```

Output:
```
     extname          | extversion
----------------------+------------
 timescaledb          | 2.25.1
 timescaledb_toolkit  | 1.22.0
```

## Multiple Versions Scenario

### Question: "What if PostgreSQL has multiple versions available?"

**Answer**: This **DOES happen** with TimescaleDB APT packages!

The APT package intentionally includes **35+ versions** (2.13.0 through 2.25.1) for upgrade path compatibility.

### Why Multiple Versions?

1. **Database Upgrades**: Existing databases can upgrade incrementally
2. **Backup Restoration**: Restore backups from older TimescaleDB versions
3. **Migration Support**: Smooth migration path from older versions
4. **Compatibility**: Support various upgrade scenarios

### Which Version Gets Created?

```sql
-- Default: Uses version from timescaledb.control
CREATE EXTENSION timescaledb;
-- Creates: 2.25.1 (default_version from control file)

-- Explicit: You can choose any available version
CREATE EXTENSION timescaledb VERSION '2.24.0';
-- Creates: 2.24.0

CREATE EXTENSION timescaledb VERSION '2.20.0';
-- Creates: 2.20.0
```

## Explicit Version Pinning (If Needed)

If you want to be explicit in your init script:

```bash
#!/bin/bash
set -e

TIMESCALEDB_VERSION="${TIMESCALEDB_VERSION:-2.25.1}"
TOOLKIT_VERSION="${TOOLKIT_VERSION:-1.22.0}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS timescaledb VERSION '${TIMESCALEDB_VERSION}';
    CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit VERSION '${TOOLKIT_VERSION}';
EOSQL
```

**But this is unnecessary** because the APT package already enforces the version!

## Extension Upgrades

If you want to upgrade to a new version:

### Method 1: Rebuild Image (Recommended)
```bash
# Build with new version
docker build --build-arg TIMESCALEDB_VERSION=2.26.0~debian12-1612 ...

# Inside database
ALTER EXTENSION timescaledb UPDATE TO '2.26.0';
```

### Method 2: In-place Upgrade
```sql
-- Check available versions
SELECT * FROM pg_available_extensions WHERE name = 'timescaledb';

-- Upgrade
ALTER EXTENSION timescaledb UPDATE;  -- to default version
-- or
ALTER EXTENSION timescaledb UPDATE TO '2.26.0';  -- to specific version
```

## Summary Table

| Scenario | Result |
|----------|--------|
| Install APT package v2.25.1 | 35+ versions available (2.13.0-2.25.1) |
| `CREATE EXTENSION timescaledb;` | Creates v2.25.1 (default) |
| `CREATE EXTENSION timescaledb VERSION '2.25.1';` | Creates v2.25.1 (explicit) |
| `CREATE EXTENSION timescaledb VERSION '2.24.0';` | ✅ Creates v2.24.0 |
| `CREATE EXTENSION timescaledb VERSION '2.20.0';` | ✅ Creates v2.20.0 |
| `CREATE EXTENSION timescaledb VERSION '2.12.0';` | ❌ Error: not in package (too old) |
| Install new APT package v2.26.0 | New range (e.g., 2.14.0-2.26.0) |

## Best Practices

### ✅ DO
- Pin APT package versions in production (`TIMESCALEDB_VERSION=2.25.1~debian12-1612`)
- Let `CREATE EXTENSION` use the default (no VERSION clause)
- Verify versions after container start (logs/health checks)
- Use `ALTER EXTENSION ... UPDATE` for upgrades

### ❌ DON'T
- Hardcode extension versions in init scripts (redundant with APT version)
- Assume multiple versions are available (they're not with APT)
- Skip version pinning in CI/CD (breaks reproducibility)

## Testing Version Match

```bash
# Build with specific version
docker build \
  --build-arg TIMESCALEDB_VERSION=2.25.1~debian12-1612 \
  -t test .

# Run and verify
docker run -d --name test -e POSTGRES_PASSWORD=test test
sleep 10

# Check installed version
docker exec test psql -U postgres -c "SELECT extversion FROM pg_extension WHERE extname='timescaledb';"
# Should output: 2.25.1

# Cleanup
docker stop test && docker rm test
```

## Related Files
- `init-timescaledb.sh` - Basic initialization (recommended)
- `init-timescaledb-verbose.sh` - With version logging
- `Dockerfile.debian` - Where APT versions are specified
