#!/usr/bin/env bash

set -euo pipefail

URL="${1:-http://localhost:8001/health}"

echo "Checking application health at: $URL"

if curl --fail --silent --show-error "$URL"; then
    echo -e "\nApplication is healthy"
    exit 0
else
    echo -e "\nApplication health check failed"
    exit 1
fi
