# Day 44: Docker Persistent Storage & Container Networking

## 1. Theoretical Foundation

### The Ephemeral Nature of Containers
By default, all files created inside a container are stored on the writable container layer. When that container is removed (`docker rm`), **all data is permanently destroyed**.
To persist database records, application uploads, and configurations, Docker provides **Volumes** and **Bind Mounts**.

---

## 2. Docker Storage Strategies

```
+-------------------------------------------------------------------------------+
|                       Host Operating System Filesystem                        |
|                                                                               |
|  [ /var/lib/docker/volumes/my_data/_data ]     [ /home/ubuntu/app/config.json]|
|                      |                                       |                |
|                      v (Managed by Docker)                   v (Host Path)    |
|             +-----------------+                     +-----------------+       |
|             |  Named Volume   |                     |   Bind Mount    |       |
|             +-----------------+                     +-----------------+       |
+----------------------|---------------------------------------|----------------+
                       v                                       v
          [ /var/lib/postgresql/data ]                [ /etc/app/config.json ]
          (Inside Container A)                        (Inside Container B)
```

| Type | Managed By | Host Location | Best DevOps Use Case |
| :--- | :--- | :--- | :--- |
| **Named Volumes** | Docker Engine | `/var/lib/docker/volumes/` | Production databases (PostgreSQL, MySQL), persistent microservice state, high I/O performance |
| **Bind Mounts** | User / Host path | Any arbitrary host directory (`/home/user/code`) | Local development (live code reload), mounting host configs (`/etc/ssl`, `/var/run/docker.sock`) |
| **tmpfs Mount** | Host RAM | Memory only | Ephemeral, sensitive secrets that should never touch persistent disk |

### Volume Commands
```bash
# Create a named volume
docker volume create pgdata

# Run PostgreSQL with persistent named volume
docker run -d \
  --name db \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# Run container with read-only bind mount (:ro)
docker run -d \
  --name web \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  -p 80:80 \
  nginx:alpine
```

---

## 3. Docker Container Networking & Embedded DNS

Docker uses Linux network namespaces and software virtual bridges (`veth` pairs) to route packets:

### Network Drivers
1. **`bridge` (Default)**: Creates a private software bridge (`docker0`) on the host. Containers communicate via private internal IPs (`172.17.0.x`).
2. **`host`**: Disables network namespace isolation. Container shares the host's exact network stack directly (no port mapping needed; maximum throughput, but port conflict hazard).
3. **`none`**: Complete network isolation. Loopback interface only.
4. **`overlay`**: Multi-host container networking across multiple Docker Swarm / Kubernetes nodes.

---

## 4. User-Defined Bridge Networks & Container Service Discovery

In the default `bridge` network (`docker0`), containers cannot resolve each other by container name (only by unstable IP addresses).
**DevOps Standard: Always create a User-Defined Bridge Network!**
User-defined bridge networks provide **automatic DNS service discovery** via Docker's embedded DNS server (`127.0.0.11`):

```bash
# 1. Create a custom network
docker network create internal-net

# 2. Launch backend database on internal network
docker run -d --name postgres-db --network internal-net -e POSTGRES_PASSWORD=pass postgres:16-alpine

# 3. Launch application connected to same network
docker run -d --name web-api --network internal-net -p 8080:8080 my-api-image
```
Inside the `web-api` container, the application simply connects to database host: **`postgres-db:5432`**! Docker's internal DNS automatically resolves the name to the container's active internal IP.

---

## 5. Interview & Review Questions
1. **What is the difference between Docker's default bridge network and a user-defined bridge network?**
   - *Answer*: On the default bridge (`docker0`), containers cannot resolve each other by container name via DNS; you must link them manually or use IP addresses. On a user-defined bridge network, Docker provides automatic internal DNS name resolution, and network isolation is improved since unrelated containers do not share the bridge.
2. **What does the `:ro` flag do in a Docker volume or bind mount?**
   - *Answer*: `:ro` mounts the volume or host directory as Read-Only inside the container filesystem. The container process can read the files (such as configuration files or SSL certificates), but the Linux kernel prevents any write or delete operations from within the container.
