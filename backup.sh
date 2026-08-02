#!/usr/bin/env bash
#
# Minecraft world backup with rotation.
#
# Usage:
#   ./backup.sh [storage_path] [destination_dir] [backups_to_keep]
#
# Defaults:
#   storage_path     = /mnt/storage/minecraft
#   destination_dir  = ./backups
#   backups_to_keep  = 7

set -euo pipefail

STORAGE_PATH="${1:-/mnt/storage/minecraft}"
DEST_DIR="${2:-./backups}"
KEEP="${3:-7}"

WORLD_DIR="vanilla"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_NAME="backup-${TIMESTAMP}.tar.gz"

if [ ! -d "${STORAGE_PATH}/${WORLD_DIR}" ]; then
  echo "Error: directory not found: ${STORAGE_PATH}/${WORLD_DIR}" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"

echo "Backing up ${STORAGE_PATH}/${WORLD_DIR} -> ${DEST_DIR}/${ARCHIVE_NAME}"
tar -czf "${DEST_DIR}/${ARCHIVE_NAME}" -C "${STORAGE_PATH}" "${WORLD_DIR}"

echo "Rotation: keeping the ${KEEP} most recent backups"
# shellcheck disable=SC2012
ls -1t "${DEST_DIR}"/backup-*.tar.gz | tail -n +$((KEEP + 1)) | while read -r old_backup; do
  echo "Removing: ${old_backup}"
  rm -f "${old_backup}"
done

echo "Done: $(ls -1 "${DEST_DIR}"/backup-*.tar.gz | wc -l) backup(s) kept"
