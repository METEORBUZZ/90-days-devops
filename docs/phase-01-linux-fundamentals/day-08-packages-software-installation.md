# Day 08: Linux Package Management & Software Installation

## 1. Theoretical Foundation

### Package Managers in Linux
In Linux, software is distributed as pre-compiled archive packages containing binaries, default configurations, metadata, and dependencies.
- **Low-level package tools**: `dpkg` (Debian/Ubuntu) and `rpm` (RedHat/Fedora). They install single `.deb` or `.rpm` files, but **do not** automatically fetch missing dependencies over the internet.
- **High-level package managers**: `apt` (Advanced Package Tool) and `dnf` / `yum` (Dandified YUM). They query remote repositories, resolve complex dependency trees, download required shared libraries, and install packages atomically.

### Package Manager Comparison Matrix

| Distribution | Low-Level Tool | High-Level Tool | Configuration / Repo Paths |
| :--- | :--- | :--- | :--- |
| **Debian / Ubuntu** | `dpkg` | `apt` / `apt-get` | `/etc/apt/sources.list`, `/etc/apt/sources.list.d/`, `/etc/apt/keyrings/` |
| **RHEL / Rocky / CentOS** | `rpm` | `dnf` (or `yum`) | `/etc/yum.repos.d/` |
| **Alpine Linux** | `apk` | `apk` | `/etc/apk/repositories` |

---

## 2. Command Reference

### Debian / Ubuntu (`apt`)
```bash
# Update local repository metadata index (does NOT upgrade installed software)
sudo apt update

# Upgrade all installed packages to latest safe versions
sudo apt upgrade -y

# Install packages non-interactively (standard for Dockerfiles and CI/CD)
sudo DEBIAN_FRONTEND=noninteractive apt install -y curl jq htop

# Remove a package but keep configuration files
sudo apt remove nginx

# Purge a package AND delete all its configuration files
sudo apt purge nginx

# Remove orphaned dependencies that are no longer needed
sudo apt autoremove --purge -y

# Search for a package
apt search prometheus-node-exporter

# Check which package owns a specific file on the filesystem
dpkg -S /usr/bin/curl
```

### RHEL / Rocky / CentOS / Amazon Linux (`dnf` / `yum`)
```bash
# Update repository metadata and upgrade installed packages
sudo dnf check-update
sudo dnf upgrade -y

# Install package
sudo dnf install -y nginx

# Query information about a package
dnf info nginx

# Find which package provides a specific binary
dnf provides */htop
```

---

## 3. DevOps Production Practice: Adding Secure Third-Party Repositories

In modern DevOps (e.g. installing Docker, HashiCorp Terraform, or Kubernetes tools), third-party repositories must be cryptographically verified using GPG keys.

### Modern Debian/Ubuntu GPG Keyring Standard (Avoiding deprecated `apt-key`)
```bash
# 1. Install prerequisites
sudo apt update && sudo apt install -y ca-certificates curl gnupg

# 2. Create secure keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# 3. Download and de-armor official GPG key into dedicated keyring
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Add signed repository entry pointing strictly to the dedicated keyring
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Update index and install validated package
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

---

## 4. Best Practices in Dockerfiles and Automation

### 1. Combine `update`, `install`, and cleanup in a single RUN layer
In Docker, each layer increases image size. Uncached package lists waste space:
```dockerfile
# Good DevOps Practice
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    jq \
 && rm -rf /var/lib/apt/lists/*
```
- `--no-install-recommends`: Skips optional suggested packages, keeping the image minimal.
- `rm -rf /var/lib/apt/lists/*`: Cleans up cached repository index files, drastically reducing Docker image size.

### 2. Version Pinning for Reproducible Builds
```bash
# Ubuntu/Debian
sudo apt install -y nginx=1.18.0-0ubuntu1.4

# Prevent automatic updates from breaking tested configurations
sudo apt-mark hold nginx
# To unhold:
# sudo apt-mark unhold nginx
```

---

## 5. Common Production Pitfalls

| Problem | Root Cause | Solution |
| :--- | :--- | :--- |
| `E: Could not get lock /var/lib/dpkg/lock-frontend` | Another process (e.g. background `unattended-upgrades`) holds the dpkg lock. | Check who is using it: `lsof /var/lib/dpkg/lock-frontend`. Wait for background update to finish before running apt. |
| Interactive prompt blocks CI/CD (`Configuring tzdata...`) | Package installer awaits user keyboard input in non-interactive runner. | Export `DEBIAN_FRONTEND=noninteractive` before running `apt install`. |
| Outdated repository index (`404 Not Found` during install) | Package versions changed on remote mirror. | Always run `apt update` immediately before `apt install`. |

---

## 6. Interview & Review Questions
1. **Why was `apt-key add` deprecated in modern Debian/Ubuntu systems?**
   - *Answer*: `apt-key add` added all third-party GPG keys to a single global trusted keyring (`/etc/apt/trusted.gpg`). This allowed any third-party repository to sign and distribute packages that could impersonate and overwrite official core system packages. Modern practice uses `/etc/apt/keyrings/` with `signed-by`, restricting trust strictly to that specific vendor's repository.
2. **What does `apt-get clean` and `rm -rf /var/lib/apt/lists/*` do, and why is it standard in Docker?**
   - *Answer*: `apt-get clean` deletes downloaded `.deb` package archives stored in `/var/cache/apt/archives/`. Removing `/var/lib/apt/lists/*` removes cached repository metadata. In Docker containers, these files are unnecessary at runtime and purging them reduces image footprint by dozens to hundreds of megabytes.
