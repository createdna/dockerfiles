.PHONY: help build-latest build-pg14 build-pg15 build-pg16 build-pinned test list-versions

# Default PostgreSQL version
PG_VERSION ?= 16

# Optional version pins (empty = latest)
TIMESCALEDB_VERSION ?=
TOOLKIT_VERSION ?=

# Image name
IMAGE_NAME ?= timescaledb-toolkit

help:
	@echo "TimescaleDB Docker Image Builder"
	@echo "================================="
	@echo ""
	@echo "Targets:"
	@echo "  build-latest      Build with latest versions (default PG_VERSION=16)"
	@echo "  build-pg14        Build for PostgreSQL 14"
	@echo "  build-pg15        Build for PostgreSQL 15"
	@echo "  build-pg16        Build for PostgreSQL 16"
	@echo "  build-pinned      Build with specific versions (set env vars)"
	@echo "  build-all         Build all PostgreSQL versions"
	@echo "  test              Test the built image"
	@echo "  list-versions     Show available package versions"
	@echo ""
	@echo "Examples:"
	@echo "  make build-latest"
	@echo "  make build-pg15"
	@echo "  make build-pinned PG_VERSION=16 TIMESCALEDB_VERSION=2.17.2~debian12"
	@echo "  make test PG_VERSION=16"
	@echo ""
	@echo "Environment Variables:"
	@echo "  PG_VERSION           PostgreSQL version (14, 15, or 16)"
	@echo "  TIMESCALEDB_VERSION  TimescaleDB version (e.g., 2.17.2~debian12)"
	@echo "  TOOLKIT_VERSION      Toolkit version (e.g., 1.18.0~debian12)"
	@echo "  IMAGE_NAME           Image name (default: timescaledb-toolkit)"

build-latest:
	@echo "Building TimescaleDB with PostgreSQL $(PG_VERSION) (latest versions)..."
	docker build \
		--build-arg PG_VERSION=$(PG_VERSION) \
		-f Dockerfile \
		-t $(IMAGE_NAME):pg$(PG_VERSION)-latest \
		-t $(IMAGE_NAME):latest \
		.

build-pg14:
	@$(MAKE) build-latest PG_VERSION=14

build-pg15:
	@$(MAKE) build-latest PG_VERSION=15

build-pg16:
	@$(MAKE) build-latest PG_VERSION=16

build-all: build-pg14 build-pg15 build-pg16

build-pinned:
	@echo "Building TimescaleDB with PostgreSQL $(PG_VERSION)..."
	@echo "  TimescaleDB: $(TIMESCALEDB_VERSION)"
	@echo "  Toolkit: $(TOOLKIT_VERSION)"
	docker build \
		--build-arg PG_VERSION=$(PG_VERSION) \
		--build-arg TIMESCALEDB_VERSION=$(TIMESCALEDB_VERSION) \
		--build-arg TOOLKIT_VERSION=$(TOOLKIT_VERSION) \
		-f Dockerfile \
		-t $(IMAGE_NAME):pg$(PG_VERSION)-ts$(TIMESCALEDB_VERSION) \
		.

test:
	@echo "Testing TimescaleDB image with PostgreSQL $(PG_VERSION)..."
	@docker run --rm -d \
		--name timescaledb-test-$(PG_VERSION) \
		-e POSTGRES_PASSWORD=test \
		$(IMAGE_NAME):pg$(PG_VERSION)-latest
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 10
	@echo "Testing extensions..."
	@docker exec timescaledb-test-$(PG_VERSION) psql -U postgres -c "\dx"
	@docker exec timescaledb-test-$(PG_VERSION) psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS timescaledb; CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit; SELECT extname, extversion FROM pg_extension WHERE extname LIKE 'timescaledb%';"
	@echo "Creating test hypertable..."
	@docker exec timescaledb-test-$(PG_VERSION) psql -U postgres -c "CREATE TABLE test (time TIMESTAMPTZ NOT NULL, value DOUBLE PRECISION); SELECT create_hypertable('test', 'time'); INSERT INTO test VALUES (NOW(), 1.0); SELECT * FROM test;"
	@echo "Test passed! Cleaning up..."
	@docker stop timescaledb-test-$(PG_VERSION)

list-versions:
	@echo "Available versions (from APT cache):"
	@echo ""
	@echo "To see all available versions, run:"
	@echo "  docker run --rm debian:bookworm bash -c '\
		apt-get update && \
		curl -fsSL https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | bash && \
		apt-cache madison timescaledb-2-postgresql-$(PG_VERSION) | head -20 && \
		echo "" && \
		apt-cache madison timescaledb-toolkit-postgresql-$(PG_VERSION) | head -20 \
	'"
	@echo ""
	@echo "Or check: https://packagecloud.io/timescale/timescaledb"

clean:
	@echo "Removing test containers..."
	@docker rm -f timescaledb-test-14 timescaledb-test-15 timescaledb-test-16 2>/dev/null || true
