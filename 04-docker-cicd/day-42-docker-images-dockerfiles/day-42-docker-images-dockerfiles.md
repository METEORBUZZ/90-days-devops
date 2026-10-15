# Day 42: Dockerfiles, Image Layering & Multi-Stage Builds

## 1. Theoretical Foundation

### How Docker Images are Structured
A **Docker Image** is an immutable, read-only template consisting of stacked layers.
Every instruction in a `Dockerfile` (`FROM`, `RUN`, `COPY`, `ADD`) creates a new layer:
- Layers are cryptographically hashed and cached.
- When an image runs as a container, the Docker storage driver (`overlay2`) adds a thin, writable **Container Layer** on top of the stacked read-only layers. All runtime file writes, modifications, and deletions occur inside this thin layer.

```
+--------------------------------------------------------------+
|  Thin Writable Container Layer (Reads & Writes)              |
+--------------------------------------------------------------+
|  Layer 4: CMD ["python", "app.py"]             (Read-Only)   |
|  Layer 3: COPY . /app                          (Read-Only)   |
|  Layer 2: RUN pip install -r requirements.txt  (Read-Only)   |
|  Layer 1: FROM python:3.11-slim                (Read-Only)   |
+--------------------------------------------------------------+
```

---

## 2. Optimizing Docker Layer Caching

Docker executes Dockerfile instructions from top to bottom. If a layer has not changed, Docker reuses the cached layer (`Using cache`).
However, **if a single layer changes, all subsequent layers are invalidated and re-executed from scratch!**

### Anti-Pattern (Slow Builds):
```dockerfile
FROM python:3.11-slim
WORKDIR /app
# BAD: Any single character change in app.py breaks cache for pip install!
COPY . /app
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

### DevOps Best Practice (Fast Builds):
```dockerfile
FROM python:3.11-slim
WORKDIR /app
# GOOD: Copy ONLY requirements first; pip install cached unless dependencies change!
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Copy application source code last
COPY . .
CMD ["python", "app.py"]
```

---

## 3. The `.dockerignore` File

The **Build Context** is the set of files sent from your local directory to the Docker daemon when you run `docker build`.
Without `.dockerignore`, you accidentally send gigabytes of `.git` history, temporary test logs, and local `.env` secrets into the image!

```dockerignore
.git
.github
*.md
.env
.env.*
__pycache__/
*.py[cod]
.venv/
node_modules/
dist/
Dockerfile
.dockerignore
```

---

## 4. Multi-Stage Builds (Enterprise Production Standard)

Multi-stage builds allow you to use heavy SDK compilers (Go, Rust, Node.js, Maven) in a build stage, and then copy **only the final compiled binary** into an ultra-lean runtime container.
Reduces image size from **1.2 GB down to 25 MB** and strips all build tools (gcc, git, npm) to prevent attacker exploitation!

### Complete Production Multi-Stage Go Example
```dockerfile
# ==========================================
# Stage 1: Build & Compile
# ==========================================
FROM golang:1.22-alpine AS builder

WORKDIR /src
# Cache module dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code and build statically linked binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /bin/api-server .

# ==========================================
# Stage 2: Minimal Secure Runtime
# ==========================================
FROM alpine:3.19

# Security: Add unprivileged system user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install certificates for HTTPS API calls
RUN apk --no-cache add ca-certificates

WORKDIR /home/appuser

# Copy ONLY compiled binary from builder stage
COPY --from=builder /bin/api-server /usr/local/bin/api-server

# Switch to non-root user
USER appuser

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/api-server"]
```

---

## 5. `CMD` vs. `ENTRYPOINT`

| Directive | Purpose | Overriding Behavior |
| :--- | :--- | :--- |
| **`ENTRYPOINT`** | Defines the fixed executable binary that runs when container launches. | Hard to override (`docker run --entrypoint /bin/sh ...`). |
| **`CMD`** | Provides default arguments passed to the `ENTRYPOINT` (or fallback executable). | Easily overridden by appending arguments (`docker run myimage arg1 arg2`). |

### Recommended Production Pattern:
```dockerfile
ENTRYPOINT ["/usr/local/bin/api-server"]
CMD ["--config=/etc/app/prod.yaml"]
```
- Running `docker run myimage` executes: `/usr/local/bin/api-server --config=/etc/app/prod.yaml`.
- Running `docker run myimage --debug` executes: `/usr/local/bin/api-server --debug`.

---

## 6. Interview & Review Questions
1. **Why are Multi-Stage builds critical for production container security and performance?**
   - *Answer*: Multi-stage builds separate the build environment (compilers, package managers, development dependencies) from the runtime environment. The final runtime image contains only the compiled binary and minimal runtime libraries, slashing image size (faster CI/CD pull times) and eliminating build tools that attackers could leverage during a container breakout.
2. **What happens if you place `COPY . .` before `RUN npm install` in a Node.js Dockerfile?**
   - *Answer*: Any modification to application source code (even a comment) invalidates the Docker cache at that line, forcing Docker to re-download and re-install all npm dependencies on every build, drastically slowing down CI/CD pipelines.
