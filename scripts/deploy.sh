#!/usr/bin/env bash
# ==============================================================================
# Deployment Script with Automated Health Validation and Rollback Support
# ==============================================================================

set -euo pipefail

IMAGE_NAME="${1:-${IMAGE_NAME:-ci-cd-api}}"
IMAGE_TAG="${2:-${IMAGE_TAG:-latest}}"
CONTAINER_NAME="${3:-${CONTAINER_NAME:-ci-cd-api}}"
APP_PORT="${4:-${APP_PORT:-8001}}"
CONTAINER_PORT=8000

FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
BACKUP_CONTAINER="${CONTAINER_NAME}_previous"

echo "=================================================="
echo "Starting Application Deployment"
echo "Target Image     : ${FULL_IMAGE}"
echo "Container Name   : ${CONTAINER_NAME}"
echo "Host Port        : ${APP_PORT}"
echo "=================================================="

# Check if image exists locally
if ! docker image inspect "${FULL_IMAGE}" > /dev/null 2>&1; then
    echo "ERROR: Target image ${FULL_IMAGE} does not exist locally."
    exit 1
fi

# Detect existing running container to preserve for rollback
PREVIOUS_IMAGE=""
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    PREVIOUS_IMAGE=$(docker inspect --format='{{.Config.Image}}' "${CONTAINER_NAME}" || true)
    echo "Found existing container running image: ${PREVIOUS_IMAGE}"

    # Rename current running container as temporary backup
    docker rm -f "${BACKUP_CONTAINER}" > /dev/null 2>&1 || true
    docker rename "${CONTAINER_NAME}" "${BACKUP_CONTAINER}" || true
    docker stop "${BACKUP_CONTAINER}" > /dev/null 2>&1 || true
fi

# Deploy new container
echo "Deploying new container: ${CONTAINER_NAME}..."
if docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${APP_PORT}:${CONTAINER_PORT}" \
    "${FULL_IMAGE}"; then
    echo "Container started. Initiating health validation..."
else
    echo "ERROR: Failed to run container ${FULL_IMAGE}."
    if [ -n "${PREVIOUS_IMAGE}" ]; then
        echo "Rolling back to previous container..."
        docker start "${BACKUP_CONTAINER}" || true
        docker rename "${BACKUP_CONTAINER}" "${CONTAINER_NAME}" || true
    fi
    exit 1
fi

# Validate health endpoint
HEALTH_URL="http://localhost:${APP_PORT}/health"
MAX_ATTEMPTS=15
WAIT_SECONDS=2
HEALTHY=false

echo "Polling health endpoint: ${HEALTH_URL}"
for i in $(seq 1 ${MAX_ATTEMPTS}); do
    if curl --fail --silent --show-error "${HEALTH_URL}" > /dev/null 2>&1; then
        echo "Health check passed on attempt ${i}/${MAX_ATTEMPTS}."
        HEALTHY=true
        break
    fi
    echo "Waiting for application to become healthy (attempt ${i}/${MAX_ATTEMPTS})..."
    sleep ${WAIT_SECONDS}
done

if [ "$HEALTHY" = true ]; then
    echo "Deployment successful! Cleaning up backup container..."
    docker rm -f "${BACKUP_CONTAINER}" > /dev/null 2>&1 || true
    exit 0
else
    echo "ERROR: Health check failed after ${MAX_ATTEMPTS} attempts!"
    echo "Fetching container logs for debugging:"
    docker logs --tail 30 "${CONTAINER_NAME}" || true

    if [ -n "${PREVIOUS_IMAGE}" ]; then
        echo "Initiating automated rollback to previous release (${PREVIOUS_IMAGE})..."
        docker rm -f "${CONTAINER_NAME}" || true
        docker start "${BACKUP_CONTAINER}" || true
        docker rename "${BACKUP_CONTAINER}" "${CONTAINER_NAME}" || true
        echo "Rollback completed. Target container restored."
    else
        echo "No previous release found to roll back to."
    fi
    exit 1
fi
