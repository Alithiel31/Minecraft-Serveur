# Changelog

All notable changes to this project are documented here.
Format inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### To do

- Re-enable the other service involved in the memory contention incident, with a proper `mem_limit` to avoid any new contention with `mc-vanilla`
- Confirm/enable `cgroup_memory` on the host so that the Docker limits (`mem_limit`) are actually enforced
- Consider re-enabling the whitelist if the public tunnel stays up without supervision
- Add an alert (via OpenClaw + a Telegram bot) on server crash or anomaly, for active supervision without manually watching the logs

## [0.5.0] - 2026-08-02

Documentation release: English becomes the default language of the repository, with French kept as a complete mirror. No change to the deployment itself.

### Added

- English `README.md` as the main entry point of the repository, with a faithful French translation in `README.fr.md` and cross-links between the two
- `Troubleshooting.en.md`: English translation of `Troubleshooting.md`, cross-linked with the French version; the English README now points to it
- `CONTRIBUTING.fr.md`: French version of the contributing guide, cross-linked with the English one
- GitHub issue forms (`.github/ISSUE_TEMPLATE/`): a bug report asking for the logs, versions and host architecture the contributing guide already required, a change/improvement request, and links to the troubleshooting notes
- `resolv-playit.conf.example`, so the file required by the compose bind mount can be copied instead of typed by hand

### Changed

- `Changelog.md` renamed to `CHANGELOG.md` and translated to English
- `CONTRIBUTING.md` translated to English, in line with the rest of the default documentation
- `backup.sh`: comments, usage block and output messages translated to English (no behaviour change)
- Smoke test job renamed from "Démarrage réel du serveur" to "Real server startup" — the check name shown on pull requests changes accordingly
- `.env.exemple` renamed to `.env.example` (English spelling); update your local copy command accordingly

### Fixed

- Installation steps in both READMEs rendered as "1. / 1. / 1." instead of 1, 2, 3: the code blocks between the steps split the list into three, and are now indented inside their step
- `.gitignore` did not cover `backups/` (the default output of `backup.sh`) nor `resolv-playit.conf`, so running a backup from the repository left world archives untracked in the working tree
- Requirements sections now warn that Docker silently discards `mem_limit` when cgroup memory accounting is off at the kernel level — the root cause of the documented crash, previously mentioned only in the troubleshooting notes

## [0.4.0] - 2026-08-01

### Added

- `LICENSE` file (MIT)
- GitHub Actions CI (`.github/workflows/ci.yml`): `docker compose config` validation, YAML/Markdown linting, secret scanning (gitleaks)
- CI status badge, "Stack & skills" section in the README
- `backup.sh` script (world backup with rotation)

### Fixed

- Renamed `.env exemple` → `.env.exemple` (space in the filename fixed, consistent with the README)
- Renamed `Chagelog.md` → `Changelog.md` (typo)
- Fixed the `markdownlint` (code blocks without a language, formatting) and `yamllint` (final newline, document header) errors reported by the CI; added `.markdownlint-cli2.jsonc` and `.yamllint.yml` to reproduce those checks locally

## [0.3.0]

### Fixed

- DNS resolution broken in the `playit` container because of `network_mode: service:mc-vanilla`: Docker's internal DNS proxy (`127.0.0.11`) is unreachable for a container without its own network endpoint. Worked around with a static `resolv-playit.conf` mounted directly over `/etc/resolv.conf`.

### Changed

- Moved the `SECRET_KEY` (playit) and `SEED` (Minecraft) secrets out into a `.env` file, not versioned
- Added `.env.exemple` and `.gitignore` for safe sharing of the project

## [0.2.0]

### Changed

- Whitelist disabled (`ENFORCE_WHITELIST` removed) to let players connect directly, including from outside the private network

### Fixed

- Minecraft server crash (watchdog, tick stuck for 73s) caused by memory contention with another service running on the same host, continuously consuming several GB of RAM

## [0.1.0]

### Added

- First deployment of the vanilla Minecraft Java server via `itzg/minecraft-server` (Docker, multi-arch ARM64 image)
- Added the `playit.gg` tunnel (Docker agent) to allow public access without port forwarding on the router (public IP unreachable remotely)
- Whitelist enabled initially, players managed through the console
