# Docker ARG Scoping Explained

## The Short Answer

**You need to redeclare ARGs in each stage where you use them.** This is a Docker requirement, not a bug.

## Visual Breakdown

```dockerfile
# ┌─────────────────────────────────────────┐
# │ Global Scope (before any FROM)          │
# │ Only available to the next FROM line    │
# └─────────────────────────────────────────┘
ARG PG_VERSION=16                           # ← Define once
ARG TIMESCALEDB_VERSION=""
ARG TOOLKIT_VERSION=""

FROM postgres:${PG_VERSION}-bookworm        # ✅ Can use PG_VERSION

# ┌─────────────────────────────────────────┐
# │ Stage 1 Scope (builder stage)           │
# │ Previous ARGs are NOT available here    │
# └─────────────────────────────────────────┘
ARG PG_VERSION                              # ← Redeclare to use in this stage
ARG TIMESCALEDB_VERSION                     # ← Redeclare to use in this stage
ARG TOOLKIT_VERSION                         # ← Redeclare to use in this stage

RUN echo ${PG_VERSION}                      # ✅ Works (redeclared on line above)
RUN echo ${TIMESCALEDB_VERSION}             # ✅ Works (redeclared)

# ┌─────────────────────────────────────────┐
# │ Global Scope (before second FROM)       │
# │ Stage 1 ARGs are NOT available here     │
# └─────────────────────────────────────────┘
ARG PG_VERSION=16                           # ← Must define again for next FROM

FROM postgres:${PG_VERSION}-bookworm        # ✅ Can use PG_VERSION

# ┌─────────────────────────────────────────┐
# │ Stage 2 Scope (final stage)             │
# │ Previous ARGs are NOT available here    │
# └─────────────────────────────────────────┘
ARG PG_VERSION                              # ← Redeclare to use in this stage

COPY ... ${PG_VERSION} ...                  # ✅ Works (redeclared)
```

## Why Docker Works This Way

Each stage in a multi-stage build is **isolated** for security and reproducibility:

1. **Global scope** (before FROM): Only for that FROM instruction
2. **Stage scope** (after FROM): Only for that stage's commands
3. **No inheritance**: Stages don't inherit ARGs from previous stages

## Common Patterns

### Pattern 1: Same ARG in all stages
```dockerfile
ARG VERSION=1.0
FROM base:${VERSION} AS builder
ARG VERSION                    # Redeclare
RUN echo ${VERSION}

ARG VERSION=1.0                # Redeclare for FROM
FROM base:${VERSION}
ARG VERSION                    # Redeclare
RUN echo ${VERSION}
```

### Pattern 2: Different ARGs per stage
```dockerfile
ARG BASE_VERSION=16
FROM postgres:${BASE_VERSION} AS builder
ARG APP_VERSION=2.0            # Only needed in builder
RUN install-app ${APP_VERSION}

ARG BASE_VERSION=16            # Redeclare for FROM
FROM postgres:${BASE_VERSION}
# Don't need APP_VERSION here
```

### Pattern 3: Build-time values (our case)
```dockerfile
# Users can override these
ARG PG_VERSION=16
ARG TIMESCALEDB_VERSION=""

FROM postgres:${PG_VERSION}
ARG PG_VERSION                 # Use in package names
ARG TIMESCALEDB_VERSION        # Use in package names
RUN apt-get install timescaledb-${PG_VERSION}=${TIMESCALEDB_VERSION}
```

## FAQ

### Q: Why not just use ENV instead?
**A**: ENV persists in the final image and can be seen by `docker inspect`. ARG is build-time only and doesn't bloat the image.

### Q: Can I reduce the number of ARG lines?
**A**: No, this is the minimum required by Docker. You need:
- 1x ARG before each FROM that uses it
- 1x ARG in each stage that uses it in RUN/COPY/etc

### Q: What happens if I forget to redeclare?
```dockerfile
ARG VERSION=1.0
FROM base AS builder
RUN echo ${VERSION}            # ❌ Empty! VERSION not available
```

### Q: Do I need default values every time?
```dockerfile
ARG VERSION=1.0                # ← Define default
FROM base:${VERSION}
ARG VERSION                    # ← No default needed, inherits value
```
You only need defaults in the **first** (global) declaration.

## Real-World Example (Our Dockerfile)

```dockerfile
# User can override: --build-arg PG_VERSION=15
ARG PG_VERSION=16              # Global: for first FROM

FROM postgres:${PG_VERSION} AS builder
ARG PG_VERSION                 # Builder stage: for package names
ARG TIMESCALEDB_VERSION=""     # Builder stage: for version pinning
RUN apt-get install timescaledb-2-postgresql-${PG_VERSION}=${TIMESCALEDB_VERSION}

ARG PG_VERSION=16              # Global: for second FROM
FROM postgres:${PG_VERSION}
ARG PG_VERSION                 # Final stage: for copy paths
COPY --from=builder /usr/lib/postgresql/${PG_VERSION}/ /usr/lib/postgresql/${PG_VERSION}/
```

## Summary

| Scope | Purpose | Required? |
|-------|---------|-----------|
| Before FROM | Pass to FROM instruction | Yes, if FROM uses it |
| After FROM | Use in RUN/COPY/etc | Yes, must redeclare |
| Between stages | Stages are isolated | Yes, redeclare for each stage |

**Bottom line**: The "duplicate" ARGs are required by Docker's security model. It's verbose but intentional! 🎯
