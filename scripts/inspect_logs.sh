#!/usr/bin/env bash
# ==============================================================================
# Log Inspection Script: Collects container logs with timestamps and error filtering
# ==============================================================================

set -euo pipefail

CONTAINER_NAME="${1:-ci-cd-api}"
LINES="${2:-100}"
LOG_DIR="./logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTFILE="${LOG_DIR}/${CONTAINER_NAME}_logs_${TIMESTAMP}.log"

mkdir -p "${LOG_DIR}"

echo "=================================================="
echo "Inspecting logs for container: ${CONTAINER_NAME}"
echo "Lines to fetch: ${LINES}"
echo "=================================================="

if ! docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "ERROR: Container ${CONTAINER_NAME} does not exist."
    exit 1
fi

echo "--- Recent Container Logs (Timestamps included) ---"
docker logs --timestamps --tail "${LINES}" "${CONTAINER_NAME}" | tee "${OUTFILE}"

echo -e "\n--- Error / Warning Scan ---"
grep -Ei "error|exception|critical|traceback|warning" "${OUTFILE}" || echo "No obvious errors or warnings found."

echo -e "\nLog inspection complete. Saved to: ${OUTFILE}"
