---
name: deploy-docker-compose-vps
description: >-
  Production deployment of a Next.js + Postgres web app to a VPS: one Docker
  Compose project per environment behind the host's nginx, images built in
  GitHub Actions and pushed to GHCR, staging deployed on every merge,
  production started by a person, rollbacks by commit. Ships complete,
  runnable files. Use when setting up or changing production deployment
  for an app with a database; not for previews (Deployer) or static sites.
metadata:
  type: practice
  category: deployment
---

## Rule

Production for an app with a database runs on a VPS the user controls. Each
environment (production, staging) is one Docker Compose project in its own
folder, behind the host's nginx, which terminates TLS. The image built by CI
carries everything the server needs, so nobody ever copies files to a server
by hand. The complete, runnable files are in [files/](files/):

| File | What it does |
| --- | --- |
| [`Dockerfile`](files/Dockerfile) | multi-stage, Node 24 LTS, standalone Next output, non-root, `BUILD_COMMIT` as runtime env, build secrets as BuildKit secrets, `deploy/` baked in |
| [`.dockerignore`](files/.dockerignore) | keeps docs, tests and test configs out (Next type-checks everything in the context) |
| [`deploy/compose.yaml`](files/deploy/compose.yaml) | app, Postgres, optional worker; one-shot `migrate` in its own profile; loopback ports, no DB port, dropped capabilities, `no-new-privileges`, init, log rotation, node-based health checks |
| [`deploy/deploy.sh`](files/deploy/deploy.sh) | `setup` once; `<env> <sha>` per deploy: pull, place files from the image, migrate alone, `up -d`, wait for health *as this build*, check the worker, keep five images |
| [`deploy/nginx/site.conf`](files/deploy/nginx/site.conf) | the site template `deploy.sh` renders per environment, tested with `nginx -t` before reload |
| [`deploy/.env.example`](files/deploy/.env.example) | every setting, with how to generate each secret |
| [`.github/workflows/ci.yml`](files/.github/workflows/ci.yml) | checks, audit, and the image built and run like the server runs it |
| [`.github/workflows/release.yml`](files/.github/workflows/release.yml) | on main: build and push `:<sha>` + `:main` (or re-tag when nothing in the image changed), keep five, deploy staging |
| [`.github/workflows/deploy.yml`](files/.github/workflows/deploy.yml) | `workflow_call` + manual dispatch: SSH with the forced-command key, then check health from outside |
| [`.github/workflows/secret-scan.yml`](files/.github/workflows/secret-scan.yml) | TruffleHog on every push and PR, docs included |
| [`app/api/health/route.ts`](files/app/api/health/route.ts) | database, worker heartbeat and build commit; 503 when the database is down |

Fill in the placeholders `<ORG>`, `<APP>` (lowercase), `<DOMAIN>` and
`<HOST>`, plus the two loopback ports at the top of `deploy.sh`.
`deploy.sh` refuses to run while any `<…>` is left.

### What the app must bring

- `output: "standalone"` in `next.config`, and an `.nvmrc` with the same
  Node major as the Dockerfile.
- The npm scripts CI calls: `format:check`, `lint`, `typecheck`, `test`,
  `build`.
- A `postbuild` that puts a bundled `migrate.mjs` (and `worker.mjs`, if
  there is a worker) beside `server.js` in `.next/standalone`, plus the
  migrations folder. Bundling keeps the ORM's CLI and the full
  `node_modules` out of the image.
- `start` runs `node .next/standalone/server.js`, so tests run the same
  server as the image. `next start` doesn't serve a standalone build.

```json
"postbuild": "cp -R .next/static .next/standalone/.next/ && if [ -d public ]; then cp -R public .next/standalone/; fi && cp -R migrations .next/standalone/ && node scripts/bundle.mjs .next/standalone",
"start": "node .next/standalone/server.js"
```

- With a worker: a heartbeat it upserts every 30 seconds, which the health
  route reads. The worker reads `BUILD_COMMIT` from the environment at
  runtime, never from a `NEXT_PUBLIC_` variable, which is only inlined into
  what `next build` bundles.

### The flow

1. **Pull request.** CI runs format, lint, typecheck and unit tests, a
   production-dependency audit and the secret scan. It also builds the
   production image and runs it against an empty Postgres the way the
   server does: migrations, then app and worker answering `/api/health` as
   this commit, with the deploy files inside the image.
2. **Merge to main.** Release builds and pushes `ghcr.io/<ORG>/<APP>:<sha>`
   and `:main`, keeps the newest five versions, and calls Deploy for
   **staging**. If the commit only touched what `.dockerignore` leaves out,
   it re-tags the previous image in seconds and deploys nothing.
3. **Deploy.** The workflow SSHes in as root with the deploy key. The key's
   forced command runs `deploy.sh staging <sha>`, which:
   - pulls the image, and takes `compose.yaml`, its own newer version and
     the rendered nginx site from it;
   - runs `migrate` alone; if it fails, the previous release keeps running;
   - runs `docker compose up -d`;
   - polls the app on its loopback port for up to two minutes, until the
     database answers and `build` equals the image's own `BUILD_COMMIT`;
   - checks the new worker has never restarted;
   - prints `staging runs <sha>. Before: <old>.`, and prunes its own images
     to the newest five.

   The workflow then checks `https://staging.<DOMAIN>/api/health` and `/`
   from outside, through nginx and TLS, and records a GitHub deployment.
4. **Production** is the same workflow, started by a person: Actions →
   Deploy → Run workflow → `production`, with the SHA staging was checked
   on.
5. **Rollback** is a Deploy of the SHA the last summary calls "Before".
   Migrations don't run backwards, so they are written expand/contract: add
   before the code that needs it ships, remove only once no reachable image
   reads it. The older image then runs on the newer schema. A migration
   that can't keep to that says so in its PR, along with what a rollback
   needs.

A project without staging (a simple site with a backend) can let a green CI
run on main deploy production directly, if the user decides so.

### One-time server setup

All as root on the server, unless noted.

1. **Packages.** Debian or Ubuntu with Docker Engine and Compose v2.20+,
   plus nginx and certbot with its nginx plugin. Register certbot once
   (`certbot register --agree-tos -m <EMAIL>`), because `setup` runs it
   non-interactively.
2. **Firewall.** Allow only 22, 80 and 443. Docker writes its own iptables
   rules, so a port published on all addresses would get past ufw; that is
   why every port in `compose.yaml` binds `127.0.0.1`.
3. **DNS.** A and AAAA records for `<DOMAIN>` and `staging.<DOMAIN>`.
4. **Ports.** `ss -ltn | grep -E ':(3200|3201) '` must print nothing.
   Otherwise pick other ports in `deploy.sh` before the first release.
5. **First release.** Fill in the placeholders and merge; Release publishes
   `:main`. If the GHCR package is private, run `docker login ghcr.io` with
   a classic token that has only `read:packages`.
6. **Run setup.** Take `deploy.sh` from main's image and run its setup.
   Setup creates `/srv/<APP>/{production,staging}`, each `.env` (mode 600,
   with its own generated database password and auth secret), the
   certificates and the nginx sites. Re-running it changes only what's
   missing.

   ```sh
   mkdir -p /srv/<APP>
   docker run --rm --pull always ghcr.io/<ORG>/<APP>:main cat deploy/deploy.sh > /srv/<APP>/deploy.sh
   chmod 755 /srv/<APP>/deploy.sh
   /srv/<APP>/deploy.sh setup
   ```

7. **Deploy key.** Generate it on a laptop, never on the server:
   `ssh-keygen -t ed25519 -N "" -C "<APP> deploy" -f <APP>-deploy`. Put the
   public half in `/root/.ssh/authorized_keys`, bound to the one command:

   ```
   command="/srv/<APP>/deploy.sh",restrict ssh-ed25519 AAAA… <APP> deploy
   ```

   Then add these in GitHub, and delete the private key from the laptop:

   | Name | Kind | Value |
   | --- | --- | --- |
   | `DEPLOY_SSH_KEY` | secret | the private half |
   | `DEPLOY_HOST` | variable | the server's address |
   | `DEPLOY_USER` | variable | `root` |
   | `DEPLOY_KNOWN_HOSTS` | variable | `ssh-keyscan -t ed25519 <HOST>`, compared with the fingerprint on the server |

   Running as root is deliberate: membership of the `docker` group is
   root-equivalent anyway, and the forced command is what limits the key.
8. **First deploys.** Deploy staging, then production, from the Actions tab.
9. **App settings.** The user adds the app's own secrets (mail, AI keys) to
   each environment's `.env` and runs `docker compose up -d`. Secrets never
   go through CI or the chat.
10. **Monitoring.** Point an uptime monitor at
    `https://<DOMAIN>/api/health`, looking for the keyword `"worker":"ok"`.

Walk the user through server work one safe step at a time: read-only
diagnostics first, short commands that can't wrap when pasted, and their
SSH session kept open while access changes.

### Pitfalls the files already guard against

- **A release's first deploy dies on a setting it introduced.** The key
  runs the `deploy.sh` already on the server, which is the previous
  release's. Every new variable in `compose.yaml` therefore gets a default
  (`${NAME:-}`) or sits behind a profile that is off until the new script
  has written it. Check with `docker compose config` against an old `.env`.
- **A script replacing itself mid-run.** bash reads a script as it executes
  it, so `deploy.sh` writes `<file>.new` and moves it over the old file.
- **One bad nginx file takes every site on the host down.** The site is
  rendered, `nginx -t` runs, and nginx reloads only if the test passes;
  otherwise the previous file goes back.
- **A failed migration leaves nothing running.** `migrate` is never a
  `depends_on`; it runs alone before `up`.
- **The old container passes for the new one.** The deploy waits for
  `build` to equal the image's own `BUILD_COMMIT`. It compares against the
  image's value, not the requested SHA, because re-tagged images carry
  their original commit.
- **A crash-looping worker looks healthy.** Its old heartbeat stays fresh
  for two minutes, so `deploy.sh` checks `RestartCount 0` on the new
  container.
- **A database password breaks the URL.** Generate passwords as hex, and
  never regenerate one on an existing volume.
- **Postgres 18 data outside the volume.** Mount the volume at
  `/var/lib/postgresql`, not `…/data`.
- **Spoofed client IPs.** nginx sets `X-Forwarded-For $remote_addr`
  instead of appending to the client's chain.
- **A failed deploy reports green.** Steps run with `shell: bash`, so
  `pipefail` catches `ssh … | tee`.
- **A lost push event.** During a GitHub incident a merge's push event was
  lost, and nothing ran. CI and Release have `workflow_dispatch`, and
  Release runs only from main.
- **GHCR retention miscounts.** Attestations count as package versions, so
  `provenance: false` and `sbom: false`.
- **A rollback target is gone.** Five kept images are shared by staging and
  production, so after five merges production's previous image may be
  pruned. Raise the count, or tag production releases so they are kept.

### Never

- `docker system prune`, `docker volume prune` or `docker compose down -v`
  on a shared host. They reach other projects' data.
- Required new settings in the same release that teaches `deploy.sh` to
  write them.
- App secrets in Actions, CI runners on the production host, or files
  copied to the server by hand.
- SSHing into or changing a server the user didn't ask you to touch.

### The hand-run variant (a demo, no CI)

When the user says not to build CI/CD ("I will deploy it manually"), deliver
the Dockerfile, compose file, nginx site, `.env.example` and a runbook.
Build on the server, not on a laptop: clone the repo there, tag the image
with the short commit, build, set the tag in `.env`, migrate, and run
`docker compose up -d`. Give one paste-able block per step, with its
expected output. Cross-building amd64 on a Mac and streaming a multi-GB
image over SSH produced a string of failures. Don't keep two files called
`compose.yaml` or `.env.example` (one for dev, one for the server); the dev
ones got copied to the server twice.

## Why

This setup ran production and staging for a multi-role dashboard app from
mid-October 2026, was copied for a second app, and shaped a hand-run client
demo. Every guard in the pitfalls list exists because the problem actually
happened (or, for the last item, was spotted while generalizing). Baking the
server files into the image came from the user ("I'm not feeling like
uploading the files from my Mac … for the future I'm not looking for that
approach"). Staging-on-merge with production by hand keeps a person in front
of production on a GitHub plan that enforces nothing.

## Exceptions

- **Previews** use [deploy-preview-with-deployer](../deploy-preview-with-deployer/SKILL.md).
- **Static marketing sites** need no database, migrations or worker. Their
  production hosting is a separate decision (see
  [OPEN_QUESTIONS.md](../../../OPEN_QUESTIONS.md)).
- **Self-hosted runners.** The workflows assume `ubuntu-latest`. On
  self-hosted runners, name every container after the run, clean up in
  `if: always()`, share one persistent BuildKit builder, and cap concurrent
  heavy steps (see [guidelines/ci-cd/testing-in-ci.md](../../../guidelines/ci-cd/testing-in-ci.md)).
- **Backups** aren't included yet: nightly `pg_dump` encrypted with `age`,
  copied off the server, with a heartbeat and a restore drill. They are
  planned, not built.

## See also

- [../../../guidelines/deployment/production-vps.md](../../../guidelines/deployment/production-vps.md) — the rules in short form.
- [../../../guidelines/ci-cd/pipelines.md](../../../guidelines/ci-cd/pipelines.md) — CI conventions these workflows follow.
