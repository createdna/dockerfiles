ARG PG_VERSION=17
FROM postgres:${PG_VERSION}-bookworm AS builder

# Declare all build args needed in this stage
ARG PG_VERSION
ARG TIMESCALEDB_VERSION=""
ARG TOOLKIT_VERSION=""

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      lsb-release && \
    rm -rf /var/lib/apt/lists/*

# Add TimescaleDB repository
RUN curl -fsSL https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | bash

# Install TimescaleDB and Toolkit with optional version pinning
RUN apt-get update && \
    if [ -n "${TIMESCALEDB_VERSION}" ]; then \
      apt-get install -y --no-install-recommends \
        timescaledb-2-postgresql-${PG_VERSION}=${TIMESCALEDB_VERSION} \
        timescaledb-2-loader-postgresql-${PG_VERSION}=${TIMESCALEDB_VERSION}; \
    else \
      apt-get install -y --no-install-recommends \
        timescaledb-2-postgresql-${PG_VERSION}; \
    fi && \
    if [ -n "${TOOLKIT_VERSION}" ]; then \
      TOOLKIT_PKG="timescaledb-toolkit-postgresql-${PG_VERSION}=${TOOLKIT_VERSION}"; \
    else \
      TOOLKIT_PKG="timescaledb-toolkit-postgresql-${PG_VERSION}"; \
    fi && \
    apt-get install -y --no-install-recommends \
      ${TOOLKIT_PKG} && \
    rm -rf /var/lib/apt/lists/*

# Configure PostgreSQL to load TimescaleDB
RUN echo "shared_preload_libraries = 'timescaledb'" >> /usr/share/postgresql/postgresql.conf.sample


ARG PG_VERSION=16
FROM postgres:${PG_VERSION}-bookworm

LABEL org.opencontainers.image.source=https://github.com/createdna/dockerfiles

# Declare PG_VERSION for use in this stage
ARG PG_VERSION

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy installed extensions from builder
COPY --from=builder /usr/lib/postgresql/${PG_VERSION}/ /usr/lib/postgresql/${PG_VERSION}/
COPY --from=builder /usr/share/postgresql/${PG_VERSION}/ /usr/share/postgresql/${PG_VERSION}/
COPY --from=builder /usr/share/postgresql/postgresql.conf.sample /usr/share/postgresql/postgresql.conf.sample

# Add initialization script
COPY --chmod=755 init-timescaledb.sh /docker-entrypoint-initdb.d/001-init-timescaledb.sh
