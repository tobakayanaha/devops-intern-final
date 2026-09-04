# DevOps Intern Final Assessment

**Name:** Bahlakoana
**Submission date:** 2026-09-02

[![CI](https://github.com/tonosa/devops-intern-final/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/tonosa/devops-intern-final/actions/workflows/ci.yml)

## Architecture Overview

```
 ┌────────────┐    push/PR    ┌──────────────┐    build+test    ┌───────────────┐
 │   Source   │ ────────────► │  GitHub      │ ────────────────►│   GHCR        │
 │  (GitHub)  │               │  Actions CI  │   (on main only) │  (registry)   │
 └────────────┘               └──────────────┘                  └───────┬───────┘
                                                                          │ pull image
                                                                          ▼
                                                                  ┌───────────────┐
                                                                  │     Nomad     │
                                                                  │  (orchestrate)│
                                                                  └───────┬───────┘
                                                                          │ container logs
                                                                          ▼
                                                                  ┌───────────────┐
                                                                  │ Promtail/Loki │
                                                                  │  (log agg.)   │
                                                                  └───────┬───────┘
                                                                          │
                                                                          ▼
                                                                  ┌───────────────┐
                                                                  │    Grafana    │
                                                                  │  (query/view) │
                                                                  └───────────────┘
```

Source changes flow through CI (lint → build → test → publish), land as a tagged
image in GHCR, get deployed by Nomad, and the running container's logs are shipped
to Loki and queried via Grafana.

## Prerequisites

| Tool       | Version used in this project |
|------------|-------------------------------|
| Docker     | 29.7.0 (build c1eba93)        |
| Nomad      | to be filled     |
| Consul     | to be filled    |
| ShellCheck | 0.9.0                         |
| Git        | 2.43.0                        |

## Quick Start

```bash
git clone https://github.com/tobakayanaha/devops-intern-final.git
cd devops-intern-final
docker build --build-arg BUILD_SHA=$(git rev-parse --short HEAD) -t nginx-app:local app/
docker run -d --name nginx-app -p 8080:8080 nginx-app:local
curl http://localhost:8080/
curl http://localhost:8080/healthz
chmod +x scripts/healthcheck.sh
./scripts/healthcheck.sh http://localhost:8080/healthz
docker rm -f nginx-app
```

---

## Task 1 — Source Control

- Repository: [`devops-intern-final`](https://github.com/tonosa/devops-intern-final) (public)
- Work was done on `feature/*` branches, merged to `main` via pull requests
  opened and self-reviewed by the author (inline review comments left on
  `app/nginx.conf` and `app/Dockerfile` before merging).
- Conventional commit messages used throughout (`feat:`, `ci:`, `docs:`).
- Final state tagged `v1.0.0` _(to be tagged once all tasks are complete)_.

## Task 2 — Linux Scripting

Both scripts live under `scripts/`, use `#!/usr/bin/env bash` with
`set -euo pipefail`, and are marked executable in git via
`git update-index --chmod=+x`.

**ShellCheck result:** both scripts pass with zero warnings (verified locally
with ShellCheck 0.9.0).

### `sysinfo.sh` sample output

```
=== User Info ===
Current user : bgr101
Effective UID: 1000
=== Host Info ===
Hostname      : TOBAKA
Kernel release: 5.15.167.4-microsoft-standard-WSL2
=== Date ===
System date (ISO-8601): 2026-09-02T07:18:49Z
=== Disk Usage ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdc       1007G   11G  945G   2% /
...
(truncated — WSL mounts several virtual filesystems; full output shows all
mount points, df -h output above is representative)
=== Memory Usage ===
               total        used        free      shared  buff/cache   available
Mem:           3.7Gi       671Mi       3.0Gi       3.5Mi       263Mi       3.1Gi
Swap:          1.0Gi          0B       1.0Gi
=== Docker Daemon Status ===
Docker daemon: running
```

> Captured on WSL2 (Ubuntu). The `Disk Usage` section is truncated above for
> readability — WSL2 mounts a number of internal virtual filesystems
> (`/mnt/wsl`, `/run`, snap loopbacks, etc.) alongside the real disks; the
> `/dev/sdc` and `C:\` lines are the meaningful ones on this host.

### `healthcheck.sh` sample output

```
$ ./scripts/healthcheck.sh http://localhost:9999
Checking http://localhost:9999 ...
FAIL: http://localhost:9999 returned HTTP 000 (expected 200)
$ echo $?
1

$ ./scripts/healthcheck.sh http://localhost:8080
Checking http://localhost:8080 ...
OK: http://localhost:8080 returned HTTP 200
$ echo $?
0
```

## Task 3 — Containerisation

- Base image: `nginx:1.27-alpine` (pinned, not `latest`)
- Runs as the non-root `nginx` user
- Custom `app/nginx.conf` serves the static site on port 8080 and exposes
  `/healthz`
- `BUILD_SHA` build-arg is injected into `index.html` at build time via `sed`
- `HEALTHCHECK` instruction included (fixed during development — see
  Troubleshooting)

### Build command

```bash
docker build --build-arg BUILD_SHA=$(git rev-parse --short HEAD) -t nginx-app:test app/
```

### Run command

```bash
docker run -d --name nginx-test -p 8080:8080 nginx-app:test
```

### Image size

```
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
nginx-app:test   f92f381bf8b0       73.7MB           21MB
```

> **Note:** Docker Desktop reports two figures here — "content size" (21MB,
> the actual layer data) is well under the 60MB budget. "Disk usage" (73.7MB)
> includes shared base-image layers already cached on the host and is not a
> reliable measure of the image's own contribution. The content size is the
> correct figure to compare against the 60MB limit.

### `curl` against `/`

```
HTTP/1.1 200 OK
Server: nginx/1.27.5
Content-Type: text/html
Content-Length: 1033
...
<dt>Build ID</dt>
<dd><code>aa836f6</code></dd>
```

### `curl` against `/healthz`

```
HTTP/1.1 200 OK
Server: nginx/1.27.5
Content-Type: text/plain
Content-Length: 3

OK
```

### Non-root confirmation

```
$ docker exec nginx-test whoami
nginx
```

### Docker HEALTHCHECK status

```
$ docker inspect --format='{{.State.Health.Status}}' nginx-test
healthy
```

## Task 4 — Continuous Integration

Workflow: `.github/workflows/ci.yml`, triggered on push and PR to `main`.

| Job       | Purpose                                                                 |
|-----------|--------------------------------------------------------------------------|
| `lint`    | ShellCheck on `scripts/`, Hadolint on `app/Dockerfile`                  |
| `build`   | Builds the image with `BUILD_SHA=${{ github.sha }}`, saves as artifact  |
| `test`    | Loads the same artifact, runs `scripts/healthcheck.sh` against `/healthz` |
| `publish` | Push-to-`main` only. Pushes to GHCR tagged with SHA and `latest`        |

- Third-party actions pinned to major/specific versions (`actions/checkout@v5`,
  `actions/upload-artifact@v4`, `hadolint/hadolint-action@v3.1.0`,
  `ludeeus/action-shellcheck@2.0.0`, `docker/login-action@v3`).
- `GITHUB_TOKEN` permissions are least-privilege: `contents: read` at the
  workflow level, with `packages: write` scoped only to the `publish` job.
- All four jobs pass on `main`, including `publish` — image is live at
  `ghcr.io/tonosa/devops-intern-final`.

## Task 5 — Orchestration with Nomad

_To be completed._

## Task 6 — Log Aggregation with Grafana Loki

_To be completed._

---

## Troubleshooting

1. **Docker `HEALTHCHECK` failing despite the endpoint working.** `curl` from
   the host against the mapped port succeeded, but Docker's own
   `HEALTHCHECK` reported `unhealthy`. `docker inspect` on the container's
   health log showed `wget: can't connect to remote host: Connection
   refused` when hitting `localhost:8080` **from inside** the container.
   Alpine resolves `localhost` to both `127.0.0.1` and `::1`, and `wget`
   attempted the IPv6 address first — but `nginx.conf` only binds
   `listen 8080;` (IPv4-only), so the IPv6 attempt was refused. Fixed by
   using `127.0.0.1` explicitly in the `HEALTHCHECK` command instead of
   `localhost`.

2. **`git update-index --chmod` failing on untracked files.** Attempting to
   mark new, not-yet-staged scripts as executable via
   `git update-index --chmod=+x` failed with "cannot add to the index —
   missing --add option." Resolved by staging the files with `git add`
   first, since `update-index --chmod` only operates on files already known
   to git's index.

5. _(for next tasks once issues are there)_

## Known Limitations

- Tasks 5 (Nomad) and 6 (Loki/Grafana) are not yet implemented as of this
  README draft.
- The image's "disk usage" figure (73.7MB) exceeds a strict reading of the
  60MB budget, though "content size" (21MB) — the image's actual own
  contribution — is well under it. Worth clarifying which metric the
  assessment intends.
- `actions/checkout` was bumped to `v5` to resolve a Node.js 20 deprecation
  warning; `actions/upload-artifact`/`download-artifact` remain on `v4` and
  may still emit the same warning — non-blocking, noted for future
  maintenance.
- No optional extension has been attempted yet.

## Screenshots

Screenshots referenced inline throughout the relevant task sections above,
stored under `docs/screenshots/`. _(to be added as captured)_