# Day 02: Filesystem Hierarchy Standard (FHS) & File Navigation

## 1. Theoretical Foundation

### The Linux Filesystem Philosophy: "Everything is a File"
In Unix and Linux, hardware devices, network sockets, named pipes, directories, processes, and standard files are all represented as byte streams via the Virtual Filesystem (VFS) interface.

### Filesystem Hierarchy Standard (FHS) Breakdown
```
/ (Root Directory)
├── bin -> usr/bin          # Essential user command binaries (ls, cp, rm, bash)
├── sbin -> usr/sbin        # Essential system administration binaries (fdisk, reboot, ip)
├── etc/                    # System-wide configuration files (nginx.conf, fstab, ssh/)
├── home/                   # User home directories (/home/ubuntu, /home/ec2-user)
├── root/                   # Superuser (root) home directory
├── var/                    # Variable runtime data:
│   ├── log/                # System and service log files (/var/log/syslog, /var/log/nginx)
│   ├── lib/                # Persistent state data (/var/lib/docker, /var/lib/mysql)
│   └── spool/              # Print / cron queues
├── tmp/                    # Volatile temporary files (often cleared on reboot / mounted in RAM)
├── opt/                    # Optional add-on third-party software packages
├── proc/                   # Virtual pseudo-filesystem exposing Kernel & Process state in RAM
├── sys/                    # Virtual pseudo-filesystem exposing Kernel hardware & driver settings
├── dev/                    # Device nodes (/dev/sda1, /dev/null, /dev/urandom, /dev/tty)
├── mnt/                    # Temporarily mounted filesystems
└── media/                  # Removable media mount points (CD-ROMs, USB drives)
```

### Inodes and File Metadata
Every file on an ext4/xfs filesystem is represented by an **Inode** (Index Node).
An Inode stores:
- File type (regular file, directory, symlink, socket, block device)
- File size (in bytes)
- Owner (UID) and Group (GID)
- Permissions (`rwxr-xr-x`)
- Timestamps: `atime` (access time), `mtime` (content modification time), `ctime` (metadata change time)
- Pointers to data blocks on the disk
- **Note**: The file name and directory path are **NOT** stored inside the inode; they are stored inside directory entry lists mapping names to Inode numbers!

---

## 2. Essential Commands & Navigation Cheat Sheet

### Navigation & Discovery
```bash
# Absolute vs Relative paths
cd /var/log/nginx        # Absolute path (starts from root /)
cd ../../etc             # Relative path (relative to current working directory)

# List with detailed metadata
ls -la                   # Long list, show hidden files (starting with dot)
ls -lh                   # Human-readable file sizes (KB, MB, GB)
ls -lt                   # Sort by modification time (newest first)
ls -lS                   # Sort by file size (largest first)

# Inode inspection
ls -i /etc/passwd        # Show inode number of /etc/passwd
stat /etc/passwd         # Comprehensive inode metadata dump
```

### File & Directory Manipulation
```bash
# Directory creation with parents
mkdir -p /opt/app/releases/v1.2.0

# Copying files and directories preserving timestamps and permissions
cp -p file.txt file_backup.txt      # Preserve mode, ownership, timestamps
cp -r /opt/app /opt/app_backup      # Recursive copy

# Move / Rename
mv /tmp/config.json /etc/app/config.json

# Safe deletion
rm -i critical_file.conf            # Interactive prompt before deletion
rm -rf /tmp/stale_cache             # Recursive force removal (NEVER run on / or /*)

# Creating empty files or updating timestamps
touch /opt/app/ready.flag
```

### Hard Links vs Symbolic (Soft) Links
```bash
# Symbolic link (Pointer to target pathname - like a shortcut)
ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf

# Hard link (Direct reference to same Inode number on the same filesystem)
ln original_file.txt hardlink_file.txt
```

| Property | Soft Link (Symlink) `ln -s` | Hard Link `ln` |
| :--- | :--- | :--- |
| Points to | File path string | Inode number directly |
| Cross-filesystem | Yes | No (must be same filesystem) |
| Target deleted | Becomes broken ("dangling link") | File data remains accessible via remaining hard links |
| Directory support | Yes | No |

---

## 3. DevOps Production Scenarios

### 1. Zero-Downtime Application Deployments via Symlinks
Production deployment tools (like Capistrano, Kubernetes ConfigMap projectors) use atomic symlink swapping:
```bash
# Switch active production traffic to release 2026-10-15
ln -sfn /opt/app/releases/2026-10-15 /opt/app/current
```
Because `ln -sfn` is an atomic system call in the Linux VFS, running processes immediately read the new release without race conditions.

### 2. High Disk Usage Emergencies (`/var/log` or `/tmp`)
When a container host node reaches 100% disk capacity:
```bash
# Find the top 10 largest directories
du -ahx /var | sort -rh | head -n 10

# Check inode usage (if disk has space but errors say 'No space left on device')
df -ih
```

---

## 4. Hands-on Lab: Directory Hierarchy Setup & Symlink Workflow

Run the following workflow:
```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Create a structured release directory
mkdir -p /tmp/devops-lab/{releases/v1.0,releases/v2.0,shared/logs}

# 2. Add sample configurations
echo "APP_VERSION=1.0.0" > /tmp/devops-lab/releases/v1.0/env.conf
echo "APP_VERSION=2.0.0" > /tmp/devops-lab/releases/v2.0/env.conf

# 3. Create current pointer symlink
ln -s /tmp/devops-lab/releases/v1.0 /tmp/devops-lab/current
echo "Active version: $(cat /tmp/devops-lab/current/env.conf)"

# 4. Atomic zero-downtime cutover to v2.0
ln -sfn /tmp/devops-lab/releases/v2.0 /tmp/devops-lab/current
echo "Cutover complete: $(cat /tmp/devops-lab/current/env.conf)"

# 5. Cleanup
rm -rf /tmp/devops-lab
```

---

## 5. Common Production Pitfalls & Troubleshooting

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| `No space left on device` (but `df -h` shows 40% free space) | Inode exhaustion (`df -i` shows 100% used inodes due to millions of tiny files/sessions). | Find and purge stale cache files: `find /tmp -type f -delete`. |
| Broken symlink (red blinking in terminal) | Target file was moved, renamed, or deleted. | Check target with `readlink -f <symlink>`. Update link target. |
| Cannot hardlink across devices | Target file is on a different mount point/EBS volume. | Use a symbolic link (`ln -s`) instead. |

---

## 6. Interview & Review Questions
1. **Why does Linux have a separate `/var` and `/etc` partition standard in production?**
   - *Answer*: `/etc` contains static host configurations that should change rarely and remain intact. `/var` stores rapidly fluctuating runtime state, caches, and logs. Separating them prevents runaway log growth in `/var` from filling up the root partition and crashing the OS.
2. **What is an Inode, and what happens when you delete a file that is still held open by a running process?**
   - *Answer*: The directory entry is unlinked, but the inode's link count does not reach 0 until the process closes its file descriptor. The disk blocks remain allocated until the process terminates (or restarts).
