---
name: website-nextjs-fullstack-soft-delete-lifecycle
description: >-
  The soft-delete/restore/purge lifecycle for an entity in a full-stack
  Next.js app backed by Prisma — a nullable deletedAt column, three
  repository functions guarded by opposite deletedAt filters so an action
  can't accidentally double-apply, a dedicated /trash route per entity, and
  confirmation copy that names any cascading effects on related records.
  Use when adding delete to any entity that isn't purely disposable, or
  when deciding whether a delete needs a trash/undo step at all. Assumes a
  dashboard/admin app with a real backend database — irrelevant for a
  simple static or marketing site with nothing stateful to soft-delete.
metadata:
  type: practice
  category: architecture
---

## Rule

### `deletedAt: DateTime?` — nullable means alive, set means in the trash

```prisma
model Company {
  // ...
  deletedAt DateTime?
  @@index([deletedAt])
}
```

Every "active" read filters `deletedAt: null` explicitly — there is no
default Prisma middleware silently doing this, so every query function
that reads live rows states its own filter, and every query function that
reads trashed rows states the opposite:

```ts
// features/companies/repository.ts
export async function findManyActive(params: ListCompaniesRepoParams) {
  return prisma.company.findMany({ where: { deletedAt: null }, /* ... */ });
}

export async function findManyDeleted() {
  return prisma.company.findMany({
    where: { deletedAt: { not: null } },
    orderBy: { deletedAt: 'desc' },
    select: { id: true, name: true, deletedAt: true, _count: { select: { leads: true } } },
  });
}
```

### Three repository functions, each guarded against the wrong current state

```ts
export async function softDelete(id: string) {
  return prisma.company.update({
    where: { id, deletedAt: null }, // can't "delete" an already-deleted row
    data: { deletedAt: new Date() },
    select: { id: true },
  });
}

export async function restore(id: string) {
  return prisma.company.update({
    where: { id, deletedAt: { not: null } }, // can't "restore" a row that isn't deleted
    data: { deletedAt: null },
    select: { id: true },
  });
}

export async function purge(id: string) {
  return prisma.company.delete({
    where: { id, deletedAt: { not: null } }, // hard delete only ever fires from the trash
    select: { id: true },
  });
}
```

Putting the opposite `deletedAt` condition **in the `where` clause itself**
(not as a separate guard-then-mutate check) means Prisma throws a
not-found error if the row's already in the wrong state — a double-click
on "delete" from two open tabs can't soft-delete an already-deleted row
twice, and there's no separate read-then-write race window to reason about.

`service.ts` translates that Prisma throw into a typed domain error the
caller can render around:

```ts
export async function deleteCompany(ctx: ActionContext, id: string): Promise<void> {
  requirePermission(ctx.user, 'companies.delete');
  try {
    await repo.softDelete(id);
  } catch {
    throw new NotFoundError('Company not found.');
  }
}
```

### A dedicated `/trash` route per entity — not a filter toggle on the main list

```tsx
// app/(app)/companies/trash/page.tsx
export default async function CompaniesTrashPage() {
  const rows = await listDeletedCompanies();
  return rows.length === 0 ? (
    <EmptyTrash />
  ) : (
    <Table>
      {/* ... */}
      <TableBody>
        {rows.map((company) => (
          <TableRow key={company.id}>
            <TableCell>{company.name}</TableCell>
            <TableCell>{formatRelativeTime(company.deletedAt)}</TableCell>
            <TableCell>
              <RestoreCompanyButton companyId={company.id} companyName={company.name} />
              <PurgeCompanyDialog companyId={company.id} companyName={company.name} />
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
```

A separate route (rather than a "show deleted" toggle on `/companies`)
keeps the everyday list page's query simple (`deletedAt: null`, always),
keeps trashed rows from ever silently appearing in a normal filtered/sorted
view, and gives restore/purge actions a page where they're the *only*
actions available — no risk of a restore button ending up next to an edit
button for a row that's mid-flight to being hard-deleted.

### Confirmation copy names the actual cascading effect, every time

A delete confirmation on a row with related data doesn't say "Are you
sure?" — it says exactly what happens to what's attached:

```tsx
{
  kind: 'confirm',
  title: 'Delete company?',
  description: (
    <>
      "{company.name}" moves to the trash. Restorable for 30 days, then
      permanently deleted.
      {leadCount > 0 ? (
        <> The <strong>{leadCount} linked lead{leadCount === 1 ? '' : 's'}</strong> stay, but lose their company link.</>
      ) : null}
    </>
  ),
  confirmLabel: 'Delete',
  onConfirm: onDelete,
}
```

Writing this sentence is also how you *discover* what a delete actually
cascades into — if you can't state the effect on related rows in one
sentence, the delete's behavior probably needs to be decided, not just
implemented.

### Purge is permanent and says so twice

The trash page's "delete forever" action is a separate, more deliberately
worded confirmation than the original soft-delete — it should never share
copy or a confirm button style with the reversible action that got the row
into the trash in the first place. A nightly job (or manual cron endpoint)
hard-purging anything past a retention window (e.g. 30 days) is the
backstop for rows nobody manually purges — the UI path and the automatic
sweep should use the exact same `purge()` repository function so there's
only one code path that actually issues a hard `DELETE`.

## Why

Guarding each repository mutation with the opposite `deletedAt` condition
in its own `where` clause — instead of a generic "check state, then
mutate" helper — means the database itself enforces the state machine
(alive → trashed → gone) atomically; there's no window where two
concurrent requests both read "not yet deleted" and both proceed. A
separate `/trash` route rather than an in-list toggle exists because the
two views have almost nothing in common (different available actions,
different columns worth showing — "deleted 3 days ago" instead of
"created 3 days ago") and conflating them into one table with a filter
flag makes both cases worse to read. Cascading-effect-specific
confirmation copy exists because a generic "Are you sure you want to
delete this?" trains users to click through without reading — specific
copy is both more honest and, empirically, actually read.

## Exceptions

- Not every entity needs a trash/restore step — a genuinely disposable,
  low-stakes record (a draft note with no relations, a notification) can
  hard-delete immediately with a plain confirm dialog. Reach for the full
  soft-delete lifecycle when a record has relations other rows reference,
  or when "I didn't mean to delete that" is a realistic and costly mistake.
- The retention window (30 days here) is a policy choice, not a fixed
  rule — pick whatever fits the data's actual sensitivity and any
  compliance requirement (e.g. a legally mandated retention or deletion
  period) that applies to that specific entity.
- If an entity is deleted so rarely that a dedicated `/trash` route would
  sit empty for months, a simple "recently deleted" section inside the
  entity's own settings/detail area is a reasonable lighter-weight
  alternative to a whole extra route.

## See also

- [website-nextjs-fullstack-layered-architecture](../website-nextjs-fullstack-layered-architecture/SKILL.md) — where `softDelete`/`restore`/`purge` sit in the repository/service split.
- [website-nextjs-fullstack-list-page-pattern](../website-nextjs-fullstack-list-page-pattern/SKILL.md) — the main list page these trash actions are one click away from.
- [website-nextjs-fullstack-server-actions](../website-nextjs-fullstack-server-actions/SKILL.md) — how the delete/restore/purge buttons themselves call into `actions.ts`.
