# Dependencies and lockfiles

The rules that kept builds reproducible across a macOS laptop, CI runners and
Linux servers.

## Resolve the lockfile on Linux after every dependency change

**MUST** · 2026-10 → 2026-11 · websites, dashboard apps (hit in 4+ repos)

npm on macOS prunes optional packages that only Linux needs (for example the
`@emnapi/*` WebAssembly helpers). The lockfile then looks fine locally, and
`npm ci` fails in CI, in the Docker build and on the preview server with
"Missing: … from lock file". After adding, removing or upgrading any
dependency, write `package-lock.json` inside a Linux container that uses the
same Node major as the image:

```sh
docker run --rm -v "$PWD:/app" -w /app node:24-alpine \
  npm install --package-lock-only
docker run --rm -v "$PWD:/app" -w /app node:24-alpine npm ci   # verify
npm ci                                                         # and on the Mac
```

Don't run `npm install` on macOS again afterwards; it reverts the fix. Use
the npm version the servers use (`npx -y npm@<version> …`) when it differs
from the laptop's. Review the lockfile diff after any CLI that installs
packages on its own (scaffolders, `init` commands).

**Why:** the first preview deploy of several sites failed at `npm ci`, and
one later fix was silently undone by a CLI's `init`.

## Never cache node_modules between CI runs

**MUST** · 2026-10 · dashboard apps (4 sources)

Every job runs a fresh `npm ci` ("Do not keep node modules, I'm not happy
with it"). Caching npm's download cache (`actions/setup-node` with
`cache: npm`), Next's `.next/cache` per runner, and Docker layers or a
BuildKit `--mount=type=cache,target=/root/.npm` are all fine. Look for speed
in tests, builds and machine capacity before raising node_modules caching
again, and only if the user does.

## Security updates: a patched release that has aged two weeks

**CONSIDER** · 2026-11 · company website · unconfirmed as a standing rule
([OPEN_QUESTIONS.md](../../OPEN_QUESTIONS.md) #22)

For an advisory, pick the newest release that fixes it and has been out for
at least two weeks (`npm install <pkg>@<version> --before=<date>`). Never use
`npm audit fix --force`. Verify by comparing the old and new production
builds on every route (status, headers, head metadata, OG images, console
errors), and tell the user to restart a running dev server.

**Why:** freshly published versions are where supply-chain attacks land; the
same reasoning gives Dependabot a seven-day cooldown. Dependabot's own
security PRs skip that cooldown on purpose; this entry is about choosing a
version by hand.

## Fix unrelated advisories in their own PR

**SHOULD** · 2026-10 · client website

If a feature PR's audit job fails on an advisory that has nothing to do with
the feature (the framework version already on main), open a minimal bump PR
first. Get it merged, then merge main into the feature branch for a fresh
run.

## Add a dependency that is already in the tree without churn

**CONSIDER** · 2026-11 · dashboard app

For a package already installed transitively at the wanted version, add it
to `package.json` and to the lockfile's root entry by hand, then run
`npm ci`. The diff stays a few reviewable lines instead of a re-resolved
lockfile.

## Ask before bumping versions

Version bumps wait for the user's yes, unless they asked for a dependency
pass: see [../stacks/choosing-dependencies.md](../stacks/choosing-dependencies.md).
Runtime majors (Node, its types, the base image) move together as one
deliberate step to the next LTS.
