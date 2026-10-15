# Day 43: Container Lifecycle, Port Forwarding, Environment & Logging

## 1. Theoretical Foundation

### The Container Lifecycle State Machine
```
            [ docker create ]
                    |
                    v
             [ Created State ]
                    |
              [ docker start ]
                    |
                    v
+------> [ Running State ] <------+
|                   |             |
|             [ docker stop ]     |
|                   |             |
|                   v             |
|            [ Stopped State ] ---+
|                   |
|                   v
|            [ docker rm ]
|                   |
|                   v
|             [ Destroyed ]
|
+--- [ docker run ] (create + start in one command)
```

---

## 2. Command Reference: `docker run` Explained

```bash
docker run -d \
  --name web-app \
  -p 8080:80 \
  -e "ENVIRONMENT=production" \
  -e "DB_HOST=10.0.1.50" \
  --restart unless-stopped \
  --memory=512m \
  --cpus=1.0 \
  nginx:alpine
```

### Breakdown of Flags:
- **`-d` (Detached Mode)**: Runs container in background and prints container ID. Without `-d`, container captures your terminal foreground.
- **`--name`**: Human-readable container name instead of randomly assigned Docker strings (`lucid_torvalds`).
- **`-p <HOST_PORT>:<CONTAINER_PORT>`**: Port mapping via `iptables` and `docker-proxy`.
  - `8080:80`: Traffic arriving on host machine port `8080` is forwarded to container port `80`.
- **`-e`**: Passes environment variables into container user space.
- **`--restart unless-stopped`**: Restart policy. If the container crashes or the host rebooted, Docker automatically restarts it unless stopped manually.
- **`--memory` and `--cpus`**: cgroup resource constraints preventing host exhaustion.

---

## 3. Container Inspection & Live Troubleshooting

```bash
# Execute an interactive shell inside a running container
docker exec -it web-app sh
# (Or bash if installed: docker exec -it web-app bash)

# Run a one-off command without interactive shell
docker exec web-app cat /etc/nginx/nginx.conf

# View live container resource consumption (CPU %, Mem %, Network I/O)
docker stats --no-stream

# View processes running inside the container
docker top web-app

# Copy files between host and container
docker cp web-app:/var/log/nginx/access.log ./local_access.log
```

---

## 4. Container Logging & Log Drivers

By default, Docker captures everything written to `stdout` and `stderr` by PID 1 inside the container using the **`json-file`** logging driver.

```bash
# View all logs
docker logs web-app

# Follow logs in real time (live stream)
docker logs -f web-app

# View last 50 lines with ISO timestamps
docker logs --tail 50 -t web-app
```

### The Unrotated Docker Log Disk Hazard
If an application outputs millions of log lines, the `json-file` on the host (`/var/lib/docker/containers/<id>/<id>-json.log`) will grow until it consumes 100% of host disk space!

**Fix: Configure Log Rotation in `/etc/docker/daemon.json`**:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
```
Reload daemon: `sudo systemctl reload docker`.

---

## 5. Interview & Review Questions
1. **What is the difference between `docker run` and `docker exec`?**
   - *Answer*: `docker run` creates and starts a brand-new container instance from an image. `docker exec` executes a new process (e.g. `/bin/sh`) inside an already running, active container.
2. **What does the port mapping `-p 127.0.0.1:8080:80` do compared to `-p 8080:80`?**
   - *Answer*: `-p 8080:80` binds to `0.0.0.0` (all host network interfaces), exposing the container port to the public internet and local LAN. `-p 127.0.0.1:8080:80` binds strictly to the host loopback interface, allowing only local host processes (or a reverse proxy like Nginx) to access it, preventing external public exposure.
