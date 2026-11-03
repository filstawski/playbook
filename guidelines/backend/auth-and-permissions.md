# Auth and permissions

Sign-in, account security, and authorization in multi-user apps. The full
pattern is in
[website-nextjs-fullstack-rbac](../../skills/website/nextjs/website-nextjs-fullstack-rbac/SKILL.md).
None of this is a default for a simple site or a single-user tool.

## Every entry point declares who may call it

**MUST** · 2026-10 → 2026-11 · dashboard apps (5 sources)

Server Actions and route handlers are public endpoints, reachable directly
whether or not any page offers them. Every page, query, action and route
declares its requirement through its wrapper; a missing declaration is a
type error, and lint enforces it. Deny by default. The UI only hides things.
"No page offers that action" is not protection.

```ts
export const archiveProject = defineAction({
  access: "staff",
  permission: "projects.archive",
  schema: ArchiveProjectInput,
  handler: async (viewer, input) => projectService.archive(viewer, input.id),
});

export default guardPage({ permission: "projects.view" }, ProjectsPage);
```

Queries call the permission check themselves, because layouts don't re-run
on client navigation. When a new subject joins a generic mechanism
(documents, trash, notes), give it explicit rules. Related lookups must
agree: if a user may pick a record in a search, fetching its details must not
refuse.

**Why:** in a review of code another agent wrote, every staff action was
still open. In another app, a new document type without its own rules let
anyone with a generic delete permission trash an immutable PDF by calling
the action directly.

## Roles are data, permissions are code, and nobody is named

**MUST** · 2026-10 · dashboard apps (6 sources)

- Permissions form a catalogue in code (`domain.verb[.scope]`, with
  `implies` and a `sensitive` flag).
- Roles are rows the customer manages, plus a protected administrator role
  that holds every permission automatically.
- Never write `role === "admin"`, a fixed role union, or a person's name in
  code ("when I say <person>, I don't mean only us, and I don't want code
  references for that").

Guardrails:

- A user can grant only what they hold, and nobody edits their own role.
- The last administrator can't lose admin.
- Per-user overrides carry a reason and an optional end date.

Four-eyes approval blocks small teams. Add a separate permission that allows
approving your own request, recorded visibly as "self-approved".

**Why:** the user wanted roles "dynamic and manageable" in the app's
settings, not hardcoded. Strict four-eyes approval left a lone admin asking
"I am admin and it says I have to ask someone else?"

## Ask for the password again on sensitive actions

**SHOULD** · 2026-10 · dashboard apps

Re-confirm the password for deploys and rollbacks, connecting an
integration, creating API keys or personal tokens, granting permission
exceptions, and changing payout details. For payout changes, also notify the
other administrators: a swapped bank account is the classic
payment-diversion fraud.

## Account-security emails are expected

**SHOULD** · 2026-10 · client dashboard app

Email the account owner on a sign-in from a browser the account hasn't used
before (time, browser and OS, IP). Also email when 2FA is set up or
removed, backup codes are regenerated, the password changes, or access
changes. Send through the outbox so sign-in never waits.

**Why:** "I didn't get an email for something like 'login from a new
location' … I explicitly told you earlier that I want emails about such
stuff."

## Sign-in hardening defaults

**SHOULD** · 2026-10 · dashboard apps

- **Accounts.** Sign-up is off; administrators create accounts. Passwords
  are at least 12 characters, including on admin-created accounts.
- **Second factor.** Mandatory TOTP, with backup codes the user must
  acknowledge.
- **Lockout.** After 5 wrong passwords or codes, lock for 15 minutes,
  doubling up to a day. Show "locked until", notify the owner, and give
  admins an unlock.
- **Password reset.** Always the same answer whether the account exists or
  not. Rate-limit per address and per IP. The link works once, for about an
  hour. Signing in afterwards still needs the second factor. All sessions
  are revoked.
- **Expired or malformed sessions** degrade to signed-out, never to a 500
  that leaves users unable to sign out.

## Audit the auth library's own endpoints

**SHOULD** · 2026-10 · client dashboard app

Check every built-in endpoint of the auth library against your rules, and
disable those that skip your validation or audit log. In one library: a
generic update-user endpoint accepted an empty name, list-sessions returned
tokens, an email-change link signed in on GET, and a plugin allowed
passkey-only sign-in. Route those steps through your own validated, logged
actions. Account creation happens only in a server-only step that no HTTP
request can reach.

## Scope selectors clamp; pages refuse explicitly

**CONSIDER** · 2026-08 · dashboard app

Inside a page, a scope selector (mine, all, someone else's) that the viewer
may not use falls back to "mine" and shows the effective scope, so a
bookmarked URL keeps working after a role change. A page the viewer may not
open shows an explicit "no permission" page instead of a silent redirect.
