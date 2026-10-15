# Day 01: Linux Introduction & DevOps Workflow

## 1. Theoretical Foundation

### What is Linux and Why Does DevOps Depend on It?
Linux is an open-source, monolithic Unix-like operating system kernel created by Linus Torvalds in 1991. In modern cloud architecture:
- **Containers**: Docker containers and Kubernetes Pods share the host Linux kernel (using Linux Namespaces and Control Groups / cgroups).
- **Cloud Infrastructure**: AWS EC2, GCP Compute Engine, and Azure VMs predominantly run Linux distributions (Ubuntu, Amazon Linux 2023, RHEL, Debian).
- **Automation & CI/CD**: GitHub Actions runners, GitLab CI executors, and Jenkins agents execute workloads natively on Linux shells.

```
+-------------------------------------------------------------+
|                     User Space                              |
|  [Applications] [Web Servers (Nginx)] [Containers (Docker)] |
|  [Shell (bash/zsh)] [System Utilities (coreutils, curl)]   |
+-------------------------------------------------------------+
|                      System Call Interface                  |
+-------------------------------------------------------------+
|                     Kernel Space                            |
|  [Process Scheduler] [Memory Manager] [VFS / Filesystems]   |
|  [Network Stack (TCP/IP)] [Device Drivers]                  |
+-------------------------------------------------------------+
|                     Hardware Architecture                   |
|  [CPU] [RAM] [Network Interface Card (NIC)] [Disks / NVMe]  |
+-------------------------------------------------------------+
```

### Kernel Space vs. User Space
1. **Kernel Space (`Ring 0`)**: The core privileged layer with direct, unrestricted access to physical hardware (CPU registers, physical memory addresses, peripherals).
2. **User Space (`Ring 3`)**: Isolated sandbox where user applications, daemons, and shells execute. Applications must invoke **System Calls** (e.g., `sys_read`, `sys_write`, `sys_fork`, `sys_clone`) to ask the kernel for privileged operations.

### Major Linux Distributions in Production
- **Debian Family (Debian, Ubuntu)**: Uses `apt`/`dpkg`. Ubiquitous in cloud VM images and container base images (`ubuntu:22.04`, `debian:bookworm-slim`).
- **Red Hat Family (RHEL, Rocky Linux, AlmaLinux, CentOS Stream, Fedora)**: Uses `dnf`/`rpm`. Common in enterprise financial, banking, and government systems.
- **Alpine Linux**: Ultra-lightweight distro (~5MB base image) built with `musl libc` and `BusyBox`. Frequently used for lean microservices containers.
- **Amazon Linux 2023 (AL2023)**: Optimized by AWS for AWS EC2 instances and ECS container hosts with tight AWS CLI/SSM integration.

---

## 2. Terminal, Shell & Environment

### Shell vs. Terminal vs. Console
- **Terminal (Emulator)**: The GUI window or text interface that captures keyboard inputs and displays text output (e.g., iTerm2, Alacritty, GNOME Terminal, Windows Terminal).
- **Shell**: The command-line interpreter that reads your textual input, parses it, executes binaries, and handles input/output redirection (e.g., `bash`, `zsh`, `sh`, `fish`).

### Essential Day 1 Discovery Commands
```bash
# 1. Identify the current user and UID/GID
whoami
id

# 2. Check current working directory
pwd

# 3. Kernel and OS details
uname -a
cat /etc/os-release

# 4. Hostname and network identity
hostname
hostname -I

# 5. System time, timezone, and uptime
date
timedatectl
uptime -p
```

---

## 3. Real-World DevOps Use Cases

### Why DevOps Engineers Run System Discovery Commands
1. **CI/CD Pipeline Validation**: Build runners dynamically execute `uname -m` to determine whether to build `x86_64` (AMD64) or `aarch64` (ARM64/Graviton) container images.
2. **Container Debugging**: When entering an unknown scratch or slim container (`docker exec -it <container> sh`), running `whoami`, `id`, and `cat /etc/os-release` tells you immediately if you are running as root or a restricted service account, and which package manager is available.
3. **Provisioning Automation (Cloud-init)**: First-boot scripts on AWS EC2 or GCP Compute Engine use `hostname` and `date` to record boot audit logs and register the host into inventory systems (Consul, Route53, Ansible).

---

## 4. Hands-on Lab: System Baseline Audit

Create a script `system_info.sh` to capture node telemetry for deployment validation:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "          HOST BASELINE SYSTEM AUDIT              "
echo "=================================================="
echo "Timestamp:        $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Active User:      $(whoami) (UID: $(id -u), GID: $(id -g))"
echo "Hostname:         $(hostname)"
echo "Kernel Release:   $(uname -r)"
echo "Architecture:     $(uname -m)"
echo "OS Name:          $(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || uname -s)"
echo "System Uptime:    $(uptime -p)"
echo "Working Dir:      $(pwd)"
echo "=================================================="
```

Make it executable and execute:
```bash
chmod +x system_info.sh
./system_info.sh
```

---

## 5. Common Production Pitfalls & Troubleshooting

| Symptom / Error | Root Cause | Remediation |
| :--- | :--- | :--- |
| `bash: ./script.sh: Permission denied` | The script file lacks execute (`+x`) permissions. | Run `chmod +x script.sh` or execute with `bash ./script.sh`. |
| `bash: ./script.sh: /bin/bash^M: bad interpreter` | Windows CRLF line endings in the script file. | Convert line endings to Unix format: `dos2unix script.sh` or `sed -i 's/\r$//' script.sh`. |
| `standard_init_linux.go: exec user process caused: no such file or directory` | Container built on ARM (e.g. Apple Silicon M1/M2) deployed to x86_64 Linux host without multi-arch build. | Build with `docker buildx build --platform linux/amd64 ...`. |

---

## 6. Key Takeaways & Interview Prep

### High-Yield Questions
1. **Explain the difference between User Space and Kernel Space. Why is this distinction crucial for container security?**
   - *Answer*: Kernel space has unrestricted hardware access; user space is protected and sandboxed. Containers share the host kernel. If a container process escapes user space or exploits a kernel vulnerability, it can compromise the entire host node and all co-located containers.
2. **What happens under the hood when a command like `ls` is typed into bash?**
   - *Answer*: Bash parses the string, checks aliases, keywords, and builtins. It then searches the directories listed in the `$PATH` environment variable. Once located, it calls `fork()` to create a child process and `execve()` to replace the child image with `/bin/ls`, which uses system calls like `getdents64` to read directory contents.
