# Day 09: Storage, Filesystems, Mounts & Disk Management

## 1. Theoretical Foundation

### Storage Stack in Linux
```
+-------------------------------------------------------------+
|                     User Application                        |
+-------------------------------------------------------------+
|                 Virtual Filesystem (VFS)                    |
+-------------------------------------------------------------+
|         Filesystem Type (ext4, xfs, btrfs, nfs)             |
+-------------------------------------------------------------+
|         Logical Volume Manager (LVM - Optional)             |
|         [ Logical Volumes (LV) ]                            |
|         [ Volume Groups (VG) ]                              |
|         [ Physical Volumes (PV) ]                           |
+-------------------------------------------------------------+
|         Block Devices / Partitions (/dev/sda1, /dev/nvme0n1p1)|
+-------------------------------------------------------------+
|         Physical Storage Hardware (SSD, NVMe, Cloud EBS)    |
+-------------------------------------------------------------+
```

### ext4 vs. XFS in Production
- **ext4**: The venerable default for Ubuntu/Debian. Supports online resizing (growing), file undeletion tools, and high compatibility.
- **XFS**: High-performance, 64-bit journaling filesystem (default on RHEL/CentOS). Highly optimized for parallel I/O and large files. *Note: XFS filesystems can be grown online, but cannot be shrunk!*

---

## 2. Disk & Filesystem Inspection Commands

### `df` (Disk Free)
Displays filesystem disk space usage:
```bash
# Human readable sizes (GB, MB)
df -h

# Check Inode usage (CRITICAL for mail/cache servers)
df -ih

# Filter by filesystem type (exclude temporary ramfs/tmpfs)
df -h -x tmpfs -x devtmpfs
```

### `du` (Disk Usage)
Measures file and directory space consumption:
```bash
# Find disk usage of immediate subdirectories
du -h --max-depth=1 /var

# Find the top 10 largest files or directories
du -ah /var/log | sort -rh | head -n 10
```

### `lsblk` and `fdisk` (Block Devices & Partitions)
```bash
# List all block storage devices and mount trees
lsblk -f

# View partition table details for a disk
sudo fdisk -l /dev/sda
```

---

## 3. Formatting, Mounting & `/etc/fstab`

### Formatting a Partition
```bash
# Format as ext4
sudo mkfs.ext4 -L "DATA_DISK" /dev/sdb1

# Format as XFS
sudo mkfs.xfs -L "DATA_DISK" /dev/sdb1
```

### Mounting & Unmounting
```bash
# Create mount point directory
sudo mkdir -p /mnt/data

# Mount filesystem
sudo mount /dev/sdb1 /mnt/data

# Unmount filesystem
sudo umount /mnt/data
# If device is busy:
# lsof +D /mnt/data    (find which process holds files open)
```

### Persistent Mounts: `/etc/fstab`
To ensure a disk mounts automatically upon system boot, add an entry to `/etc/fstab`.
**Best Practice**: Always use device **UUID** (Universally Unique Identifier) rather than `/dev/sdb1`, because device letters can change after hardware reboot!

```bash
# 1. Get UUID of partition
sudo blkid /dev/sdb1
# Output: /dev/sdb1: UUID="3c4456e2-1234-4567-89ab-cdef01234567" TYPE="ext4"

# 2. Add entry to /etc/fstab:
# <filesystem UUID>                          <mount point>  <type>  <options>       <dump> <pass>
UUID=3c4456e2-1234-4567-89ab-cdef01234567  /mnt/data      ext4    defaults,nofail 0      2
```
- `defaults`: Enables `rw`, `suid`, `dev`, `exec`, `auto`, `nouser`, `async`.
- `nofail`: Prevents boot hang if an external cloud EBS or NFS disk is disconnected.
- `<pass>`: `1` for root `/` filesystem fsck check; `2` for other partitions; `0` to disable boot check.

**Verification command**:
```bash
# Test /etc/fstab without rebooting!
sudo mount -a
```
*Always run `mount -a` after editing `/etc/fstab`. If there is a syntax error, it will warn you immediately. If you reboot with a corrupt `/etc/fstab`, the machine enters emergency mode!*

---

## 4. DevOps Production Scenarios

### 1. Growing an EBS Volume on AWS EC2 Without Downtime
When an AWS EBS volume size is modified in AWS Console from 20GB to 50GB:
```bash
# 1. Verify OS sees the larger underlying block device
lsblk

# 2. Grow the partition table (e.g. partition 1 on nvme0n1)
sudo growpart /dev/nvme0n1 1

# 3. Expand the filesystem online:
# If ext4:
sudo resize2fs /dev/nvme0n1p1

# If XFS:
sudo xfs_growfs /
```
The application experiences zero seconds of downtime!

---

## 5. Common Production Pitfalls

| Mistake | Consequence | Safe Fix |
| :--- | :--- | :--- |
| Deleting an open log file with `rm access.log` | `df -h` still shows disk full because the running process keeps the open inode unlinked. | Truncate the file instead: `> /var/log/nginx/access.log` or restart the service. |
| Missing `nofail` on non-critical cloud disks in `/etc/fstab` | EC2 instance fails health checks and gets stuck in Emergency Mode during automated reboot. | Always add `,nofail` to cloud data disks in `/etc/fstab`. |
| Inode exhaustion | Disk shows gigabytes free, but new file creation fails with `No space left on device`. | Find directories with millions of files: `find / -xdev -printf '%h\n' \| sort \| uniq -c \| sort -k 1 -n`. |

---

## 6. Interview & Review Questions
1. **You deleted a 50GB log file using `rm`, but `df -h` still shows the disk at 100% full. Why, and how do you resolve it?**
   - *Answer*: When a file is unlinked with `rm`, its directory pointer is removed, but if a running process still holds an open file descriptor to it, the kernel does not release the allocated disk blocks. Run `lsof +L1` or `lsof | grep deleted` to find the process PID. Once you reload/restart that process, or truncate it via `/proc/<PID>/fd/<FD>`, the kernel frees the blocks.
2. **What is the difference between `df -h` and `du -sh`? Why can their outputs differ?**
   - *Answer*: `df` queries filesystem superblock metadata directly to see total allocated blocks (fast, kernel-level). `du` traverses the directory tree summing individual file sizes (slower). They differ when deleted files are still held open by processes, when sparse files exist, or when files are hidden underneath active mount points.
