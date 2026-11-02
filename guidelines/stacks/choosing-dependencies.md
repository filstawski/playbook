# Choosing dependencies

Who decides on libraries, versions and providers, and how a choice is
prepared. The defaults themselves are in [web-stack.md](web-stack.md).

## Library, version, ORM and provider choices are the user's

**MUST** · 2026-10 → 2026-11 · every project type (7 sources)

Recommend, then wait for an explicit yes before installing anything. Present
two options with their trade-offs and your pick. That applies to a ZIP
library, a PDF renderer, a drag-and-drop kit, an ORM major or a hosting
provider alike. Never switch to a different major, or "downgrade to stable",
on your own.

**Why:** an agent moved a project from the release-candidate ORM major the
user had chosen back to the stable one ("why you switched to prisma 7? I want
to use 8").

## Prefer what's already installed

**MUST** · 2026-11 · dashboard app

Before adding even an approved dependency, check whether an installed one
already does the job, and whether the package is deprecated or renamed. If
it is redundant, drop it and tell the user. An approved QR-code package
turned out to be deprecated, and an installed library already rendered QR
codes. Don't rely on a library that is only present as someone else's
transitive dependency; add it explicitly or don't use it.

## Versions: at least a week old, LTS runtimes, aligned majors

**SHOULD** · 2026-10 · dashboard apps

Pick the newest release that has been out for at least seven days, matching
the Dependabot cooldown, as protection against freshly published malicious
versions. For security fixes picked by hand, a two-week bar was applied once and is
still an open question (see
[../ci-cd/dependencies-and-lockfiles.md](../ci-cd/dependencies-and-lockfiles.md)).
Run only LTS Node (even majors, not end-of-life). Keep `.nvmrc`,
`engines.node`, the Docker base image and `@types/node` on the same major.
Skip majors the toolchain doesn't support yet (e.g. a TypeScript major the
lint plugin rejects), and note the reason in the Dependabot ignore rule.

## Pin release candidates exactly

**MUST** · 2026-10 · dashboard apps

When the user picks a release candidate, pin it and every sibling package
that must share its toolchain version exactly, with no caret. A newer sibling
RC broke every code-generation run.

## Read the bundled docs before writing code

**MUST** · 2026-11 · websites, dashboard apps

Frameworks and libraries newer than the model's training data ship their own
docs. Read them before using an API:

- Next.js: `node_modules/next/dist/docs/`.
- Installed library skills (for example the ORM's skill).

Next.js 16 differs from what models remember: `proxy.ts` replaces
middleware, `params` are Promises, `next build` no longer lints, and
`PageProps`/`LayoutProps` come from `next typegen`. Keep the agent-rules
block that `next dev` writes into `AGENTS.md`, and commit it as is.

**Why:** several Next.js 16 behaviours were discoverable only from the
bundled docs, and stale assumptions broke routes and transitions.

## Tooling stays out of production dependencies

**SHOULD** · 2026-10 · dashboard app

CLI generators (shadcn, code generators) go in `devDependencies`, and CI
audits production dependencies only (`npm audit --omit=dev`), so the audit
means something. When a peer or optional link drags a CLI into production
dependencies, use npm `overrides` to patched versions, and note when the
override can go.

## Upgrade packages that move together in one PR

**SHOULD** · 2026-10 · dashboard app

Framework and plugin pairs, an ORM and its generator, a runtime and its types
are upgraded together in one PR. The user picks the target version.
Dependabot PRs that split such a pair are closed and replaced.
