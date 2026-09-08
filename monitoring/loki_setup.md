# Loki Setup Notes

## How the stack was started

```bash
cd monitoring
docker compose up
```

This brings up three containers, defined in `docker-compose.yaml`:

- **Loki** (`grafana/loki:3.7.0`) — log storage/query engine, port 3100
- **Promtail** (`grafana/promtail:3.6.8`) — log shipper, discovers containers via
  the Docker socket
- **Grafana** (`grafana/grafana-oss:13.0.2`) — query UI, port 3000

Promtail is configured (`promtail-config.yaml`) with a `docker_sd_configs`
scrape job that discovers **every** running container on the host via the
Docker socket, not just the nginx-app one — it relabels each discovered
container with `job`, `container`, and (where present)
`nomad_alloc_id`.

## Label set applied

Confirmed directly from the container Nomad launches
(`docker inspect nginx-app-<alloc-id> --format '{{json .Config.Labels}}'`),
Nomad's Docker driver sets exactly one label by default on this version
(Nomad v2.0.5): `com.hashicorp.nomad.alloc_id`. Promtail relabels this into
a first-class Loki label.

Final label set attached to each log stream from the nginx-app container:

| Label            | Source                                            | Example value                              |
|------------------|----------------------------------------------------|---------------------------------------------|
| `job`            | Static value set in `promtail-config.yaml`         | `docker-logs`                               |
| `container`      | `__meta_docker_container_name` (Docker SD)         | `nginx-app-0cc64c19-43f4-bcb3-c883-ed422e71355e` |
| `container_id`   | `__meta_docker_container_id` (Docker SD)           | `662cdd25317a...`                           |
| `nomad_alloc_id` | `com.hashicorp.nomad.alloc_id` Docker label         | `0cc64c19-43f4-bcb3-c883-ed422e71355e`      |

This satisfies the brief's requirement of at minimum `job`, `container`, and
one of `nomad_alloc_id` or `service`.

## Confirming ingestion

Generated real traffic against the running Nomad-deployed container,
including a deliberate request to a path that doesn't exist:

```bash
curl http://172.30.192.163:24338/
curl http://172.30.192.163:24338/this-path-does-not-exist
```

### LogQL query — isolating all nginx-app logs

```logql
{container=~"nginx-app.*"}
```

Result: 3 log lines returned — nginx's own error log line for the missing
path, plus two access log lines (one `200`, one `404`).

### LogQL query — isolating the non-200 request specifically

```logql
{container=~"nginx-app.*"} |= "404"
```

Result:

```
172.30.192.163 - - [08/Sep/2026:06:33:12 +0000] "GET /this-path-does-not-exist HTTP/1.1" 404 153 "-" "curl/8.5.0"
```

This confirms Loki is correctly ingesting labelled nginx access logs and
that a LogQL filter can isolate error responses specifically.

## Problems hit and how they were resolved

1. **Queried the wrong port entirely.** Early testing accidentally curled
   Nomad's own web UI port (`4646`) instead of the actual application's
   dynamic port, which meant "confirming ingestion" was really just
   confirming Nomad's UI responds to anything — an easy mistake when
   juggling several running services' addresses at once. Fixed by
   re-checking `nomad alloc status` for the real `Allocation Addresses`
   entry.

2. **Wrong container name assumed for `docker logs`.** Assumed Compose
   would prefix containers with the git repo name
   (`devops-intern-final-promtail-1`), but Compose actually names
   containers after the **directory** the compose file lives in
   (`monitoring-promtail-1`, since the file is at `monitoring/docker-compose.yaml`).
   Confirmed the real names via `docker ps` rather than guessing further.

3. **First Loki query returned an empty result set.** Ran the LogQL query
   before generating any real traffic against the app — Loki correctly
   had nothing to return, since no logs existed yet. Not a bug; resolved by
   generating traffic first, then re-querying (with a short `sleep` to
   allow for Promtail's scrape interval).

4. **Nomad allocation later reported as `lost`.** Unrelated to Loki
   directly, but discovered while re-checking the allocation's address:
   the Nomad agent had stopped at some point (same root cause as an
   earlier Consul outage — `-dev` mode has no persistent background
   service), leaving Nomad believing the allocation was lost even though
   the underlying Docker container kept running independently. Logs were
   still ingested correctly throughout, since Promtail talks to Docker
   directly and has no dependency on Nomad's own view of the world.