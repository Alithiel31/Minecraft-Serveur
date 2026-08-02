# Contributing

🇫🇷 [Version française](./CONTRIBUTING.fr.md)

Thanks for your interest in this project. This repository deploys a vanilla Minecraft Java server through Docker Compose; any contribution that simplifies the deployment, fixes a bug, or improves the documentation is welcome.

## Before you start

- Open an issue to discuss the change you have in mind, except for trivial fixes (typo, broken link).
- Check that the change is not already covered by the "To do" items in [`CHANGELOG.md`](./CHANGELOG.md).

## Development environment

```bash
git clone git@github.com:Alithiel31/Minecraft-Serveur.git
cd Minecraft-Serveur
cp .env.example .env
# fill in PLAYIT_SECRET_KEY and MC_SEED
```

The CI checks can be reproduced locally:

```bash
# Compose syntax validation
docker compose -f minecraft-vanilla.yml config

# YAML lint (same config as the CI, see .yamllint.yml)
yamllint -c .yamllint.yml minecraft-vanilla.yml

# Markdown lint (same config as the CI, see .markdownlint-cli2.jsonc)
markdownlint-cli2 "**/*.md"
```

## Opening a Pull Request

1. Create a branch from `main` (`git checkout -b fix/my-change`).
2. Commit with a clear message, ideally in the `type: description` format (`fix:`, `docs:`, `chore:`...).
3. Update [`CHANGELOG.md`](./CHANGELOG.md) in the `[Unreleased]` section if the change is notable for a user.
4. Check that the CI workflows pass (`validate-compose`, `lint-yaml`, `lint-markdown`, `secret-scan`, `smoke-test`).
5. Open the PR against `main`.

## Reporting a problem

Opening an issue gives you a form that asks for exactly what is needed: the output of `docker logs mc-vanilla` (and `docker logs playit-mc` if the problem concerns the tunnel), the Docker/Docker Compose version, and the host architecture (ARM64, x86...). Check [`Troubleshooting.en.md`](./Troubleshooting.en.md) before opening an issue — the two most frequent incidents (memory crash, playit DNS) are already documented there.

Never paste a real `PLAYIT_SECRET_KEY` or `MC_SEED` in an issue; redact them from any log or config you copy in.

## Secrets

Never commit `.env` or any real value of `PLAYIT_SECRET_KEY` or `MC_SEED`. The CI includes a `gitleaks` scan on every PR.
