# Contribuer

🇬🇧 [English version](./CONTRIBUTING.md)

Merci de l'intérêt porté à ce projet. Ce dépôt déploie un serveur Minecraft Java vanilla via Docker Compose ; toute contribution qui simplifie le déploiement, corrige un bug, ou améliore la documentation est la bienvenue.

## Avant de commencer

- Ouvrir une issue pour discuter du changement envisagé, sauf pour les corrections triviales (typo, lien cassé).
- Vérifier que le changement n'est pas déjà couvert par les items « À faire » du [`CHANGELOG.md`](./CHANGELOG.md).

## Environnement de développement

```bash
git clone git@github.com:Alithiel31/Minecraft-Serveur.git
cd Minecraft-Serveur
cp .env.example .env
# renseigner PLAYIT_SECRET_KEY et MC_SEED
```

Les vérifications de la CI peuvent être reproduites en local :

```bash
# Validation de la syntaxe du compose
docker compose -f minecraft-vanilla.yml config

# Lint YAML (config identique à celle du CI, voir .yamllint.yml)
yamllint -c .yamllint.yml minecraft-vanilla.yml

# Lint Markdown (config identique à celle du CI, voir .markdownlint-cli2.jsonc)
markdownlint-cli2 "**/*.md"
```

## Faire une Pull Request

1. Créer une branche depuis `main` (`git checkout -b fix/mon-changement`).
2. Committer avec un message clair, idéalement au format `type: description` (`fix:`, `docs:`, `chore:`...).
3. Mettre à jour [`CHANGELOG.md`](./CHANGELOG.md) dans la section `[Unreleased]` si le changement est notable pour un utilisateur.
4. Vérifier que les workflows CI passent (`validate-compose`, `lint-yaml`, `lint-markdown`, `secret-scan`, `smoke-test`).
5. Ouvrir la PR vers `main`.

## Signaler un problème

Merci d'inclure : la sortie de `docker logs mc-vanilla` (et `docker logs playit-mc` si le problème concerne le tunnel), la version de Docker/Docker Compose, et l'architecture de l'hôte (ARM64, x86...). Voir [`Troubleshooting.md`](./Troubleshooting.md) avant d'ouvrir une issue — les deux incidents les plus fréquents (crash mémoire, DNS playit) y sont déjà documentés.

## Secrets

Ne jamais committer `.env` ni aucune valeur réelle de `PLAYIT_SECRET_KEY` ou `MC_SEED`. Le CI inclut un scan `gitleaks` sur chaque PR.
