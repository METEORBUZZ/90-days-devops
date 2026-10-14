#!/usr/bin/env bash
set -euo pipefail
echo "=== Day 1: DevOps System Report ==="
printf 'User: '; whoami
printf 'Hostname: '; hostname
printf 'Date: '; date
printf 'Working directory: '; pwd
