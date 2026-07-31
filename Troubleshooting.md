# Troubleshooting

Ce document retrace les deux principaux incidents rencontrés lors du déploiement, avec la démarche de diagnostic suivie — pas seulement la solution finale.

---

## 1. Crash du serveur Minecraft (watchdog, tick bloqué)

### Symptôme

Après plusieurs minutes de fonctionnement normal, le serveur s'est arrêté brutalement :

```
[Server thread/WARN]: Can't keep up! Is the server overloaded? Running 188049ms or 3760 ticks behind
[Server Watchdog/ERROR]: A single server tick took 73.23 seconds (should be max 0.05)
[Server Watchdog/ERROR]: Considering it to be crashed, server will forcibly shutdown.
```

Un tick à 73 secondes au lieu de 50 ms n'est pas un simple ralentissement de jeu — c'est un gel complet du processus. Le serveur était vide au moment du crash (aucun joueur connecté), ce qui excluait d'emblée une surcharge liée au gameplay.

### Hypothèse

L'hôte (Raspberry Pi 5) fait tourner une trentaine d'autres containers Docker en parallèle. Hypothèse : un pic de consommation mémoire d'un autre service a poussé la JVM Minecraft dans le swap, où les temps d'accès mémoire explosent au point de geler le tick.

### Investigation

```bash
free -h
# Swap: 2.0Gi total, 1.6Gi utilisé — confirme une pression mémoire significative

docker stats --no-stream
# Un container affichait 3.7 GiB de RAM utilisée (47% du total de l'hôte),
# largement au-dessus de tous les autres services (souvent < 100 MiB chacun)
```

Le container identifié tournait un processus d'ingestion de données en continu (connexion WebSocket permanente à un firehose externe, écritures DB via Prisma). Ses propres logs montraient déjà des erreurs indépendantes :

```
Timed out fetching a new connection from the connection pool. connection_limit: 9, timeout: 10
Unique constraint failed on the fields: (`uri`)
```

Ces erreurs (pool de connexions Prisma sous-dimensionné, race condition sur un upsert) indiquaient que ce service tournait déjà à la limite de ses ressources — cohérent avec une consommation mémoire anormalement élevée et croissante.

### Conclusion / correction

- Arrêt temporaire du container en cause → la RAM disponible sur l'hôte est repassée de ~1.8 Gi à ~5.2 Gi, et le serveur Minecraft est resté stable.
- **Root cause confirmée** : contention mémoire inter-containers, pas un bug du serveur Minecraft ou de sa configuration.
- **Point de vigilance non résolu** : la limite `mem_limit` définie dans le compose Minecraft n'était pas appliquée par Docker (`Your kernel does not support memory limit capabilities or the cgroup is not mounted. Limitation discarded.`), car `cgroup_memory` n'est pas activé au niveau kernel sur cet hôte. Tant que ce n'est pas corrigé, aucune limite mémoire Docker n'est réellement garantie — un correctif de fond reste à appliquer (paramètre kernel `cgroup_memory=1 cgroup_enable=memory`), au-delà du simple fait d'avoir arrêté le service fautif.

---

## 2. Le tunnel playit.gg reste injoignable (DNS)

### Symptôme

Le tunnel public (playit.gg) semblait configuré correctement côté dashboard (agent connecté, tunnel créé, adresse générée), mais la connexion échouait systématiquement en timeout. Les logs de l'agent playit tournaient en boucle avec :

```
ERROR playit_agent_core::agent_control::address_selector: failed to send initial ping error=Os { code: 101, kind: NetworkUnreachable, ... }
ERROR playit_api_client::http_client: API call failed ... source: ... ConnectError("dns error", ... "failed to lookup address information: Try again")
WARN playit_agent_core::agent_control::maintained_control: control session expired; reconnecting reason=SessionNotSetup
```

### Hypothèses écartées

1. **Email du compte playit non vérifié** — plausible au vu de `account_status="email_not_verified"` dans un premier temps, mais le problème a persisté après vérification de l'email et redémarrage de l'agent.
2. **Contention mémoire** (voir incident n°1) — écartée aussi, l'erreur DNS persistait bien après résolution de ce problème.

### Investigation

Le container `playit` est configuré avec `network_mode: "service:mc-vanilla"` — il partage entièrement la pile réseau du container Minecraft plutôt que d'avoir la sienne propre. Test de résolution DNS directement dans ce contexte réseau partagé :

```bash
docker exec mc-vanilla cat /etc/resolv.conf
# nameserver 127.0.0.11   → le proxy DNS interne de Docker

docker exec playit-mc nslookup api.playit.gg
# nslookup: write to '127.0.0.11': Connection refused
```

Le container `mc-vanilla`, lui, résolvait correctement (`docker exec mc-vanilla getent hosts api.playit.gg` retournait des IP valides) — donc le proxy DNS Docker fonctionnait globalement. Le refus venait spécifiquement du container `playit`.

### Root cause

Un container démarré avec `network_mode: service:X` (ou `container:X`) n'a **pas son propre endpoint réseau enregistré** auprès de Docker — il emprunte entièrement celui du container cible. Le proxy DNS interne de Docker (`127.0.0.11`) associe ses réponses à l'endpoint réseau qui l'interroge ; sans endpoint propre, les requêtes du container en mode partagé vers `127.0.0.11` sont rejetées (`Connection refused`). C'est une limitation connue de Docker avec ce mode réseau, pas un bug de configuration.

### Correction

Contourner le proxy DNS interne de Docker pour le container concerné, en montant un `/etc/resolv.conf` statique pointant directement vers des résolveurs publics :

```yaml
playit:
  ...
  volumes:
    - ./resolv-playit.conf:/etc/resolv.conf:ro
```

```
# resolv-playit.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
```

Note : la simple directive `dns:` de Docker Compose au niveau du service **n'a pas suffi** dans un premier temps — elle ne fait que reconfigurer les forwarders du proxy interne (`127.0.0.11`), sans changer le fait que ce proxy reste inaccessible depuis un container sans endpoint réseau propre. Le montage direct du fichier `resolv.conf`, qui bypasse totalement ce proxy, était nécessaire.