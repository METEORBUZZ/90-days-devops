# Phase 1: Linux, Networking & Scripting (Days 01–15)

Linux is the bedrock of modern DevOps infrastructure. More than 90% of cloud workloads, containers (Docker/Kubernetes), and CI/CD runners operate on Linux. Master these 15 days to build an unbreakable foundation.

---

## 📅 Daily Learning Index

| Day | Topic | In-Depth Learning Guide | Key Concepts |
| :--- | :--- | :--- | :--- |
| **01** | **Linux Intro & DevOps Workflow** | [Day 01 Guide](./day-01-linux-introduction-devops-workflow.md) | Kernel vs User space, Distros, Terminal vs Shell, DevOps toolchain |
| **02** | **Filesystem Hierarchy & Navigation** | [Day 02 Guide](./day-02-filesystem-hierarchy-file-commands.md) | FHS standards (`/etc`, `/var`, `/proc`), inode basics, absolute vs relative paths |
| **03** | **Text Processing & Streams** | [Day 03 Guide](./day-03-reading-searching-text-processing.md) | Standard Streams (stdin, stdout, stderr), Pipes, `grep`, `awk`, `sed`, `cut` |
| **04** | **Users, Groups & Privilege Management** | [Day 04 Guide](./day-04-users-groups-sudo.md) | `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`, Least Privilege, Service Accounts |
| **05** | **File Permissions & Ownership** | [Day 05 Guide](./day-05-permissions-ownership.md) | Numeric & symbolic `chmod`, `chown`, `umask`, SUID, SGID, Sticky Bit |
| **06** | **Processes & System Resource Management** | [Day 06 Guide](./day-06-processes-resource-usage.md) | PID 1, Process States, Signals (SIGTERM vs SIGKILL), `top`, `htop`, `ps aux`, load average |
| **07** | **systemd & Service Management** | [Day 07 Guide](./day-07-services-systemd.md) | Unit files, Targets, `systemctl` lifecycle, daemon-reload, `journalctl` |
| **08** | **Package Management & Repositories** | [Day 08 Guide](./day-08-packages-software-installation.md) | APT vs DNF/YUM, custom repo signing keys, GPG, dependency resolution |
| **09** | **Disk, Storage & Filesystem Management** | [Day 09 Guide](./day-09-storage-disk-filesystems.md) | `df`, `du`, Inodes exhaustion, Mounts, `/etc/fstab`, LVM fundamentals |
| **10** | **System Logs & Troubleshooting** | [Day 10 Guide](./day-10-logs-troubleshooting-basics.md) | `/var/log` layout, `journalctl` filters, log rotation, root cause debugging |
| **11** | **Networking Fundamentals for DevOps** | [Day 11 Guide](./day-11-networking-fundamentals.md) | TCP/IP, OSI model, Ports, DNS resolution, `ss`, `netstat`, `curl`, `ip`, `traceroute` |
| **12** | **SSH & Secure Remote Access** | [Day 12 Guide](./day-12-ssh-secure-remote-access.md) | Asymmetric cryptography, `~/.ssh/config`, Agent forwarding, sshd hardening |
| **13** | **Bash Scripting Fundamentals** | [Day 13 Guide](./day-13-bash-fundamentals.md) | Shebang (`#!/usr/bin/env bash`), strict mode (`set -euo pipefail`), variables, exit codes |
| **14** | **Control Flow, Loops & Functions in Bash**| [Day 14 Guide](./day-14-bash-conditions-loops-functions.md) | `if/then/else`, `case`, `for/while`, positional arguments, reusable bash functions |
| **15** | **Linux Automation Mini-Project** | [Day 15 Guide](./day-15-linux-automation-mini-project.md) | Production System Health Check & Alerting Daemon script |

---

## 🎯 Phase 1 Goals & Milestones
By the end of Phase 1, you should be able to:
1. Explain how the Linux kernel orchestrates system resources (CPU, Memory, Storage, I/O).
2. Confidently diagnose container and server failures using logs and metric tools.
3. Write production-ready, idempotent Bash scripts adhering to clean coding standards (`set -euo pipefail`).
4. Securely manage identities, SSH keys, file permissions, and firewall/network sockets.
