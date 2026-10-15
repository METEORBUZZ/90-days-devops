# Day 46: Container Security, Vulnerability Scanning & Distroless Images

## 1. Theoretical Foundation

### The Container Attack Surface
Because containers share the host Linux kernel, container security is vital. If an attacker exploits a remote code execution (RCE) vulnerability inside a container running as `root`, they can attempt kernel exploits (e.g. Dirty COW, runc container breakout) to compromise the underlying host and access all co-located tenant workloads.

### The 4 Tenets of Container Hardening
1. **Never run containers as `root` (UID 0)**: Always create and switch to an unprivileged system user.
2. **Minimal Base Images**: Eliminate unnecessary package managers, shells, and curl/wget utilities.
3. **Immutable Root Filesystem**: Mount container root as Read-Only (`--read-only`).
4. **Drop Linux Capabilities**: Strip elevated kernel capabilities (`--cap-drop=ALL`).

---

## 2. Hardening Dockerfiles

```dockerfile
FROM alpine:3.19

# 1. Security: Create dedicated unprivileged system user and group with fixed high UID
RUN addgroup -g 10001 appgroup && \
    adduser -u 10001 -G appgroup -s /sbin/nologin -D appuser

WORKDIR /app

# 2. Copy application binary and enforce ownership
COPY --chown=appuser:appgroup ./bin/api-server /app/api-server

# 3. Strip write permissions on binary
RUN chmod 550 /app/api-server

# 4. Mandatory: Switch to non-root user
USER 10001

EXPOSE 8080
ENTRYPOINT ["/app/api-server"]
```

### Google Distroless Images
For maximum security, use Google's **Distroless** base images:
- Contains **only your application and its minimal runtime dependencies** (glibc, CA certificates, tzdata).
- Contains **no package managers (`apt`, `apk`)**.
- Contains **no shell (`/bin/sh`, `/bin/bash`)**!
- If an attacker injects commands, there is literally no shell interpreter to execute them.

```dockerfile
# Build binary in standard Golang compiler
FROM golang:1.22 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server .

# Production Distroless Runtime
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /app/server /server
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```

---

## 3. Automated Vulnerability Scanning with Trivy

**Trivy** (by Aqua Security) is the industry standard for vulnerability scanning in CI/CD pipelines. It scans OS packages and language-specific dependencies (npm, pip, maven) against national CVE databases.

```bash
# Install Trivy
brew install trivy    # macOS
# Or Linux: apt install trivy

# Scan a Docker image locally
trivy image nginx:1.20

# Scan image and fail the CI/CD pipeline if CRITICAL or HIGH vulnerabilities exist
trivy image --severity HIGH,CRITICAL --exit-code 1 my-company-api:latest
```

---

## 4. Runtime Security Hardening Flags

When launching containers in production with `docker run`:

```bash
docker run -d \
  --name secure-web \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --security-opt=no-new-privileges:true \
  -p 80:80 \
  my-secure-image
```
- `--read-only`: The container filesystem is mounted read-only. Attackers cannot download scripts or modify web files!
- `--cap-drop=ALL`: Removes all kernel root capabilities (like raw packet creation, module loading, chown).
- `--cap-add=NET_BIND_SERVICE`: Adds back only the specific capability required to bind low ports (80/443).
- `--security-opt=no-new-privileges:true`: Prevents SUID binaries from escalating privileges inside the container.

---

## 5. Interview & Review Questions
1. **Why should you never run production containers as `root`?**
   - *Answer*: UID 0 inside a container is by default UID 0 on the host Linux kernel. If an application contains an RCE vulnerability or a container breakout flaw in the container runtime (`runc`), an attacker running as root inside the container inherits root privileges on the underlying host operating system. Running as an unprivileged UID (e.g. 10001) confines the blast radius.
2. **What is a "Distroless" container image and what security advantages does it offer?**
   - *Answer*: Distroless images contain only the compiled application and its direct runtime libraries; they omit package managers, package repositories, text editors, and even command shells (`sh`, `bash`). This drastically shrinks the attack surface and eliminates living-off-the-land tools attackers rely on after code execution.
