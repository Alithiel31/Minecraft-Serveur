# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

## [Unreleased]

### À faire

- Réactiver l'autre service concerné par l'incident de contention mémoire, avec un `mem_limit` propre pour éviter toute nouvelle contention avec `mc-vanilla`
- Confirmer/activer `cgroup_memory` sur l'hôte pour que les limites Docker (`mem_limit`) soient réellement appliquées
- Envisager de réactiver la whitelist si le tunnel public reste actif sans supervision
- Ajouter une alerte (via OpenClaw + bot Telegram) en cas de crash ou d'anomalie sur le serveur, pour une supervision active sans surveillance manuelle des logs

## [0.4.0] - 2026-08-01

### Added

- Fichier `LICENSE` (MIT)
- CI GitHub Actions (`.github/workflows/ci.yml`) : validation `docker compose config`, lint YAML/Markdown, scan de secrets (gitleaks)
- Badge de statut CI, section « Stack & compétences » dans le README
- Script `backup.sh` (sauvegarde du monde avec rotation)

### Fixed

- Renommage de `.env exemple` → `.env.exemple` (espace dans le nom de fichier corrigé, cohérence avec le README)
- Renommage de `Chagelog.md` → `Changelog.md` (faute de frappe)
- Correction des erreurs `markdownlint` (blocs de code sans langage, formatage) et `yamllint` (retour à la ligne final, en-tête de document) relevées par le CI ; ajout de `.markdownlint-cli2.jsonc` et `.yamllint.yml` pour reproduire ces checks en local

## [0.3.0]

### Fixed

- Résolution DNS du container `playit` cassée à cause du `network_mode: service:mc-vanilla` : le proxy DNS interne de Docker (`127.0.0.11`) est inaccessible pour un container sans son propre endpoint réseau. Contournement via un `resolv-playit.conf` statique monté directement sur `/etc/resolv.conf`.

### Changed

- Externalisation du secret `SECRET_KEY` (playit) et de `SEED` (Minecraft) dans un fichier `.env`, non versionné
- Ajout de `.env.exemple` et `.gitignore` pour un partage sûr du projet

## [0.2.0]

### Changed

- Whitelist désactivée (`ENFORCE_WHITELIST` retiré) pour permettre une connexion directe des joueurs, y compris hors réseau privé

### Fixed

- Crash du serveur Minecraft (watchdog, tick bloqué 73s) causé par une contention mémoire avec un autre service tournant sur le même hôte, consommant plusieurs Go de RAM en continu

## [0.1.0]

### Added

- Premier déploiement du serveur Minecraft Java vanilla via `itzg/minecraft-server` (Docker, image multi-arch ARM64)
- Ajout du tunnel `playit.gg` (agent Docker) pour permettre l'accès public sans redirection de port sur le routeur (IP publique inaccessible à distance)
- Whitelist activée initialement, gestion des joueurs via la console
