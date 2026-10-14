#!/usr/bin/env bash
set -u
LOG_FILE="${1:-./health-report.log}"
{
  echo "=== Host health report: $(date -Is) ==="
  echo "-- Host --"; hostname
  echo "-- Disk --"; df -h
  echo "-- Memory --"; free -h
  echo "-- Uptime/load --"; uptime
} 2>&1 | tee -a "$LOG_FILE"
# Read-only starter. Test additions in a disposable environment.
