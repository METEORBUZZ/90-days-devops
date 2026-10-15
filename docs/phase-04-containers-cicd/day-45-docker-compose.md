# Day 45: Multi-Container Microservices with Docker Compose

## 1. Theoretical Foundation

### What is Docker Compose?
Docker Compose is a declarative tool for defining and running multi-container Docker applications.
Instead of typing dozens of manual `docker run`, `docker network create`, and `docker volume create` commands with fragile shell scripts, the entire architecture (services, networks, volumes, environment variables, health checks) is defined in a single YAML file: **`compose.yaml`** (or `docker-compose.yml`).

---

## 2. Production Architecture: 3-Tier Web Application Stack

Let's build a complete production microservice stack:
1. **Frontend / API Service** (Node.js / Python).
2. **In-Memory Cache** (Redis).
3. **Relational Database** (PostgreSQL) with persistent volume.

### Complete `compose.yaml` Specification:
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: production-api
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_PORT=5432
      - DB_USER=postgres
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - REDIS_URL=redis://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    networks:
      - app-tier
      - db-tier
    secrets:
      - db_password

  cache:
    image: redis:7-alpine
    container_name: app-cache
    restart: unless-stopped
    command: ["redis-server", "--maxmemory", "256mb", "--maxmemory-policy", "allkeys-lru"]
    networks:
      - app-tier

  db:
    image: postgres:16-alpine
    container_name: app-database
    restart: unless-stopped
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - db-tier
    secrets:
      - db_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d appdb"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

volumes:
  postgres_data:
    driver: local

networks:
  app-tier:
    driver: bridge
  db-tier:
    driver: bridge

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

---

## 3. Essential Docker Compose CLI Commands

In modern Docker installations (v2+), use the integrated CLI command: **`docker compose`** (without hyphen).

```bash
# Build and start all services in detached background mode
docker compose up -d

# Force rebuild of Dockerfile images before starting
docker compose up -d --build

# Inspect status of all containers defined in compose file
docker compose ps

# Live follow logs across all services simultaneously
docker compose logs -f

# Filter logs for specific service only
docker compose logs -f app

# Execute command inside a compose service container
docker compose exec db psql -U postgres -d appdb

# Stop all containers without deleting volumes
docker compose stop

# Destroy containers, networks, and shutdown stack
docker compose down

# Destroy containers AND delete all persistent named volumes (CAUTION!)
docker compose down -v
```

---

## 4. Architectural Highlights of the Compose Specification

1. **Dual Network Segmentation**:
   - `app` is connected to both `app-tier` and `db-tier`.
   - `cache` is connected only to `app-tier`.
   - `db` is connected only to `db-tier`.
   - **Result**: The Redis cache cannot communicate with the database, and neither the database nor cache ports are exposed to the host machine's external network.
2. **`condition: service_healthy`**:
   - Traditional `depends_on: [db]` only waits until the DB container process launches. Often the database is still initializing and rejects connections!
   - `condition: service_healthy` forces Docker Compose to wait until PostgreSQL successfully answers `pg_isready` before starting the application container.

---

## 5. Interview & Review Questions
1. **Why is `condition: service_healthy` superior to standard `depends_on` in Docker Compose?**
   - *Answer*: Standard `depends_on` only checks if the container has reached the "running" state at the process level. For complex services like databases, the daemon often takes 5–15 seconds to run migrations and open listening sockets. `condition: service_healthy` ensures dependent application containers are not launched until the database passes an active health check probe.
2. **What does `docker compose down -v` do and why must it be used with extreme caution?**
   - *Answer*: `docker compose down` removes containers and networks created by the Compose file. Adding the `-v` flag instructs Docker to also permanently delete all associated named volumes, which wipes out database state and persistent storage.
