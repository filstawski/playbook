# Data and migrations

Schema changes, transactions, and how records keep their history. ORM notes
assume Prisma 8 (the contract-based release), which the user picked for
current apps.

## Never edit a migration that may have run anywhere

**MUST** · 2026-10 → 2026-11 · dashboard apps (4 sources)

Once a migration may have been applied to any database, never re-plan,
rename or delete it; add a new one on top. That includes the user's dev
database from a feature branch, before merge.

- Check the database's migration marker, read-only, before deciding.
- Several branches with migrations form one linear chain: land one, then
  re-plan the next branch's migration from main's current schema before its
  PR goes up.
- Switch the user's checkout to a branch only once its migration is final.

**Why:** deleting and re-planning a migration the user had already applied
left their database unable to migrate ("Why can't I migrate the
database?").

## Expand before contract

**MUST** · 2026-10 · dashboard apps

Migrations add things before code relies on them. Removals come in a later
release, once no deployed image reads the old shape. Rolling back to the
previous image on the newer schema then just works (see
[../deployment/production-vps.md](../deployment/production-vps.md)).

## Write by hand what the planner can't express

**SHOULD** · 2026-10 · dashboard apps

Changing an existing foreign key's nullability or `onDelete`, or adding a NOT
NULL column to a populated table, needs a hand-written migration (drop
constraint, drop not-null, re-add the key; or add nullable, backfill, then
set not-null). Apply it to a scratch database and verify before pushing.
Prisma 8 specifics that cost time:

- The flow is: edit the contract, `prisma contract emit`,
  `prisma migration plan --name <x>`.
- The planner labels some safe changes "destructive" (re-adding a check
  constraint, int4 → int8). Read the SQL, not the label.
- A toolchain upgrade can change the contract hash without any schema
  change.
- Raw SQL goes only in repositories, as whole statements. `null` can't be
  interpolated (use `NULLIF` with a sentinel). Guard empty `IN ()` lists.
- The client is cached for the dev server's lifetime, so contract changes
  need a dev-server restart. In a fresh worktree, run `next build` before
  `tsc` so generated types exist.

## Side effects are written in the same transaction as the change

**MUST** · 2026-10 · dashboard app

A shared action wrapper runs permission check → schema validation →
`transaction(tx => handler)` → typed result. Audit entries, outbox emails,
timeline entries and live-update signals are all written with `tx`, so
none can be lost or half-applied.

**Why:** an earlier version of the app lost audit entries and left
half-finished operations, because follow-up writes ran outside the
transaction.

External systems (object storage, DNS, payment providers) are the
exception: do the external step first, then a short transaction with a
rollback hook that cleans up the external resource if the write fails.
Never hold a transaction open across a network call. Secondary effects that
must not block the main action (a mirrored calendar entry) are best-effort,
logged, and idempotent upserts keyed by subject and owner.

## Guard read-modify-write with a revision counter

**CONSIDER** · 2026-10 · client dashboard app

When a step reads an aggregate, changes it and writes it back whole, add a
`revision` column, and let a write through only against the revision it
read. A person's edit stops with "please reload" on conflict, since they
decided based on what they saw. Background steps that only add retry from a
fresh read. Shared config that admins edit saves as new versions and refuses
a stale save with a message.

**Why:** the revision is there "to prevent stale updates", as the user put
it: a write based on an outdated read must not overwrite newer changes.

## Model what a thing is, and ask before merging concepts

**SHOULD** · 2026-10 · dashboard app

Split records by what they are, not by how they arrived; channels differ only
at the entrance. When a plan would merge entities the user described
separately, raise it as an open question instead of deciding silently ("is
my idea wrong, have you misunderstood, or why have you put it all into one
page?"). Model many-to-many membership with its own fields (role, contact
details per membership) as soon as one real case needs it.

## History doesn't change when live data does

**SHOULD** · 2026-10 · dashboard apps

- **Records of things sent** (emails, links, mailings) store the recipient's
  name, greeting and address as they were. The link to the live entity is a
  nullable foreign key with `onDelete: SetNull`.
- **Issued documents** are kept exactly as sent, with their template
  version and a SHA-256 hash. Numbers are assigned only on issue, so
  discarded drafts leave no gaps, and every preview is watermarked
  "SAMPLE".
- **Documents with a retention duty** can't be edited or deleted:
  corrections go through a cancellation document. Their files are owned by
  the document record, so purging a parent can't cascade-delete them.

**Why:** in one app, filing issued PDFs under the parent record would have
let a purge of that record delete them, and a generic document action would
have allowed trashing them.

## Block, trash and purge are three different operations

**SHOULD** · 2026-10 · dashboard apps

- **Block** ends sessions and refuses sign-in until the account is
  unblocked.
- **Trash** is a soft delete (`deletedAt`), read-only and restorable.
  Children trashed with a parent share its timestamp, so a restore brings
  back exactly those.
- **Purge** needs its own permission and runs in one transaction. It
  anonymizes the person in the audit log and records one anonymous "purged"
  entry. Purging a record that automated sources might find again leaves a
  tombstone of its dedupe keys, so importers can't re-add it ("make sure it
  doesn't get filled in again"). Duplicate checks also see trashed rows and
  say so.

See [website-nextjs-fullstack-soft-delete-lifecycle](../../skills/website/nextjs/website-nextjs-fullstack-soft-delete-lifecycle/SKILL.md).

## Closed states change only by explicit transition

**SHOULD** · 2026-08 · dashboard app

Terminal-state guards (won/lost, closed) run only on an actual transition
into that state, not on every save of a closed record. Edit forms keep the
real status as their default. Reopening is an explicit, audited action.

**Why:** editing a closed record's name silently reset its stage.

## Human-readable numbers beside the UUID

**SHOULD** · 2026-10 · dashboard app

Keep the UUID primary key, and add configurable display numbers per record
type (prefix, digits, optional year, e.g. `K-0001`, `D-2026-0042`). Defaults
live in code; overrides live in the database and are edited on a settings
page with a live preview. Assign the number at a meaningful moment in the
record's lifecycle, and allow entering existing numbers when importing.

**Why:** the user asked for numbers "like K-0001", with settings for the
prefix and the counter.

## Business time zone, tested across midnight

**SHOULD** · 2026-10 · dashboard app

Format user-visible times on server and client in the business's time zone,
and decide "today" by that calendar, so emails and UI agree. Unit-test with
fixed clocks: a normal case, a case just past local midnight, and the exact
instant that failed, under several machine time zones.

**Why:** a test failed only when CI ran near midnight UTC; the sign-in page
used the device's zone while emails used the business zone.

## Audit that something changed, not what private content said

**SHOULD** · 2026-11 · dashboard app

Log that a note was added, changed or removed, not its text. History views
show sensitive field values only with a dedicated permission. Only content
edits move an "edited" marker: pinning a note must not change the timestamp
that drives it.

**Why:** pinning a note once marked it "edited", because the pin updated the
same timestamp.

## Demo and staging data

**SHOULD** · 2026-10 → 2026-11 · dashboard apps

- **Coverage.** Seed one record in every workflow state, derived from the
  app's own rules.
- **Volume.** Generate bulk data with a fixed-seed faker in the UI's
  locale, around hand-written scenarios.
- **Ownership.** Hand ownership round-robin to every active account. When a
  second person got staging access, all data turned out to belong to the
  admin.
- **On demand.** Provide a logged way to generate data for one chosen user
  (an admin page and a CLI) that refuses to run on production.
- **Resets.** Keep the seed and reset scripts in step with every schema
  change.

**Why:** a schema change without a matching reset update failed CI's image
job with "cannot truncate a table referenced in a foreign key constraint".
