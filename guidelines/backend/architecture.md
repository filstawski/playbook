# Backend architecture

How server code is organized. For full-stack Next.js apps the detailed shape
is in the skills
[website-nextjs-fullstack-layered-architecture](../../skills/website/nextjs/website-nextjs-fullstack-layered-architecture/SKILL.md)
and
[website-nextjs-fullstack-server-actions](../../skills/website/nextjs/website-nextjs-fullstack-server-actions/SKILL.md);
for a separate TypeScript API, the [api skills](../../skills/api/README.md).
Both are for multi-user apps with a real backend. Many projects instead use a
separate API with an SDK, or have no backend at all.

## Feature modules; only the repository touches the database

**MUST** · 2026-10 → 2026-11 · dashboard apps (5 sources)

Each feature lives in `src/features/<domain>/` with `schemas`, `repository`,
`service`, `queries` and `actions` (plus `labels` and `types` where needed).

- Only a feature's own repository imports the database client.
- Other features call its service or queries, never its repository.
- Client components never import service or repository code.

Enforce this with ESLint `no-restricted-imports`, so a violation is a lint
error rather than a review comment.

```js
// eslint.config.mjs (excerpt)
{
  files: ["src/**/*.{ts,tsx}"],
  ignores: ["src/features/*/repository.ts", "src/lib/db.ts"],
  rules: {
    "no-restricted-imports": ["error", {
      patterns: [
        { group: ["@/lib/db", "@prisma/*"], message: "Only a feature's repository touches the database." },
        { group: ["@/features/*/repository"], message: "Use the feature's service or queries." },
      ],
    }],
  },
}
```

## Keep the repository layer even when the ORM looks like enough

**SHOULD** · 2026-10 · client dashboard app

A repository between services and the ORM assembles domain objects from
several tables, writes them in one transaction, and hides storage quirks
(integer booleans, JSON casts, null versus undefined, search the database
can't do). Storage then changes in one place.

**Why:** storage changed three times in one project (in-memory mocks → ORM
v7 → ORM v8), and each time only the repositories changed.

## Service import cycles only fail the production build

**MUST** · 2026-10 → 2026-11 · dashboard app

Cycles between feature services pass the dev server, the typecheck and the
unit tests, then fail `next build` with "Cannot access 'x' before
initialization". Run a production build whenever cross-feature service
imports are added. To break a cycle, move the shared read into a small
module beside the service that imports no other services.

## Subsystems are catalogues of definitions

**SHOULD** · 2026-08 → 2026-10 · dashboard apps, API project

New subsystems (email, notifications, jobs, permissions, imports, documents,
search) all follow one shape:

- a `defineX(...)` next to the feature that uses it;
- a catalogue that derives the types;
- an outbox or job queue for delivery, with retries and visibility;
- pluggable transports and safe modes.

Adding a case means adding one definition file. When behaviour varies by
type or by changed field, declare it in one registry table that generic code
iterates. Never use another `if` branch or a per-subclass override ("the
if, if, if stuff is annoying to maintain").

```ts
// One row per changed field; generic update code runs amend before the write, apply after commit.
export const fieldEffects = defineFieldEffects<User>({
  email: { amend: (data) => ({ ...data, emailVerified: false }), apply: (user) => sendVerifyEmail(user) },
  username: { apply: (user, old) => redirects.add(`/u/${old.username}`, `/u/${user.username}`) },
});
```

See [api-manager-declarative-config](../../skills/api/managers/api-manager-declarative-config/SKILL.md)
and [extract-reusable-primitives](../../skills/extract-reusable-primitives/SKILL.md).

## Watch the abstraction budget

**CONSIDER** · 2026-08 · API project

Moving duplication into a base layer is wanted ("managers should be very
lean"). Once the base needs around fifteen concepts to understand, say so
and offer to stop; the user has chosen to keep things as they are rather
than add another round of abstraction.

**Why:** after several rounds of moving code into the base layer, the user
found the managers "heavy and complicated" and decided to keep them as they
were.

## Rewrite a core layer next to the old one

**SHOULD** · 2026-08 · API project

For a large redesign of a shared layer, build it in a new folder (`v2/`)
without touching the current files. Port one model per step, keeping the
project typechecking after each, and track progress in a guide with a
port-status table (see
[docs-migration-status-tracking](../../skills/docs/docs-migration-status-tracking/SKILL.md)).
Call out behaviour bugs fixed during a port.

**Why:** the user wanted the redesign kept apart from working code ("Do not
make changes to any current files. Work just within v2/"), and routes move
to it one at a time.

## Never drop typed error handling in a refactor

**MUST** · 2026-08 · API project

When moving logic into a service layer, keep the existing error mapping. The
service throws a typed domain error, and the route maps it to an HTTP
response. A refactor that lets provider errors bubble up raw is a
regression, not a simplification.

**Why:** a proposed refactor of a create method lost the provider-specific
error handling the old code had, and the user caught it ("doesn't have any
proper error handling?").

## Don't write helpers that only reshape what the library accepts

**SHOULD** · 2026-10 · client dashboard app

Prisma ignores `undefined` filters, so pass `where: { status, type }`
directly instead of building a helper that strips empty keys. Anything done
in code after a query (locale-aware search or sort the database can't do)
gets a one-line comment saying why.

## Build features mock-first behind the repository

**SHOULD** · 2026-10 · client dashboard app

Start a new feature on in-memory mocks behind the repository interface
before adding a database or a user system ("if you can do the emails in
memory first, I'd appreciate it more than having a database right now").
Store mocks on `globalThis` so they survive hot reload. Generate them from
the app's own rules and check them for consistency; later they become the
seed. See [same-import-upgrade-path](../../skills/same-import-upgrade-path/SKILL.md).

## Reuse generic models before adding tables

**CONSIDER** · 2026-11 · dashboard app

Before a new table, check whether an existing polymorphic model fits. For
example, comments became notes with a new subject type: no migration, and
author checks came for free. Key saved views generically by list so other
lists can reuse them.
