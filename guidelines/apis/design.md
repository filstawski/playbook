# API design

Contracts, inbound and outbound endpoints between the user's own apps, links
that act, and command-line interfaces. Route and handler structure for a
TypeScript API is in the [api skills](../../skills/api/README.md).

## Contracts are append-only; errors carry a code, a message and a hint

**SHOULD** · 2026-10 · deployer, dashboard apps

Never rename JSON fields, error codes or exit codes; add new ones. Guard the
contract with fixture files that every client (including a mobile app)
decodes in its tests. A user-facing error has a stable machine code, a plain
message, and, when there's an obvious next step, a hint with the exact
command or action.

```json
{ "error": { "code": "NAME_TAKEN", "message": "A preview called 'demo' already exists.",
             "hint": "Pick another name, or run: deployer destroy demo --yes" } }
```

## Inbound endpoints from sibling apps

**SHOULD** · 2026-10 · dashboard app + company website

When one of the user's apps posts into another (a website sending inquiries
to a CRM):

- **Key.** Generate it in the receiving app's settings: password-confirmed,
  shown once, stored hashed with a visible prefix. Compare it with
  `timingSafeEqual`.
- **Path and status codes.** Version the path (`/api/v1/...`). Answer 201
  for created, 200 for a replay, 400 / 401 / 413 / 429 with `Retry-After`.
- **Retries and limits.** Deduplicate retries by an `Idempotency-Key` header
  under an advisory lock. Rate-limit wrong keys per IP (about 10 per 15
  minutes) and cap total intake per hour.
- **Audit.** Record each intake with a system actor.

The sender calls it only after its own primary action succeeded. It sends a
fresh UUID as `Idempotency-Key` per submission and retries three times after
0, 2 and 8 seconds, honoring `Retry-After` up to 30 seconds. 400, 401 and 413
are final. It logs only the request key, never the payload.

**Why:** the user chose "a key made by the app" over other ways to connect,
and a retry must never create a duplicate record.

## Return to the requested page after sign-in, same origin only

**SHOULD** · 2026-10 · client dashboard app

Middleware (proxy) only forwards the requested path. The auth check stays
where data is read, and redirects to `/sign-in?next=<path>`. Accept `next`
only if it resolves to the app's own origin and isn't the sign-in page:
reject `//host` and `/\host`. Signed-in visitors pass straight through.

```ts
export function safeNext(next: string | null, origin: string): string {
  if (!next || !next.startsWith("/") || next.startsWith("//") || next.startsWith("/\\")) return "/";
  const url = new URL(next, origin);
  return url.origin === origin && url.pathname !== SIGN_IN_PATH ? url.pathname + url.search : "/";
}
```

## Links in emails never change state on GET

**MUST** · 2026-10 · client dashboard app

A link in an email opens a page. The state change (confirm, sign in,
consent, unsubscribe) happens when the visitor presses a button on that page.
Mail scanners and link previews follow every link.

## Sharing files with external people

**CONSIDER** · 2026-10 · client dashboard app

Store only a hash of the link token, and expire it (for example after 30
days). A new link closes the previous one. The email carries only the link,
no data. The page reveals nothing until the recipient enters a short-lived
code sent by email; then a short session cookie takes over. Log every open
and download.

## Command-line interfaces: friendly at a terminal, stable for scripts

**SHOULD** · 2026-10 · deployer

At a terminal (TTY):

- Show rich panels for single results, colour on the key facts, and compact
  tables for lists.
- Replace required flags with a pre-filled form with smart defaults. Ask for
  missing arguments with pickers or confirmations.
- Every flag skips its question, and `-y` skips the whole form.

Without a TTY, with `--json`, in CI or for agents:

- Behaviour and output stay unchanged, and nothing ever prompts.
- `--json` prints exactly one JSON value on stdout.
- Exit codes are documented and distinct (ok, failed, invalid input, auth,
  timeout, not found).

Honour `NO_COLOR`. Keep command names the user chose. An agent skill shipped
with the CLI changes in the same commit as the CLI.

**Why:** the user finds flags tedious at a terminal, while agents and CI need
output they can parse.
