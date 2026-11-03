# Security and testing

Server-side hygiene that came up in practice, and how backend code is
tested. Auth and permissions have their own file:
[auth-and-permissions.md](auth-and-permissions.md).

## Keep secrets out of logs, URLs and test code

**MUST** · 2026-10 → 2026-11 · dashboard apps

Never write `user:password@` into a URL literal, tests included; build
connection strings from environment variables at runtime. Never print
secret values, and mask env files when showing them. Never send the user's
third-party API keys anywhere. Turn off framework logging that echoes
server-function arguments, because it printed passwords in dev logs:

```ts
// next.config.ts
const nextConfig: NextConfig = { logging: { serverFunctions: false } };
```

## Renders have no side effects

**SHOULD** · 2026-11 · dashboard app

Link prefetching renders guarded pages on the server, so a render must not
write audit entries or anything else. Record "viewed" events from the
browser once the page is actually shown, or in actions.

## Fetch user-supplied URLs only to public addresses

**SHOULD** · 2026-10 · dashboard app

Background jobs that fetch websites users entered must resolve the host and
allow only public addresses (block private, loopback and link-local, for IPv4
and IPv6). Make this switchable off in tests, and use reserved `.example`
domains in mock data.

## Uploads: signed, sniffed, versioned

**SHOULD** · 2026-10 · dashboard app

Browsers upload straight to S3-compatible storage with a short-lived signed
URL (about 10 minutes); the app never holds the bytes. Before a record
accepts an upload, sniff its first bytes:

- Refuse executables, whatever the file is named.
- Quarantine files whose name and content disagree.
- Sweep unfinished uploads after about an hour.

Keep the allowlist broad ("as few limitations as possible") but checked.
Versions are never overwritten, and every open of a sensitive file is
audited.

Decode uploaded text in this order: a UTF-16 BOM, then strict UTF-8, then
Windows-1252. Node's `TextDecoder("windows-1252")` behaves as Latin-1, so
map 0x80–0x9F by hand. Detect CSV separators from the first line; regional
spreadsheet exports use `;`.

**Why:** the user wanted documents to refuse files like ".exe or .sh" but
otherwise to have "as few limitations as possible".

## External share links act as their maker

**SHOULD** · 2026-10 · dashboard apps

A share token is 32 random bytes (base64url), stored only as SHA-256 and
shown once. Access is re-checked with the maker's current permissions, so
the link dies when they leave or lose the permission, and when it expires,
is revoked, or the item is trashed. An optional password is hashed (scrypt)
and rate-limited per link and IP. Cap what an unauthenticated link can
write.

## Operations survive crashes and concurrent writes

**SHOULD** · 2026-10 · deployer, dashboard apps

- **Crashes.** Background handlers run again after a crash: record progress
  immediately, and adopt resources an earlier attempt created.
- **Atomic changes.** Multi-step changes go through one transaction.
- **Concurrent writes.** Read-then-write paths use compare-and-swap
  (`update … where status = <expected>`).
- **External resources.** Touch only those labelled as yours.
- **Subprocesses.** Run them directly, never through a shell.

For a per-user work queue, claim items with
`FOR UPDATE SKIP LOCKED`, keep a heartbeat while the screen is open, and
sweep claims from closed tabs.

## Prefer real dependencies in tests

**SHOULD** · 2026-10 · deployer, dashboard apps

Every behaviour change ships with tests and updated docs. Use real
dependencies where you can: Postgres in a container, real HTTP, real Git, a
full in-process server. Point external integrations at a configurable base
URL, and run a small stand-in server for them in e2e tests, with reset
endpoints and helpers to simulate events. Take the clock in hand for time
rules.

## Local infrastructure that doesn't collide

**SHOULD** · 2026-10 · dashboard app

- **Ports.** Run local Postgres through Compose on a non-default host port
  (e.g. 5433), so other projects keep theirs, and pick ports that are free.
- **Databases.** Use a separate database for e2e tests.
- **Environment.** Validate env variables with Zod at boot and name the
  missing one.
- **Health.** Expose a health endpoint that returns 503 when the database or
  worker is unreachable.
- **Other projects.** Never stop another project's running dev server.

**Why:** e2e tests once silently reused another project's dev server on the
same port and checked the wrong app.

```ts
// src/lib/env.ts
const Env = z.object({
  DATABASE_URL: z.string().url(),
  AUTH_SECRET: z.string().min(32),
  RESEND_API_KEY: z.string().startsWith("re_").optional(),
});
export const env = Env.parse(process.env); // throws naming the missing/invalid key
```
