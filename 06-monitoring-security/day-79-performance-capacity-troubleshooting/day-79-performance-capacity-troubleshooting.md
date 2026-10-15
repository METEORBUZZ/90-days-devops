# Day 79: Linux Performance Analysis, Bottlenecks & Capacity Planning

## 1. Theoretical Foundation

### Brendan Gregg's USE Method
Developed by legendary Linux performance architect Brendan Gregg, the **USE Method** solves system performance degradations by checking every hardware component for:
- **Utilization**: The percentage of time that a resource was busy servicing work (e.g. CPU 95%, Disk 100%).
- **Saturation**: The degree to which extra work has queued up because the resource is busy (e.g. CPU run-queue length, Disk queue depth).
- **Errors**: Hardware and subsystem error counts (e.g. NIC packet drops, disk retry reads).

---

## 2. The 60-Second Linux Performance Triage Playbook

When an on-call engineer logs into an unresponsive or slow Linux production server, run these 10 commands in sequence:

```bash
# 1. Check system load averages and active users
uptime

# 2. Check kernel ring buffer for hardware/OOM errors
dmesg -T | tail -n 50

# 3. Check virtual memory and CPU run-queue (run every 1 second for 5 counts)
vmstat 1 5
# Watch columns: 'r' (runnable processes), 'b' (processes blocked on I/O), 'si'/'so' (swap activity)

# 4. Check CPU breakdown across all cores
mpstat -P ALL 1 3
# Watch: '%usr' (user app), '%sys' (kernel overhead), '%iowait' (waiting on disk), '%steal' (hypervisor steal!)

# 5. Check real-time process CPU & RAM consumption
top -b -n 1 | head -n 20

# 6. Check detailed disk I/O metrics
iostat -xz 1 3
# Watch: '%util' (disk busy %), 'await' (average I/O latency in ms)

# 7. Check free RAM and cache allocations
free -m

# 8. Check network socket statistics and connection queues
sar -n DEV 1 3
ss -s

# 9. Check TCP retransmissions and network errors
netstat -s | grep -i retrans

# 10. Check disk space and inode saturation
df -h
df -ih
```

---

## 3. Interpreting Bottlenecks

### 1. High CPU `%steal` in Cloud VMs (EC2 / Linode)
- If `mpstat` or `top` shows high `%steal` (e.g. > 15%), your cloud provider's physical hypervisor is starving your virtual machine of CPU cycles because other noisy-neighbor VMs on the same physical host rack are consuming capacity.
- **Solution**: Stop/Start the instance to migrate to another host rack, or upgrade from burstable instances (`t3`) to dedicated instances (`c6i`/`c7g`).

### 2. High Disk `%iowait` (Blocked Processes in `D` State)
- If CPU usage is only 20%, but Load Average is 12.0 and `vmstat` shows high `b` column: processes are blocked waiting on slow disk reads or network storage (NFS/EBS IOPS limit reached).
- **Solution**: Increase EBS volume IOPS or throughput, optimize database queries, or add an in-memory Redis cache.

---

## 4. Interview & Review Questions
1. **What does high `%iowait` indicate on a Linux server?**
   - *Answer*: High `%iowait` indicates that CPU cores are sitting idle because threads are blocked waiting for outstanding disk I/O or network filesystem operations to complete. It points to a storage bottleneck (such as an exhausted EBS IOPS volume, slow rotational disk, or failing NFS mount) rather than a computational CPU bottleneck.
2. **What does high `%steal` mean in cloud compute environments?**
   - *Answer*: `%steal` is the percentage of time that a virtual CPU is ready to execute instructions but is prevented from running because the physical host hypervisor is dedicating compute cycles to another tenant VM sharing the underlying physical CPU hardware.
