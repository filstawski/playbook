---
name: deploy-preview-with-deployer
description: >-
  Put a branch or client site on a temporary preview URL with the user's
  self-hosted Deployer: the files a repo needs (Dockerfile, deployer.yaml),
  deploying, updating in place after each push, lifetimes, verification and
  the common failures. Use when asked to preview, deploy for review, share a
  branch or client draft as a link, or fix a failing preview.
metadata:
  type: practice
  category: deployment
---

## Rule

Previews run on [Deployer](https://github.com/filstawski/deployer), never on
Vercel, Netlify or GitHub Pages. This skill is the workflow: when to deploy,
what goes in the repo, how a preview is kept current. Deployer's own agent
skill is the reference for every command, flag and error code. Install it in
the project (`npx skills add filstawski/deployer`) or print it with
`deployer skill`. It always matches the installed CLI, so prefer it whenever
the two disagree.

Deploy only when the user asked for it in this task. When you were asked to
keep a preview current, updating it after each push is part of the job;
otherwise, after a push, offer to refresh it.

### 1. Check access first

```sh
deployer status --json
```

Exit code 3 means you aren't logged in. Ask the user for the server URL and
a token; never guess. Agents and CI get project-scoped tokens. Never run
`token`, `server` or `github` admin commands.

### 2. Add the files (repo root)

The app must listen on `0.0.0.0` on a fixed port and start without real
credentials or outbound internet: a preview is one container, with no
database service, no secrets and 512 MiB of memory.

```dockerfile
# Dockerfile — Next.js site or app
FROM node:24-alpine AS build
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:24-alpine
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1
# owned by node so the image optimizer can write .next/cache
COPY --from=build --chown=node:node /app ./
USER node
EXPOSE 3000
CMD ["npx", "next", "start", "-H", "0.0.0.0", "-p", "3000"]
```

```gitignore
# .dockerignore
.git
node_modules
.next
.env*
!.env.example
*.log
.agents
.claude
.checks
docs/legacy-site/assets
```

```yaml
# deployer.yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/filstawski/deployer/main/schemas/deployer.schema.json
version: 1
source:
  dockerfile: Dockerfile
  context: .
http:
  port: 3000
  healthcheck:
    path: /
    timeout: 2m
# environment:          # plain values only, never secrets: the file is committed
#   NODE_ENV: production
```

For a static export or SPA, build in the first stage and serve the output
with `nginx:alpine` on port 80 (`try_files $uri $uri/ /index.html;`), with
`http.port: 80`. Other stacks: `deployer skill recipes`.

Sites also add a preview-only `noindex` header, keyed on `DEPLOYER_URL`,
which Deployer injects only at preview runtime. See
[guidelines/deployment/deployer.md](../../../guidelines/deployment/deployer.md).

### 3. Validate, fix the lockfile, push

```sh
deployer validate --json
# after ANY dependency change: resolve the lockfile on Linux, or npm ci fails in the build
docker run --rm -v "$PWD:/app" -w /app node:24-alpine npm install --package-lock-only
git add Dockerfile .dockerignore deployer.yaml package-lock.json
git commit -m "build: add Deployer recipe"
git push -u origin HEAD
```

The server builds the pushed commit, never your working tree, so committing
and pushing come first. They need the user's approval: an explicit "deploy
it" for changes they have seen counts, as does a task brief that grants
commit and push.

### 4. Deploy once

```sh
deployer deploy --ref feat/new-home --name new-home --ttl 14d \
  --idempotency-key "<task>-feat-new-home" --json
```

- **Name.** Short and readable; it becomes `https://<name>.<PREVIEW_DOMAIN>`.
- **Lifetime.** Choose it deliberately: 1 day for a quick check, 14 days for
  a client review. Longer than the server's maximum needs an admin to raise
  `deployments.max_ttl`.
- **Exit code first.** Read the exit code, then `error.code` and
  `error.hint`. Don't retry `BUILD_FAILED` or `HEALTHCHECK_FAILED`
  unchanged; read `deployer logs <name> --build --json` first.

### 5. Report it

The URL, what it shows (branch and commit), when it expires, and the command
to extend it:

```text
Preview: https://new-home.<PREVIEW_DOMAIN> (feat/new-home @ 3f2a9c1)
Expires 2026-11-16. Extend with: deployer extend new-home --by 14d
```

### 6. Keep it current

```sh
deployer update new-home --json                 # after each push to its branch
deployer update new-home --ref feat/v2 --json   # point it at another branch
deployer extend new-home --by 14d --json        # keep the same URL alive longer
deployer destroy new-home --yes --json          # done with it
```

`update` builds the new commit while the old one keeps serving, and rolls
back if the build fails. Extending keeps the URL, so links already sent to a
client keep working. Before a client meeting, check the expiry and the
pinned commit:

```sh
deployer inspect new-home --json   # state, deployment.commit, expires_at
```

"Is the latest version deployed?" is answered by comparing
`deployment.commit` with `git rev-parse origin/<branch>`, not by looking at
GitHub.

### 7. Verify

```sh
deployer inspect new-home --json                      # state: running
curl -sI https://new-home.<PREVIEW_DOMAIN>/ | sed -n '1p;/x-robots-tag/Ip'
```

Then open it in a browser. While a build runs, the URL shows a progress page
(503) that reloads into the app.

### Common failures

| Symptom | Cause → fix |
| --- | --- |
| `npm ci` "Missing: @emnapi/… from lock file" | lockfile written on macOS → re-resolve in `node:24-alpine`, push, `update` |
| `HEALTHCHECK_FAILED` connection refused | bound to localhost or the wrong port → `-H 0.0.0.0`; standalone Next needs `HOSTNAME=0.0.0.0`; match `http.port` |
| `HEALTHCHECK_FAILED` 404/500 | wrong health path → `/` or a real route; slow start → raise `timeout` (≤ 5m) |
| Container exits / 502 | crash on missing config, unreachable DB, out of memory → `deployer logs <name>`; make the app start without secrets or egress |
| Assets or API calls go to localhost | build-time values baked in; `DEPLOYER_URL` exists only at runtime → relative URLs or runtime reads |
| "Invalid host header", redirect loops | allow `*.<PREVIEW_DOMAIN>`; trust `X-Forwarded-Proto` |
| `SOURCE_FAILED` "branch not found" | not pushed → `git push -u origin <branch>` |
| `SOURCE_FAILED` "private or does not exist" | the server's GitHub App isn't installed on the repo owner → ask the user (admin task) |
| `NAME_TAKEN` / `QUOTA_EXCEEDED` | pick another name / destroy your unused or failed previews |
| Old code shown | previews don't follow branches → push, then `deployer update <name>` |

## Why

The user built Deployer in October 2026 to replace an earlier tool that could
only publish static exports to GitHub Pages. Every repo touched since has a
`deployer.yaml`, and client previews go there "rather than Vercel".
The lockfile row is first in the table because it broke the first preview
of four different projects. "Deploy once, update in place" exists because a
client keeps the link they were sent.

## Exceptions

- **Production is not a preview.** Apps with a database and real users
  deploy with
  [deploy-docker-compose-vps](../deploy-docker-compose-vps/SKILL.md).
- **Multi-service apps** (a database, a worker, secrets) don't fit a single
  preview container yet. Use SQLite or sample data for the preview, or skip
  it and say so.
- **Command details change with Deployer releases.** When this skill and
  `deployer skill` disagree, the latter wins.

## See also

- [../../../guidelines/deployment/deployer.md](../../../guidelines/deployment/deployer.md) — how Deployer works, and the rules around it.
- [git-commit-requires-approval](../../git/git-commit-requires-approval/SKILL.md) — pushing for a preview is still a commit that needs approval.
