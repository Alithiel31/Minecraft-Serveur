#!/usr/bin/env bash
#
# Sauvegarde du monde Minecraft avec rotation.
#
# Usage :
#   ./backup.sh [chemin_stockage] [dossier_destination] [nb_backups_a_garder]
#
# Par défaut :
#   chemin_stockage      = /mnt/storage/minecraft
#   dossier_destination  = ./backups
#   nb_backups_a_garder  = 7

set -euo pipefail

STORAGE_PATH="${1:-/mnt/storage/minecraft}"
DEST_DIR="${2:-./backups}"
KEEP="${3:-7}"

WORLD_DIR="vanilla"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_NAME="backup-${TIMESTAMP}.tar.gz"

if [ ! -d "${STORAGE_PATH}/${WORLD_DIR}" ]; then
  echo "Erreur : dossier introuvable : ${STORAGE_PATH}/${WORLD_DIR}" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"

echo "Sauvegarde de ${STORAGE_PATH}/${WORLD_DIR} -> ${DEST_DIR}/${ARCHIVE_NAME}"
tar -czf "${DEST_DIR}/${ARCHIVE_NAME}" -C "${STORAGE_PATH}" "${WORLD_DIR}"

echo "Rotation : conservation des ${KEEP} sauvegardes les plus récentes"
# shellcheck disable=SC2012
ls -1t "${DEST_DIR}"/backup-*.tar.gz | tail -n +$((KEEP + 1)) | while read -r old_backup; do
  echo "Suppression : ${old_backup}"
  rm -f "${old_backup}"
done

echo "Terminé : $(ls -1 "${DEST_DIR}"/backup-*.tar.gz | wc -l) sauvegarde(s) conservée(s)"
