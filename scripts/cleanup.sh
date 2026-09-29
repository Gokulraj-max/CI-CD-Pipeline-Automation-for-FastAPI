#!/usr/bin/env bash

set -euo pipefail

echo "Cleaning unused Docker resources..."

docker container prune -f
docker image prune -f

echo "Cleanup completed."
