# Pipelines

What runs in CI, when it runs, and how workflows are written. GitHub Actions
throughout. A complete set of workflow files for a containerized web app is
in the skill
[deploy-docker-compose-vps](../../skills/deploy/deploy-docker-compose-vps/SKILL.md).

## Full CI from day one

**SHOULD** · 2026-10 · dashboard apps, CLI tool

A new app repo gets the whole pipeline in its first week, as parallel jobs:

| Job | Contents |
| --- | --- |
| checks | format, lint, typecheck, unit tests, generated-file drift checks |
| e2e | Playwright against a **production build**, its own database service, migrate + seed in global setup |
| image | build the production image and run it like the server does (see below) |
| audit | `npm audit --audit-level=high --omit=dev` |
| secret scan | TruffleHog, its own workflow, every PR and push to main |

Plus a PR template and Dependabot (see
[../github/repositories.md](../github/repositories.md)). Where there is a
choice of tool, pick the recommended, widely used option ("let me know what
is recommended and popular and I want our project to have it").

## Every step is a project script

**SHOULD** · 2026-10 → 2026-11 · dashboard apps, CLI tool

CI steps call `npm run <script>` or `make <target>`; no logic inline in the
YAML beyond glue. Every red check can then be reproduced locally with the
same command, and the README lists the local equivalent of each job.

## Concurrency, permissions and timeouts on every workflow

**SHOULD** · 2026-11 · dashboard apps, CLI tool

```yaml
permissions:
  contents: read            # widen per job: packages: write, deployments: write

concurrency:                # CI: a new push makes the old run pointless
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  checks:
    timeout-minutes: 20     # every job has one
```

Release and deploy workflows use `cancel-in-progress: false` with one group
per environment. A deploy cut off halfway is worse than one that waits.
Deploy steps run with `shell: bash` so `pipefail` is on.

## Run only the CI a change needs

**SHOULD** · 2026-10 · dashboard apps

Docs-only commits must not burn Actions minutes ("why are actions triggered
on commits like 'docs:'"). Skip prose and agent folders, but never skip the
secret scan, because it lives in its own workflow without filters. Run heavy
jobs (e2e, image) on PRs; on push to main a quick check is enough. When a
main commit doesn't change anything the image contains, retag the previous
image instead of rebuilding.

```yaml
on:
  pull_request:
    paths-ignore: ["docs/**", "**/*.md", ".agents/**", ".claude/**"]
  push:
    branches: [main]
    paths-ignore: ["docs/**", "**/*.md", ".agents/**", ".claude/**"]
  workflow_dispatch:        # for pushes GitHub lost during an incident
```

## Give push-triggered workflows a manual trigger

**SHOULD** · 2026-10 · dashboard app

Add `workflow_dispatch` to CI and release workflows. During a GitHub incident
a merge's push event was lost and nothing ran. Restrict release jobs with
`if: github.ref == 'refs/heads/main'`, and write main-only conditions as
`github.event_name != 'pull_request'` so they also run on a manual dispatch.
Check githubstatus.com before blaming the repository.

## Build and run the production image on every PR

**SHOULD** · 2026-10 → 2026-11 · dashboard apps

A PR job builds the image (no push) and starts it the way the server does,
against an empty database: migrations run, app and worker start, the health
endpoint answers with the PR's commit (`== $GITHUB_SHA`), a second seed run
is a no-op, and the deploy files are inside the image. Print container logs
on failure, and remove the run's containers and image in an `if: always()`
step.

## Keep actions current, pin security tools exactly

**SHOULD** · 2026-10 · CLI tool, dashboard apps

Pin actions to a major version and let Dependabot move them. Pin security
tools such as TruffleHog to an exact release. When GitHub deprecates an
action runtime, move to the new releases promptly, in their own `ci:`
commit.

## Verify platforms you can't run, through CI

**SHOULD** · 2026-10 · CLI tool

A tool that claims Windows (or Android) support gets a CI job on that
platform that runs its tests and its real installer. With no local machine
for a platform, open a draft PR to get CI evidence before merging. A CLI was
made Windows-compatible entirely through a `windows-latest` job.

**Why:** the user deploys from a Windows PC as well as a Mac ("so I can
connect and deploy from my Windows PC and not just my Mac"), and there is no
Windows machine to test on.

## Don't bypass red CI

**MUST** · 2026-10 · dashboard apps

Fix the cause of a red check. Rerun only failures that are clearly
infrastructure (a package mirror hang, an OOM kill, a runner timeout), and
make the job independent of that infrastructure where you can. A
time-dependent test failure is a bug to fix, not to rerun. See
[testing-in-ci.md](testing-in-ci.md) for telling the two apart.
