# Day 07: systemd Architecture & Service Management

## 1. Theoretical Foundation

### What is `systemd`?
`systemd` is the standard init system and service manager for modern Linux operating systems (replacing SysVinit and Upstart).
Key Features:
- Executes as **PID 1**.
- Parallelized boot sequence using socket and D-Bus activation.
- Manages services, mount points, timers (cron replacement), sockets, and devices using **Units**.
- Tracks process groups using Linux **cgroups** (Control Groups), preventing orphaned child processes.

### Unit Types in `systemd`
- `.service`: Daemons and applications (e.g. `docker.service`, `nginx.service`).
- `.target`: Grouping mechanism representing boot states (e.g. `multi-user.target` for multi-user CLI mode, `graphical.target` for desktop GUI).
- `.timer`: Scheduled jobs triggered on calendar rules or relative timestamps (modern cron alternative).
- `.socket`: IPC or network sockets that activate services on demand.
- `.mount`: Filesystem mount points.

---

## 2. Managing Services with `systemctl`

```bash
# Service Lifecycle Control
sudo systemctl start nginx         # Start service now
sudo systemctl stop nginx          # Stop service now
sudo systemctl restart nginx       # Restart service (stop + start)
sudo systemctl reload nginx        # Reload configuration without dropping connections (SIGHUP)
sudo systemctl status nginx        # Inspect active state, PID, memory, recent logs

# Boot Persistence
sudo systemctl enable nginx        # Auto-start on system boot (creates symlink in target directory)
sudo systemctl disable nginx       # Disable auto-start on boot
sudo systemctl is-active nginx     # Programmatic check (returns 0 if active, non-zero if inactive)
sudo systemctl is-enabled nginx    # Programmatic check for boot status

# Masking (prevent accidental starting)
sudo systemctl mask nginx          # Symlinks service to /dev/null
sudo systemctl unmask nginx
```

---

## 3. Anatomy of a Production `.service` Unit File

Custom systemd service files are placed in `/etc/systemd/system/myapp.service`:

```ini
[Unit]
Description=Production Go API Microservice
Documentation=https://docs.mycompany.internal/api
# Wait until network stack and PostgreSQL service are ready before starting
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=appuser
Group=appgroup
WorkingDirectory=/opt/myapp

# Binary execution command (must be an absolute path!)
ExecStart=/opt/myapp/bin/api-server --config=/etc/myapp/config.yaml
ExecReload=/bin/kill -HUP $MAINPID

# Auto-recovery: Restart policy if application crashes or gets killed
Restart=always
RestartSec=5s

# Security Hardening Directives
ProtectSystem=strict
ProtectHome=true
NoNewPrivileges=true
PrivateTmp=true

# Resource Limits via cgroups
LimitNOFILE=65535
MemoryMax=512M
CPUQuota=100%

# Environment variables
Environment="PORT=8080"
EnvironmentFile=/etc/myapp/production.env

[Install]
# Hook into standard multi-user boot runlevel
WantedBy=multi-user.target
```

### Reloading systemd Daemon
Whenever you create or modify a `.service` file:
```bash
sudo systemctl daemon-reload
sudo systemctl restart myapp
```
*If you forget `daemon-reload`, systemd executes the cached in-memory definition!*

---

## 4. Viewing Service Logs with `journalctl`

`journalctl` queries the unified binary logging system managed by `systemd-journald`:

```bash
# View all logs for a specific service unit
journalctl -u myapp.service

# Live follow logs in real-time (like tail -f)
journalctl -u myapp.service -f

# Filter by time range
journalctl -u myapp.service --since "1 hour ago"
journalctl -u myapp.service --since "2026-10-15 00:00:00" --until "2026-10-15 02:00:00"

# Show only errors and critical alerts
journalctl -u myapp.service -p err

# Don't truncate long lines and open in pager
journalctl -u myapp.service --no-pager -n 100
```

---

## 5. DevOps Production Scenarios

### 1. Migrating Cron Jobs to systemd Timers
systemd timers provide millisecond precision, explicit dependencies, and unified `journalctl` logging:
1. Create `/etc/systemd/system/backup.service` (defines the command).
2. Create `/etc/systemd/system/backup.timer`:
```ini
[Unit]
Description=Run DB Backup Daily at 2 AM

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```
Enable and start the timer:
```bash
sudo systemctl enable --now backup.timer
systemctl list-timers
```

---

## 6. Interview & Review Questions
1. **What is the difference between `systemctl reload` and `systemctl restart`?**
   - *Answer*: `restart` terminates the running process and creates a fresh instance, resulting in a brief service interruption and dropped active connections. `reload` sends a signal (typically `SIGHUP`) instructing the running daemon to re-read its configuration files on the fly without terminating active worker threads or dropping connections.
2. **Why must `systemctl daemon-reload` be executed after modifying a unit file?**
   - *Answer*: `systemd` parses and compiles unit files into an internal in-memory dependency graph upon boot. Modifying a unit file on disk does not update the active in-memory representation until `daemon-reload` instructs systemd to re-scan and rebuild its dependency tree.
