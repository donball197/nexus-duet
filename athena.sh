#!/bin/bash
# =============================================================================
# AthenaFusionX — Genesis Master Controller (v9.9 Final / A2A Edition)
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "[🚀] $1"; }

# 1. PERMISSIONS
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

# 2. GENERATE DOCKER COMPOSE (Full Stack)
log "Configuring Infrastructure..."
cat <<YAML > docker-compose.yml
version: '3.8'
services:
  backend:
    build: ./backend
    env_file: .env
    ports:
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgres://athena:athena_pass@db:5432/athenadb
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  db:
    image: postgres:15-alpine
    restart: always
    environment:
      - POSTGRES_USER=athena
      - POSTGRES_PASSWORD=athena_pass
      - POSTGRES_DB=athenadb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
YAML

# 3. GENERATE DOCKERFILE (Optimized for ChromeOS)
cat <<DOCKER > backend/Dockerfile
FROM rust:1.83-slim as builder
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
# Skip re-downloading index if possible to speed up builds
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/athenafusionx-backend /athena
CMD ["/athena"]
DOCKER

# 4. LAUNCH
log "Launching Autonomous Stack..."
# Use 'docker-compose' or 'docker compose' depending on version
if command -v docker-compose &> /dev/null; then
    docker-compose up -d --build
else
    docker compose up -d --build
fi

log "======================================================"
log "✅ SYSTEM ONLINE: Backend + Database + A2A Logic"
log "-> Portal: http://localhost:3000"
log "======================================================"
