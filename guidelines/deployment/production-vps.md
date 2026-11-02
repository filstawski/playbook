# Production on a VPS

The production pattern used for web apps with a database: one Docker Compose
project per environment on a VPS, behind the host's nginx, with images built
in CI. The full procedure and every file (Dockerfile, compose file, deploy
script, nginx site, workflows) are in the skill
[deploy-docker-compose-vps](../../skills/deploy/deploy-docker-compose-vps/SKILL.md).

## One Compose project per environment, behind the host's nginx

**SHOULD** · 2026-10 → 2026-11 · dashboard apps (2 apps, plus a demo)

- **Layout.** Each environment (staging, production) is its own Compose
  project in its own folder with its own `.env`.
- **Ports.** The app binds to `127.0.0.1`, and the host's nginx terminates
  TLS (certbot) and proxies to it. The database has no host port.
- **Containers.** App containers run as non-root, with `no-new-privileges`,
  all capabilities dropped, an init process, rotated logs (10 MB × 5) and a
  health check.
- **Access.** The CI deploy key is bound in `authorized_keys` with
  `command="<deploy script>",restrict`, so it can do exactly one thing.
  Running the stack as root is acceptable when that's simpler: a dedicated
  user in the `docker` group is root-equivalent anyway.

## The image carries its own server files

**MUST** · 2026-10 · dashboard apps

The compose file, deploy script, backup script and nginx sites are baked
into the release image. Each deploy takes them from the image of the commit
it deploys, so a rollback brings its own scripts back. Never copy files to a
server by hand ("I'm not feeling like uploading the files from my Mac").
Server setup is: pull the image, extract the deploy script, and run an
idempotent `setup` that creates folders, `.env` files with generated secrets
(mode 600), certificates and nginx sites, doing only what's missing. The user
only adds DNS records and pastes the secrets they own.

## The previous release's deploy script runs first

**MUST** · 2026-10 · dashboard app

A self-replacing deploy script only takes effect on the next run, so the
first deploy after a change still runs the old script with the new compose
file. Never make a new setting required (`${VAR:?}`) in the same release that
teaches the deploy script to write it. Put new services behind a Compose
profile or give variables safe defaults, and check with
`docker compose config` against an `.env` as it was before the change.

## Migrations run alone first, written expand/contract

**MUST** · 2026-10 · dashboard apps

Deploy order: run migrations as a one-shot service in its own profile (never
a `depends_on` of the app), then `up -d --remove-orphans`, then poll the
health endpoint for up to two minutes, checking the build commit and that the
worker hasn't restarted. A failed migration leaves the previous version
running. Write migrations expand/contract: add before use, drop only once no
deployed image reads it. Rolling back is then just deploying the previous
commit's image.

**Why:** migrations don't roll back, so expand/contract keeps the previous
image working against the newer schema. Compose stops dependents before
recreating a dependency, which rules out `depends_on` for migrations.

## Health endpoint reports the build commit

**SHOULD** · 2026-10 · dashboard apps

`/api/health` returns the commit the image was built from. CI asserts it
equals the PR's SHA, and every deploy checks it from outside after the
switch. A deploy summary says "`<env>` runs `<sha>`. Before: `<old sha>`." so
the rollback target is always written down.

**Why:** a worker once read its build commit at runtime, always got null,
and silently broke a feature that was caught only later. The CI assertion
now guards against that.

## Staging gets every merge; production is started by a person

**SHOULD** · 2026-10 → 2026-11 · dashboard apps, company website

With staging: each main commit is published and deployed to staging
automatically, and production is a manual workflow dispatch with the commit
that was checked on staging. Without staging (a simple marketing site), a
green CI run on main deploys straight to production. Both are deliberate
per-project choices.

Staging runs on realistic made-up seed data, never a copy of production. Tie
the seed to a hash of the seed files plus the schema, so a deploy re-seeds
only when they change and testers' edits survive otherwise. The reset
command refuses to run on production.

## Never prune globally on a shared host

**MUST** · 2026-10 · dashboard apps, demos

One VPS hosts several apps. Never run `docker system prune`,
`docker volume prune` or `docker compose down -v` there. Clean up only your
own images by repository name (keep the newest five for rollback) and only
resources carrying your own labels.

**Why:** the same host runs other apps, demos and the preview server, and a
volume prune would delete their data.

## Don't touch servers unless asked

**MUST** · 2026-10 · dashboard apps, client demo

Don't SSH into or change a shared or production server unless the user asked
for it in that task. When the user will deploy by hand ("do not actually do
the whole CI/CD pipeline, I will deploy it manually"), deliver the
Dockerfile, compose file, nginx site, `.env.example` and a runbook, and
skip CI/CD.

**Why:** the by-hand case was a client demo for one meeting, which didn't
justify a pipeline; production would later run on the client's own server.

## A manual deploy builds on the server

**SHOULD** · 2026-10 · client demo

For a by-hand deploy, clone the repo on the server and build there: pull,
tag the image with the short commit hash, build, set the tag in `.env`,
migrate, `docker compose up -d`. Don't make the user cross-build amd64 on a
laptop and ship a multi-GB image over SSH. Give one paste-able block per step
with its expected output.

**Changed:** the first runbook (2026-10-22, morning) built on the laptop and
shipped the image with `docker save | ssh docker load`. That produced a
string of failures ("I'm on my server. How do I deploy this, it can't be
that hard"). Building on the server worked the same day.

## Distinct names for dev and server config

**SHOULD** · 2026-10 · client demo

Don't keep two files called `compose.yaml` or `.env.example` (one at the repo
root for development, one in `deploy/` for the server): the user copied the
development ones to the server twice. Name them distinctly, or have the
runbook copy to an explicit target name. Required variables use
`${VAR:?message}`, and when a template gains keys, diff its keys against the
live `.env`.

## Walk the user through server work one safe step at a time

**SHOULD** · 2026-10 · dashboard app

Start with read-only diagnostics the user runs and pastes (OS, versions, free
disk and RAM, ports in use, existing certificates). Check free ports before
choosing one. Give short commands that can't wrap when pasted. Ask for
configuration with commands that don't print secrets. While SSH access is
being changed, tell the user to keep their current session open.

**Why:** during a first install, the read-only output the user pasted showed
a port conflict, so the next command could use another port and the install
went through.

## Take ops commands from the deploy doc

**MUST** · 2026-10 · dashboard app

For an ops question, use the canonical command from the project's deploy
doc, not from a script header. Ops tasks are Compose profiles
(`--profile ops run --rm <task>`). Commands against a compose file in a
subfolder need `--env-file`. Never offer `down -v` or a reseed when the user
wants to resync something a script already handles ("I don't want to
reseed, we've got a script for it").

**Why:** an agent first suggested dropping the database volume, then gave a
command without `--env-file` that failed silently. The user had to push back
twice before the deploy doc's version came up.

## Backups: off-site, encrypted, monitored, restore-tested

**CONSIDER** · 2026-10 · dashboard app

Back up a production database with nightly encrypted (`age`) dumps to
off-site storage, with the private key only in the password
manager and never on the server, a heartbeat that alerts on a missed night,
and a restore drill before relying on them. The user deferred this once
in favour of features ("screw backups for now"); raise it again before a
launch with real data.

## Domains: one canonical host, permanent redirects

**SHOULD** · 2026-11 · company website

Secondary domains redirect every path to the same page on the main domain,
with the query kept: 308 once the target exists, 307 to the home page until
it does, so nothing gets cached permanently by mistake. Don't serve a
language on its own domain. Before launch, map every old URL to its closest
new page in one permanent hop.

**Why:** serving a language on its own domain broke cross-domain hreflang
and split links between the domains.
