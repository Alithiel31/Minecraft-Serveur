# Serveur Minecraft Java Vanilla — Caesura (RPi5)

## Avant de démarrer

1. Créer le dossier de données sur le disque externe (pas la carte SD) :
```bash
mkdir -p /mnt/storage/minecraft/vanilla
```

2. Créer le fichier `.env` (non versionné, copié depuis `.env.example`) avec le vrai secret playit :
```bash
cp .env.example .env
nano .env   # coller le SECRET_KEY généré par le wizard playit.gg
```

3. Créer le fichier `resolv-playit.conf` **sur Caesura**, dans le même dossier que le compose (nécessaire car le container `playit` ne peut pas utiliser le resolver DNS interne de Docker à cause du `network_mode: service:mc-vanilla`) :
```bash
cat <<EOF > resolv-playit.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
```

Whitelist actuellement **désactivée** — n'importe qui trouvant l'adresse peut rejoindre (protection restante : `online-mode`, compte Mojang/Microsoft légitime requis).

## Déploiement

Depuis le dossier contenant `minecraft-vanilla.yml` :

```bash
docker compose -f minecraft-vanilla.yml up -d
```

## Vérifications post-lancement

```bash
# Suivre le démarrage du serveur Minecraft jusqu'au "Done" (génération du monde)
docker logs -f mc-vanilla

# Suivre la connexion de l'agent playit (doit confirmer la connexion à ton compte)
docker logs -f playit-mc

# Vérifier la consommation réelle des deux containers
docker stats mc-vanilla playit-mc --no-stream
```

## Accès des joueurs

- **Joueur sur Tailscale** : connexion directe à `100.109.50.124:25565`
- **Joueur hors Tailscale** : connexion via l'adresse publique générée dans le dashboard playit.gg
  (à créer : tunnel type "Minecraft Java" pointant vers le port local `25565`)

## Commandes utiles

```bash
# Arrêter le serveur (sans supprimer les containers/volumes)
docker compose -f minecraft-vanilla.yml stop

# Redémarrer
docker compose -f minecraft-vanilla.yml start

# Tout arrêter et supprimer les containers (le monde reste sur le volume)
docker compose -f minecraft-vanilla.yml down

# Se connecter à la console du serveur pour taper des commandes Minecraft (whitelist add, op, etc.)
docker attach mc-vanilla
# Pour se détacher sans arrêter le serveur : Ctrl+P puis Ctrl+Q
```

## Gérer la whitelist

Après le premier démarrage (une fois `mc-vanilla` up), attacher la console et ajouter les joueurs :

```bash
docker attach mc-vanilla
```

Puis dans la console Minecraft :

```
whitelist add pseudo1
whitelist add pseudo2
whitelist list       # vérifier la liste actuelle
whitelist remove pseudoX   # retirer un joueur si besoin
```

Pour se détacher de la console **sans arrêter le serveur** : `Ctrl+P` puis `Ctrl+Q`.

## Sauvegarde du monde

Le monde vit dans `/mnt/storage/minecraft/vanilla`. Sauvegarde simple :

```bash
tar -czf /mnt/storage/minecraft/backup-$(date +%Y%m%d).tar.gz -C /mnt/storage/minecraft vanilla
```