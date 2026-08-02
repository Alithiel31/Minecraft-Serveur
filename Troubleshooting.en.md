# Troubleshooting

🇫🇷 [Version française](./Troubleshooting.md)

This document goes back over the two main incidents encountered during the deployment, including the diagnostic process followed — not just the final fix.

---

## 1. Minecraft server crash (watchdog, stuck tick)

### Symptom

After several minutes of normal operation, the server shut down abruptly:

```text
[Server thread/WARN]: Can't keep up! Is the server overloaded? Running 188049ms or 3760 ticks behind
[Server Watchdog/ERROR]: A single server tick took 73.23 seconds (should be max 0.05)
[Server Watchdog/ERROR]: Considering it to be crashed, server will forcibly shutdown.
```

A 73-second tick instead of 50 ms is not a simple gameplay slowdown — it is a complete freeze of the process. The server was empty at the time of the crash (no players connected), which ruled out gameplay-related overload straight away.

### Hypothesis

The host (Raspberry Pi 5) runs about thirty other Docker containers in parallel. Hypothesis: a memory usage spike from another service pushed the Minecraft JVM into swap, where memory access times blow up to the point of freezing the tick.

### Investigation

```bash
free -h
# Swap: 2.0Gi total, 1.6Gi used — confirms significant memory pressure

docker stats --no-stream
# One container was showing 3.7 GiB of RAM used (47% of the host total),
# far above every other service (often < 100 MiB each)
```

The container identified was running another application service (unrelated to Minecraft) which already showed, in its own logs, independent errors revealing resource saturation: connection pool timeouts against its database, write failures on a uniqueness constraint. Those errors indicated that this service was already running at the limit of its resources — consistent with abnormally high and growing memory usage.

### Conclusion / fix

- Temporarily stopping the offending container → available RAM on the host went back from ~1.8 Gi to ~5.2 Gi, and the Minecraft server stayed stable.
- **Root cause confirmed**: inter-container memory contention, not a bug in the Minecraft server or its configuration.
- **Unresolved point to watch**: the `mem_limit` set in the Minecraft compose file was not being enforced by Docker (`Your kernel does not support memory limit capabilities or the cgroup is not mounted. Limitation discarded.`), because `cgroup_memory` is not enabled at the kernel level on this host. Until that is fixed, no Docker memory limit is actually guaranteed — a proper fix remains to be applied (kernel parameter `cgroup_memory=1 cgroup_enable=memory`), beyond simply having stopped the offending service.

---

## 2. The playit.gg tunnel stays unreachable (DNS)

### Symptom

The public tunnel (playit.gg) looked correctly configured on the dashboard side (agent connected, tunnel created, address generated), but connecting failed systematically with a timeout. The playit agent logs were looping with:

```text
ERROR playit_agent_core::agent_control::address_selector: failed to send initial ping error=Os { code: 101, kind: NetworkUnreachable, ... }
ERROR playit_api_client::http_client: API call failed ... source: ... ConnectError("dns error", ... "failed to lookup address information: Try again")
WARN playit_agent_core::agent_control::maintained_control: control session expired; reconnecting reason=SessionNotSetup
```

### Hypotheses ruled out

1. **playit account email not verified** — plausible given `account_status="email_not_verified"` at first, but the problem persisted after verifying the email and restarting the agent.
2. **Memory contention** (see incident #1) — ruled out as well, the DNS error persisted well after that problem was resolved.

### Investigation

The `playit` container is configured with `network_mode: "service:mc-vanilla"` — it fully shares the network stack of the Minecraft container rather than having its own. DNS resolution test directly inside that shared network context:

```bash
docker exec mc-vanilla cat /etc/resolv.conf
# nameserver 127.0.0.11   → Docker's internal DNS proxy

docker exec playit-mc nslookup api.playit.gg
# nslookup: write to '127.0.0.11': Connection refused
```

The `mc-vanilla` container, on the other hand, resolved correctly (`docker exec mc-vanilla getent hosts api.playit.gg` returned valid IPs) — so the Docker DNS proxy was working overall. The refusal came specifically from the `playit` container.

### Root cause

A container started with `network_mode: service:X` (or `container:X`) has **no network endpoint of its own registered** with Docker — it entirely borrows the target container's. Docker's internal DNS proxy (`127.0.0.11`) associates its answers with the network endpoint querying it; without an endpoint of its own, requests from the shared-mode container to `127.0.0.11` are rejected (`Connection refused`). This is a known Docker limitation with this network mode, not a configuration bug.

### Fix

Bypass Docker's internal DNS proxy for the container concerned, by mounting a static `/etc/resolv.conf` pointing directly to public resolvers:

```yaml
playit:
  ...
  volumes:
    - ./resolv-playit.conf:/etc/resolv.conf:ro
```

```text
# resolv-playit.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
```

Note: Docker Compose's plain `dns:` directive at the service level **was not enough** at first — it only reconfigures the internal proxy's forwarders (`127.0.0.11`), without changing the fact that this proxy stays unreachable from a container without its own network endpoint. Mounting the `resolv.conf` file directly, which bypasses that proxy entirely, was necessary.
