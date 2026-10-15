# Day 86: Incident Simulation 1 — Linux & Networking Outages

## 1. Scenario 1: Disk Inode Exhaustion Outage

### Incident Report
- **Alert**: P1 Alert: Server unable to write files. Application logging is failing.
- **Symptom**: `df -h` shows **50GB of free disk space (only 40% used)**, but attempts to create new files fail with:
  `bash: /var/log/app/session.tmp: No space left on device`

### Step-by-Step Triage & Resolution:
1. **Diagnosis**: Check inode utilization:
   ```bash
   df -ih
   # Output shows: /dev/nvme0n1p1  100% Inodes Used!
   ```
2. **Locate the Problematic Directory**:
   Find which directory contains millions of tiny files:
   ```bash
   find / -xdev -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -k1 -nr | head -n 5
   # Output: 4,500,000 /var/spool/clientmqueue
   ```
3. **Remediation**:
   `rm *` will fail with `Argument list too long`. Use `find` with `-delete`:
   ```bash
   find /var/spool/clientmqueue -type f -delete
   ```
4. **Prevention**: Fix cron job mailing misconfiguration and configure logrotate.

---

## 2. Scenario 2: High CPU Load with Zero CPU Utilization (Uninterruptible Disk Sleep)

### Incident Report
- **Alert**: Server load average is **18.0 on a 2-core VM**. Pager triggered for high load.
- **Symptom**: When running `top`, user CPU is 2%, system CPU is 1%, and idle CPU is 97%!

### Step-by-Step Triage & Resolution:
1. **Diagnosis**: Inspect process states:
   ```bash
   ps aux | awk '$8 ~ /D/'
   ```
   Notice dozens of processes in state **`D` (Uninterruptible Sleep / waiting on disk I/O)**!
2. **Inspect Mount Points & NFS**:
   ```bash
   dmesg -T | grep -i nfs
   # Output: "nfs: server nfs-storage.internal not responding, still trying"
   ```
3. **Root Cause**: An external NFS server was disconnected or network partition occurred, freezing all threads attempting to access the mount point.
4. **Remediation**: Force unmount the stale NFS mount:
   ```bash
   sudo umount -f -l /mnt/shared-nfs
   ```
   Load average drops immediately from 18.0 back to 0.15.

---

## 3. Scenario 3: Container "Connection Timed Out" (Firewall Drop)

### Incident Report
- A developer reports that `curl http://db-internal:5432` from inside a container times out after 30 seconds.

### Triage:
1. Check DNS resolution: `dig +short db-internal` (Succeeds: `10.0.10.45`).
2. Test port reachability: `nc -zv 10.0.10.45 5432` (Times out!).
3. Check route table: `ip route show` (Route exists).
4. **Diagnose Security Group / iptables**:
   Inspect AWS Security Group or host `iptables -L -n -v`:
   - Outbound port 5432 or inbound on destination security group was omitted.
   - Authorize port 5432: connection connects within 2ms.

---

## 4. Key Takeaways
- "No space left on device" can mean either full disk blocks (`df -h`) OR exhausted inodes (`df -ih`).
- High load with low CPU indicates processes stuck in uninterruptible sleep state (`D`), waiting on hanging disk or network mounts.
