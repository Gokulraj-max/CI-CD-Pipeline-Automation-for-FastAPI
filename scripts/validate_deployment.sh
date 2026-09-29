#!/usr/bin/env bash
# ==============================================================================
# Deployment Validation Script: Validates container state, port bindings, and API endpoints
# ==============================================================================

set -euo pipefail

CONTAINER_NAME="${1:-ci-cd-api}"
APP_PORT="${2:-8001}"
BASE_URL="http://localhost:${APP_PORT}"

echo "=================================================="
echo "Validating Deployment for: ${CONTAINER_NAME}"
echo "Base URL: ${BASE_URL}"
echo "=================================================="

# 1. Verify container existence and running state
echo "[1/4] Checking container status..."
if ! docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "FAILED: Container ${CONTAINER_NAME} is not running!"
    exit 1
fi
echo "PASSED: Container is actively running."

# 2. Verify port mapping
echo "[2/4] Verifying port mapping..."
PORT_MAPPING=$(docker port "${CONTAINER_NAME}" 2>&1 || true)
echo "Port mappings: ${PORT_MAPPING}"
if echo "${PORT_MAPPING}" | grep -q "${APP_PORT}"; then
    echo "PASSED: Port ${APP_PORT} is mapped correctly."
else
    echo "WARNING: Port ${APP_PORT} not explicitly found in docker port mapping."
fi

# 3. Test Root Endpoint
echo "[3/4] Testing Root Endpoint (${BASE_URL}/)..."
ROOT_RESP=$(curl --silent --show-error --fail "${BASE_URL}/" || true)
if echo "${ROOT_RESP}" | grep -q "CI/CD Pipeline Automation"; then
    echo "PASSED: Root endpoint responded with expected payload."
else
    echo "FAILED: Root endpoint did not return expected message: ${ROOT_RESP}"
    exit 1
fi

# 4. Test Info Endpoint
echo "[4/4] Testing API Info Endpoint (${BASE_URL}/api/v1/info)..."
INFO_RESP=$(curl --silent --show-error --fail "${BASE_URL}/api/v1/info" || true)
if echo "${INFO_RESP}" | grep -q "FastAPI"; then
    echo "PASSED: API Info endpoint verified."
else
    echo "FAILED: API Info endpoint invalid: ${INFO_RESP}"
    exit 1
fi

echo "=================================================="
echo "ALL VALIDATION CHECKS PASSED SUCCESSFULLY!"
echo "=================================================="
