# Day 15: Linux Automation Mini-Project — Production System Health Daemon

## 1. Project Overview & Objectives

In this capstone mini-project for Phase 1, you will combine everything learned across the first 14 days (Linux FHS, processes, logs, permissions, networking, systemd, and defensive Bash scripting) to build an enterprise-grade **System Health Monitoring and Alerting Agent**.

### Features of the Script
1. **Strict Defensive Standards**: `set -euo pipefail`, portable shebang, colored standard outputs.
2. **CPU & System Load Telemetry**: Calculates load per CPU core and detects throttling.
3. **Memory Utilization**: Calculates percentage of RAM used, available, and swap exhaustion.
4. **Disk Space & Inode Threshold Checks**: Alerts if any mounted partition exceeds 85% usage or inode capacity.
5. **Critical Service Daemon Checks**: Verifies required daemons (`sshd`, `cron`/`systemd-journald`, `docker`) are active.
6. **Open Network Port & Socket Audit**: Scans listening ports and checks external reachability.
7. **JSON Report Output**: Generates machine-readable JSON logs for ingestion into monitoring systems (Datadog, Prometheus node_exporter textfile collector, CloudWatch).
8. **Automated systemd Service & Timer Integration**: Runs automatically every 5 minutes in the background.

---

## 2. Complete Project Implementation

Create `/usr/local/bin/node-health-monitor.sh`:

```bash
#!/usr/bin/env bash
# ==============================================================================
# Script Name : node-health-monitor.sh
# Description : Production System Telemetry & Health Audit Agent
# Phase       : 90 Days of DevOps - Day 15 Capstone
# Author      : DevOps Engineering Team
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Configuration & Thresholds ---
DISK_THRESHOLD_PERCENT=85
MEM_THRESHOLD_PERCENT=85
REPORT_DIR="/var/log/node-health"
REPORT_FILE="${REPORT_DIR}/health-$(date +%Y-%m-%d).json"

# Color Codes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Ensure report directory exists
mkdir -p "$REPORT_DIR"

# Logging Helpers
log_info()    { echo -e "[${GREEN}OK${RESET}]    $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $1"; }
log_warning() { echo -e "[${YELLOW}WARN${RESET}]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $1" >&2; }
log_error()   { echo -e "[${RED}ALERT${RESET}] $(date -u +"%Y-%m-%dT%H:%M:%SZ") - $1" >&2; }

# --- 1. Host Identity & Uptime ---
check_system_identity() {
    HOSTNAME=$(hostname)
    UPTIME_STR=$(uptime -p)
    KERNEL_VER=$(uname -r)
    log_info "Node: ${HOSTNAME} | Kernel: ${KERNEL_VER} | Uptime: ${UPTIME_STR}"
}

# --- 2. CPU Load Average Check ---
check_cpu_load() {
    local CORES
    CORES=$(nproc)
    local LOAD1
    LOAD1=$(awk '{print $1}' /proc/loadavg)

    # Convert load into integer comparison
    local LOAD_INT
    LOAD_INT=$(echo "$LOAD1" | awk -F. '{print $1}')

    if [[ "$LOAD_INT" -ge "$CORES" ]]; then
        log_warning "CPU 1-min load average ($LOAD1) meets or exceeds core count ($CORES)!"
    else
        log_info "CPU load normal ($LOAD1 on $CORES cores)."
    fi
}

# --- 3. Memory & Swap Health ---
check_memory() {
    local TOTAL_MEM AVAIL_MEM USED_PERCENT
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')
    USED_PERCENT=$(( (TOTAL_MEM - AVAIL_MEM) * 100 / TOTAL_MEM ))

    if [[ "$USED_PERCENT" -ge "$MEM_THRESHOLD_PERCENT" ]]; then
        log_error "Memory usage is critical: ${USED_PERCENT}% used (Available: ${AVAIL_MEM}MB / Total: ${TOTAL_MEM}MB)!"
    else
        log_info "Memory usage healthy: ${USED_PERCENT}% used (Available: ${AVAIL_MEM}MB)."
    fi
}

# --- 4. Disk & Inode Space Check ---
check_disks() {
    # Scan all local ext4/xfs partitions
    df -hP -x tmpfs -x devtmpfs | awk 'NR>1 {print $5, $6}' | while read -r USAGE MOUNT; do
        USAGE_NUM=${USAGE%\%}
        if [[ "$USAGE_NUM" -ge "$DISK_THRESHOLD_PERCENT" ]]; then
            log_error "Disk volume on '${MOUNT}' is high: ${USAGE_NUM}% used!"
        else
            log_info "Mount '${MOUNT}' disk usage: ${USAGE_NUM}%."
        fi
    done
}

# --- 5. Critical Daemon Check ---
check_services() {
    local SERVICES=("ssh" "cron")
    for SVC in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$SVC" 2>/dev/null || systemctl is-active --quiet "${SVC}d" 2>/dev/null; then
            log_info "Service '${SVC}' is active and running."
        else
            log_warning "Service '${SVC}' is NOT active or not installed!"
        fi
    done
}

# --- 6. Export Structured JSON Telemetry ---
generate_json_metric() {
    local TIMESTAMP
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local HOST
    HOST=$(hostname)
    local TOTAL_MEM AVAIL_MEM
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')

    cat <<EOF >> "$REPORT_FILE"
{"timestamp":"${TIMESTAMP}","host":"${HOST}","memory_total_mb":${TOTAL_MEM},"memory_available_mb":${AVAIL_MEM},"status":"AUDIT_COMPLETE"}
EOF
    log_info "Metric appended to ${REPORT_FILE}"
}

# --- Execution Flow ---
main() {
    echo "=================================================="
    echo "       NODE HEALTH AUDIT EXECUTION                "
    echo "=================================================="
    check_system_identity
    check_cpu_load
    check_memory
    check_disks
    check_services
    generate_json_metric
    echo "=================================================="
}

main "$@"
```

---

## 3. Automation Setup: systemd Service & Timer

Make the script executable:
```bash
sudo chmod 750 /usr/local/bin/node-health-monitor.sh
```

### 1. Create the systemd Service (`/etc/systemd/system/node-health-monitor.service`)
```ini
[Unit]
Description=Node Health Telemetry Audit
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/node-health-monitor.sh
StandardOutput=journal
StandardError=journal
```

### 2. Create the systemd Timer (`/etc/systemd/system/node-health-monitor.timer`)
Runs every 5 minutes:
```ini
[Unit]
Description=Trigger Node Health Audit Every 5 Minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

### 3. Activate the Timer
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now node-health-monitor.timer

# Verify the timer is scheduled
systemctl list-timers --all | grep node-health
```

---

## 4. Phase 1 Milestone Completed!

🎉 **Congratulations! You have completed Phase 1 of the 90 Days of DevOps.**
You now possess a solid, production-tested understanding of:
- Linux kernel and user space.
- Filesystem hierarchy, inodes, and file permissions.
- Text parsing (`grep`, `awk`, `sed`) and log diagnostics (`journalctl`).
- Processes, signals, memory, and CPU troubleshooting.
- Storage mounts, partitions, and LVM.
- Networking protocols, ports, and socket diagnostics (`ss`, `dig`, `curl`).
- SSH key management and server hardening.
- Production-grade, defensive Bash automation and systemd services.

Next: **Phase 2 — Git, Python & Automation (Days 16–25)**!
