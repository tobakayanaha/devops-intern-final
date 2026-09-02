#!/usr/bin/env bash
set -euo pipefail

# sysinfo.sh
# Reports basic host environment information: user, hostname, kernel,
# date, disk usage, memory usage, and Docker daemon status.

echo "=== User Info ==="
echo "Current user : $(whoami)"
echo "Effective UID: $(id -u)"
echo

echo "=== Host Info ==="
echo "Hostname      : $(hostname)"
echo "Kernel release: $(uname -r)"
echo

echo "=== Date ==="
echo "System date (ISO-8601): $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo

echo "=== Disk Usage ==="
df -h --output=source,size,used,avail,pcent,target 2>/dev/null || df -h
echo

echo "=== Memory Usage ==="
free -h
echo

echo "=== Docker Daemon Status ==="
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "Docker daemon: running"
    else
        echo "Docker daemon: installed but NOT running"
    fi
else
    echo "Docker daemon: docker command not found"
fi
