#!/usr/bin/env bash
# ==============================================================================
# Resource Reporting Script: Checks system uptime, memory, disk, and Docker stats
# ==============================================================================

set -euo pipefail

echo "=================================================="
echo "HOST SYSTEM & CONTAINER RESOURCE REPORT"
echo "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "=================================================="

echo -e "\n[1] System Uptime and Load Average:"
uptime || true

echo -e "\n[2] Memory Utilization:"
if command -v free > /dev/null 2>&1; then
    free -h
else
    echo "Command 'free' not available on this platform."
fi

echo -e "\n[3] Disk Space Utilization:"
df -h / || df -h .

echo -e "\n[4] Docker Container Resource Statistics (Snapshot):"
if command -v docker > /dev/null 2>&1; then
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" || echo "No active containers running."
fi

echo -e "\n[5] Docker Disk Usage Summary:"
if command -v docker > /dev/null 2>&1; then
    docker system df || true
fi

echo "=================================================="
echo "Resource report generation finished."
echo "=================================================="
