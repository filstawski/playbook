# Testing in CI

End-to-end tests, flaky failures, and self-hosted runners. The motion side of
testing (filming transitions, reduced motion) is in
[website-motion](../../skills/website/website-motion/SKILL.md).

## Isolate e2e runs completely

**MUST** · 2026-10 · dashboard app

Run e2e on a dedicated port with `reuseExistingServer: false`, and fail
loudly when that port is taken. Use a dedicated test database, migrated and
seeded in global setup, and a setup project that stores the signed-in
session (`storageState`).

**Why:** Playwright once silently reused another project's dev server on the
same port and tested the wrong app.

```ts
// playwright.config.ts (excerpt)
export default defineConfig({
  webServer: {
    command: "npm run start -- -p 3100",
    url: "http://127.0.0.1:3100",
    reuseExistingServer: false,
    timeout: 10 * 60_000,          // cold production builds on busy runners
  },
  use: { baseURL: "http://127.0.0.1:3100", timezoneId: "Europe/Berlin" },
  projects: [
    { name: "setup", testMatch: /auth\.setup\.ts/ },
    { name: "app", dependencies: ["setup"], use: { storageState: "e2e/.auth/admin.json" } },
  ],
});
```

## Make tests deterministic and self-sufficient

**SHOULD** · 2026-10 · dashboard app

- **Own the preconditions.** Each test sets up the state it needs instead of
  relying on what earlier tests left behind.
- **Find rows by unique data.** Look up rows by unique attributes, not by
  display labels, and give test data unique names.
- **Keep sessions and limits out of the way.** Create extra signed-in
  sessions through the auth API in fixtures, not the UI. Give each test its
  own client IP from a documentation range so lockouts and rate limits don't
  interfere.
- **Wait for the real state.** After a debounced search, wait for the query
  parameter in the URL. On busy servers, wait for hydration before clicking.
  Pin the browser timezone.
- **Keep mocks honest.** A mock must not be more permissive than the real
  system. A mock that always offered an extra answer hid a production bug.
- **Prove the fix.** Reproduce a bug on main first, then show the new test
  fails without the fix and passes with it.

## Run e2e with reduced motion, except motion specs

**SHOULD** · 2026-10 · dashboard app

Playwright waits for elements to stop moving, so a spring-heavy UI makes
every click wait. Run the suite with `reducedMotion: "reduce"` and opt the
specs that test motion back in. Measure each part of a slow job before
changing it; this plus build-cache fixes took one e2e job from 18 to 14
minutes.

## Classify a red job before re-running it

**SHOULD** · 2026-10 → 2026-11 · dashboard app

Read why it failed. Infrastructure failures are a web-server start timeout,
exit 137 (OOM), the job time limit, or a cancelled run; anything else is a
test failure. Re-run only the failed job, alone, after the run's other jobs
finish:

```sh
gh run rerun <run-id> --failed
```

If the same test fails twice, stop re-running and debug it: loop it locally
until it fails and log the inputs. A "flaky" import test that failed twice
the same way turned out to be a real test-data bug. Tell the user that runs
you cancelled show as "failed" on GitHub.

## Shared self-hosted runners: cap the heavy steps

**SHOULD** · 2026-10 → 2026-11 · dashboard app

Several Docker-based runners on one machine let jobs run in parallel, but
concurrent heavy steps (typecheck, production build, e2e, image build)
OOM-killed the box for days. Guard heavy steps with a machine-wide semaphore
so a third one waits instead of crashing. Type-check once per pipeline and
let the other builds skip it. Raise job timeouts so waiting for a slot isn't
a failure.

```sh
#!/usr/bin/env bash
# .github/scripts/heavy.sh run <command…>: run the command in one of N machine-wide slots.
# The lock files live in a folder every runner container mounts at the same path;
# a per-container /tmp would give each runner its own slots and limit nothing.
set -euo pipefail
DIR=/opt/actions-runner/_work/.heavy; SLOTS=${HEAVY_SLOTS:-2}; mkdir -p "$DIR"
shift   # drop "run"
while :; do
  for slot in $(seq 1 "$SLOTS"); do
    exec 9>"$DIR/slot-$slot"
    if flock -n 9; then echo "[heavy] slot $slot of $SLOTS"; exec "$@"; fi
  done
  echo "[heavy] all $SLOTS slots busy, waiting"; sleep 10
done
```

```yaml
- run: .github/scripts/heavy.sh run npm run build
```

Size the slots from measured peaks: a type check used about 6.5 GB and a
build or e2e run 3–5 GB. Image builds that run inside an action (not a
`run:` step) need a variant that takes a slot in one step and gives it back
in a later one.

**Why:** "I want it finally solved." After the fix, image builds dropped from
6–9 minutes to 3.5. Until capacity is fixed, treat load-cancelled e2e jobs
as a capacity problem: verify the touched specs locally on a scratch
database and say so, instead of spinning on re-runs.

## Self-hosted runner setup

**CONSIDER** · 2026-10 · dashboard app

Use a public runner image as several organization-scoped runners, registered
with a fine-grained token limited to self-hosted runners. Mount the host's
Docker socket and the work directory at the same path inside and outside the
runner. Name each run's containers and clean them up in `if: always()`
steps. Keep runners off the production host.

**Why:** self-hosted runners lift the free plan's 2,000-minute cap for
private repos and run jobs in parallel (the user found it "annoying that
only one task is running at once"). A PR's code gets the host's Docker
socket, so runners stay off production.

## Never put credential-shaped URLs anywhere

The rule is in [../backend/security-and-testing.md](../backend/security-and-testing.md#keep-secrets-out-of-logs-urls-and-test-code).
The CI angle: the secret scanner reads every commit of a PR, so even a fake
`postgres://user:pass@host` in a test fails it, and a later fix-up commit
doesn't help. Build connection strings from environment variables at
runtime. Never print tokens in tool output, and mask values when inspecting
env files.

```ts
// do
const url = `postgres://${env.DB_USER}:${env.DB_PASSWORD}@${env.DB_HOST}/${env.DB_NAME}`;
// don't, not even in a test fixture
const url = "postgres://app:secret@localhost/app";
```

## Seed and reset scripts are part of a schema change

**SHOULD** · 2026-10 · dashboard app

After adding a table or foreign key, update the truncate/clear lists in seed
and demo-reset scripts (see
[../backend/data-and-migrations.md](../backend/data-and-migrations.md#demo-and-staging-data)),
and run the reset on a scratch database before pushing. A PR passed every local test and still failed CI on "cannot truncate
a table referenced in a foreign key constraint".

## A site is done when the page check passes

**MUST** · 2026-11 · websites

For a website, "done" means typecheck, lint, format check, a static build and
the browser page check all pass. The page check opens every sitemap page in a
real browser and fails on console errors, broken links, missing metadata or
placeholder text. See
[website-nextjs-site-setup](../../skills/website/nextjs/website-nextjs-site-setup/SKILL.md).
