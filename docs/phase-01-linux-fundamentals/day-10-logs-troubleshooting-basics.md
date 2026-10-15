# Day 10: System Logging, Log Rotation & Evidence-Based Troubleshooting

## 1. Theoretical Foundation

### The Linux Logging Architecture
Logs are the primary diagnostic telemetry of any Linux server, container, or cloud VM.
Historically, syslog daemons (`rsyslogd`, `syslog-ng`) listened on `/dev/log` and wrote plain text files into `/var/log`.
In modern Linux distributions, **`systemd-journald`** acts as the central ingestion layer:
```
  [ Applications ]      [ Kernel Messages (dmesg) ]      [ Services (stdout/stderr) ]
         \                         |                         /
          \                        |                        /
           v                       v                       v
                          systemd-journald
                      (Structured Binary Log in RAM/Disk)
                             /             \
                            /               \
                           v                 v
                     journalctl         rsyslogd (optional)
                     (CLI tool)              |
                                             v
                                  /var/log/syslog (Plain text)
```

### Key Log Files in `/var/log`
- `/var/log/syslog` or `/var/log/messages`: General system operating system activity and non-auth daemons.
- `/var/log/auth.log` or `/var/log/secure`: SSH authentication attempts, sudo elevations, user login successes and failures.
- `/var/log/dmesg` or `dmesg`: Kernel ring buffer (hardware detection, driver initialization, Out-Of-Memory OOM killer kills).
- `/var/log/nginx/` or `/var/log/httpd/`: Web server access and error logs.
- `/var/log/dpkg.log` or `/var/log/dnf.log`: Software package installation and upgrade audit trail.

### Log Priority Levels (RFC 5424)
0. **Emergency (`emerg`)**: System is unusable.
1. **Alert (`alert`)**: Action must be taken immediately.
2. **Critical (`crit`)**: Critical hardware or subsystem condition.
3. **Error (`err`)**: Error conditions (service failed).
4. **Warning (`warning`)**: Warning conditions.
5. **Notice (`notice`)**: Normal but significant event.
6. **Informational (`info`)**: Informational messages.
7. **Debug (`debug`)**: Detailed debug telemetry.

---

## 2. Advanced `journalctl` & `dmesg` Commands

### Filtering `journalctl` Like a Pro
```bash
# 1. Show logs for current boot session only
journalctl -b

# 2. Show logs from previous boot (invaluable for analyzing unexpected reboot/kernel panic)
journalctl -b -1

# 3. Filter by priority (errors and worse)
journalctl -p err..emerg

# 4. Filter by specific systemd service unit
journalctl -u docker.service --since "30 minutes ago"

# 5. Filter by PID
journalctl _PID=1420

# 6. View disk space consumed by journal logs and clean up
journalctl --disk-usage
sudo journalctl --vacuum-size=500M     # Retain only 500MB
sudo journalctl --vacuum-time=14d       # Retain only last 14 days
```

### Inspecting Kernel Events: `dmesg`
```bash
# Human-readable timestamps and color output
dmesg -T --color=always | less -R

# Check if the Linux Out-Of-Memory (OOM) Killer terminated your process
dmesg -T | grep -i -E "(oom|out of memory|killed process)"
```

---

## 3. Log Rotation with `logrotate`

Without log rotation, plain text logs eventually consume 100% of server disk space.
`logrotate` is run daily via cron or systemd timer. Its rules reside in `/etc/logrotate.conf` and `/etc/logrotate.d/`.

### Anatomy of a Production Logrotate File (`/etc/logrotate.d/myapp`)
```text
/var/log/myapp/*.log {
    daily                   # Rotate every day
    rotate 14               # Keep 14 days of historical logs before deleting oldest
    missingok               # Don't error out if log file is missing
    notifempty              # Don't rotate empty files
    compress                # Compress historical logs with gzip (.gz)
    delaycompress           # Don't compress most recent rotation until next cycle
    dateext                 # Append ISO date instead of simple .1, .2
    create 0640 appuser adm # Permissions for newly created log file
    sharedscripts
    postrotate
        # Signal application to reopen its log file descriptor
        /bin/systemctl reload myapp.service > /dev/null 2>&1 || true
    endscript
}
```

**Testing logrotate configurations**:
```bash
# Perform dry-run (simulates rotation without altering disk)
sudo logrotate -d /etc/logrotate.d/myapp

# Force immediate rotation
sudo logrotate -f /etc/logrotate.d/myapp
```

---

## 4. Evidence-Based DevOps Troubleshooting Methodology

When responding to an incident or pager alert, follow the **OODA Loop (Observe, Orient, Decide, Act)**:
1. **Observe (Gather Evidence)**:
   - Check host resource health: `uptime`, `free -m`, `df -h`.
   - Check service status: `systemctl status <service>`.
   - Check recent logs: `journalctl -u <service> -n 50 --no-pager`.
2. **Orient (Isolate Root Cause)**:
   - Did the process crash due to memory (check `dmesg \| grep oom`)?
   - Did it fail to bind a network port (check `ss -tulpn`)?
   - Did a configuration change break it (check `git diff` or `/var/log/dpkg.log`)?
3. **Decide (Formulate Minimal Safe Action)**:
   - Do not guess or execute destructive commands. Formulate a targeted fix.
4. **Act & Verify**:
   - Apply remediation, reload service, verify HTTP health check (`curl -Iv http://localhost:8080/health`), and document findings.

---

## 5. Interview & Review Questions
1. **What happens during an OOM (Out Of Memory) event in Linux? How do you find which process was killed?**
   - *Answer*: When the system exhausts physical RAM and swap space, the kernel invokes the `oom_killer`. It calculates badness scores based on memory consumption and terminates the highest-scoring process to preserve system stability. You can detect this immediately using `dmesg -T | grep -i oom` or `journalctl -k | grep -i oom`.
2. **Why is `sharedscripts` and `postrotate` used in `logrotate`?**
   - *Answer*: `sharedscripts` ensures that the `postrotate` script runs only once after all matching files in the glob pattern have rotated, rather than once per file. The `postrotate` block typically instructs the running daemon (like Nginx) to reload and reopen its file descriptors so it writes to the newly created log file instead of continuing to write to the rotated/compressed file.
