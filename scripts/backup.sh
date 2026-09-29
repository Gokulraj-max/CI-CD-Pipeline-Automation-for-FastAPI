#!/usr/bin/env bash
# ==============================================================================
# Backup Script: Saves deployment configuration, image tags, and container metadata
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${1:-./backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TARGET_DIR="${BACKUP_DIR}/backup_${TIMESTAMP}"
CONTAINER_NAME="${2:-ci-cd-api}"

echo "Creating deployment backup directory: ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

# Backup Docker configuration and container metadata if container exists
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "Backing up container metadata for: ${CONTAINER_NAME}"
    docker inspect "${CONTAINER_NAME}" > "${TARGET_DIR}/container_inspect_${CONTAINER_NAME}.json"
    docker port "${CONTAINER_NAME}" > "${TARGET_DIR}/container_ports.txt" || true
fi

# Backup environment files if present
if [ -f .env ]; then
    echo "Backing up .env file..."
    cp .env "${TARGET_DIR}/.env.backup"
fi

# Record git commit hash if available
if command -v git > /dev/null 2>&1 && git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Backing up git state..."
    git rev-parse HEAD > "${TARGET_DIR}/git_commit_hash.txt"
    git status --short > "${TARGET_DIR}/git_status.txt"
fi

# Backup Docker image list for this app
docker images --filter=reference='ci-cd-api*' > "${TARGET_DIR}/docker_images.txt" 2>&1 || true

echo "Backup completed successfully at: ${TARGET_DIR}"
