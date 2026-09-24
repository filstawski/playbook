---
name: website-nextjs-fullstack-layered-architecture
description: >-
  The five-file feature-module shape for a full-stack Next.js app that owns
  its own backend (Prisma, no separate API service) — schemas.ts,
  repository.ts, service.ts, queries.ts, actions.ts, plus co-located
  components. Covers the PascalCase Zod schema naming convention and why
  reads (queries.ts) and writes (actions.ts) get their own files instead of
  one shared entry point. Use when adding a new domain/entity to a
  full-stack Next.js app, or deciding which file a piece of server-side
  logic belongs in. Scoped to multi-role, multi-user dashboard/admin-style
  apps with real backend complexity (a real permission model, an audit
  trail, several entities with their own CRUD) — not a default for a
  simple marketing site, a single-user tool, or anything without that
  complexity to justify five files per entity.
metadata:
  type: practice
  category: architecture
---

## Rule

### One folder per domain, five files with fixed jobs

```
src/features/<domain>/
  schemas.ts       # Zod input schemas + inferred types (PascalCase)
  repository.ts    # the ONLY file that imports the Prisma client
  service.ts        # business logic — permission checks, orchestration
  queries.ts        # read-side entry points, called from Server Components
  actions.ts        # write-side entry points — Server Actions
  <name>-table.tsx, <name>-form-fields.tsx, create-<name>-sheet.tsx, ...
```

Every file has exactly one direction of dependency — `repository` never
imports `service`, `service` never imports `queries`/`actions`, and nothing
outside the feature folder imports `repository` or (usually) `service`
directly:

```
components / app pages
      │
      ▼
queries.ts ──┐        actions.ts (Server Actions, wrapped by defineAction —
      │      │              see website-nextjs-fullstack-server-actions)
      ▼      ▼
       service.ts
           │
           ▼
      repository.ts
           │
           ▼
       lib/db.ts (Prisma)
```

### `schemas.ts` — PascalCase Zod schemas, the single source of truth for a shape

```ts
// features/companies/schemas.ts
import { z } from 'zod';

const optionalString = (max = 200) => z.string().max(max).optional().or(z.literal(''));

export const CreateCompanyInputSchema = z.object({
  name: z.string().min(1, 'Name ist erforderlich').max(200),
  industry: optionalString(100),
  website: optionalString(200),
  phone: optionalString(50),
  city: optionalString(120),
  countryCode: optionalString(8),
  notes: optionalString(2000),
});

// z.input vs z.output diverge whenever a field has a default/transform —
// FormInput is what react-hook-form actually holds (pre-parse); the plain
// name is the parsed, service-layer shape.
export type CreateCompanyFormInput = z.input<typeof CreateCompanyInputSchema>;
export type CreateCompanyInput = z.output<typeof CreateCompanyInputSchema>;

export const UpdateCompanyInputSchema = z.object({
  id: z.string().cuid(),
  data: CreateCompanyInputSchema,
});
export type UpdateCompanyInput = z.output<typeof UpdateCompanyInputSchema>;

export const CompanyIdSchema = z.string().cuid();
export type CompanyId = z.output<typeof CompanyIdSchema>;
```

Naming rules, applied consistently across every feature:

| Pattern | Example | Inferred type |
| --- | --- | --- |
| `{Action}{Entity}InputSchema` | `CreateCompanyInputSchema` | `CreateCompanyInput` |
| `{Action}{Entity}InputSchema` | `UpdateCompanyInputSchema` | `UpdateCompanyInput` |
| `{Entity}{Qualifier}Schema` | `CompanyIdSchema` | `CompanyId` |
| Form-side type when `z.input` ≠ `z.output` | — | `{X}FormInput` |

Prefer a **loose, forgiving validator over a strict one for free-text-ish
real-world fields** (phone numbers, websites) — accept any string and
normalize/display-format later, rather than rejecting "www.example.com" or
"+49 30 123 456" at the door. Save strict validation (`.cuid()`, `.email()`,
enum membership) for fields with one unambiguous correct shape.

### `repository.ts` — the only file that touches Prisma

```ts
// features/companies/repository.ts
import type { Prisma } from '@prisma/client';
import { prisma } from '@/lib/db';
import type { CreateCompanyInput } from './schemas';

const companyListSelect = {
  id: true,
  name: true,
  industry: true,
  createdAt: true,
  _count: { select: { leads: { where: { deletedAt: null } } } },
} satisfies Prisma.CompanySelect;

export type CompanyListRow = Prisma.CompanyGetPayload<{ select: typeof companyListSelect }>;

export async function findManyActive(params: { skip: number; take: number; orderBy: Prisma.CompanyOrderByWithRelationInput }) {
  return prisma.company.findMany({
    where: { deletedAt: null },
    orderBy: params.orderBy,
    skip: params.skip,
    take: params.take,
    select: companyListSelect,
  });
}

export async function create(data: CreateCompanyInput, ownerId: string) {
  return prisma.company.create({
    data: { ...data, owner: { connect: { id: ownerId } } },
    select: { id: true, name: true },
  });
}

export type CompanyDetail = NonNullable<Awaited<ReturnType<typeof findManyActive>>>[number];
```

Every query function is named for what it returns, not for the HTTP verb or
UI action that triggers it (`findManyActive`, `findByIdActive`,
`findManyDeleted` — not `list`/`get`/`getDeleted`). A repository function
returns **plain data shapes** (via Prisma `select`), never a raw Prisma
model instance a caller could accidentally over-fetch relations from later.

### `service.ts` — business logic, permission checks, and nothing else

Every exported function takes a request context first, checks permission
first, then does the work:

```ts
// features/companies/service.ts
import { requirePermission } from '@/features/rbac/require-permission';
import { NotFoundError } from '@/lib/errors';
import type { ActionContext } from '@/server/session';
import * as repo from './repository';
import type { CreateCompanyInput } from './schemas';

export async function getCompany(ctx: ActionContext, id: string) {
  requirePermission(ctx.user, 'companies.read');
  const company = await repo.findByIdActive(id);
  if (!company) throw new NotFoundError('Unternehmen nicht gefunden.');
  return company;
}

export async function createCompany(ctx: ActionContext, input: CreateCompanyInput) {
  requirePermission(ctx.user, 'companies.create');
  const company = await repo.create(input, ctx.user.id);
  return { companyId: company.id, companyName: company.name };
}

export async function deleteCompany(ctx: ActionContext, id: string): Promise<void> {
  requirePermission(ctx.user, 'companies.delete');
  try {
    await repo.softDelete(id);
  } catch {
    throw new NotFoundError('Unternehmen nicht gefunden.');
  }
}
```

The `requirePermission(...)` call as the **first line of every service
function** is not optional ceremony — it's the second of RBAC's three lines
of defense (see
[website-nextjs-fullstack-rbac](../website-nextjs-fullstack-rbac/SKILL.md)):
the service never trusts that its caller (an action or a query) already
checked. A repository failure (unique constraint, row not found under the
`deletedAt: null` guard) gets translated into a typed domain error
(`NotFoundError`) here — `repository.ts` throws whatever Prisma throws,
`service.ts` is where that becomes a meaningful error the caller can branch
on.

### `queries.ts` — the read-side entry point, thin and RSC-friendly

```ts
// features/companies/queries.ts
import 'server-only';
import { NotFoundError } from '@/lib/errors';
import { requireUser } from '@/server/session';
import * as service from './service';

async function ctx() {
  return { user: await requireUser() };
}

export async function listCompanies(params: ListCompaniesParams) {
  return service.listCompanies(await ctx(), params);
}

export async function getCompany(id: string) {
  try {
    return await service.getCompany(await ctx(), id);
  } catch (error) {
    if (error instanceof NotFoundError) return null;
    throw error;
  }
}
```

`queries.ts` exists as its own file — distinct from `actions.ts` — because
reads and writes have genuinely different callers and constraints: a query
is called directly from a Server Component during render (no Server Action
wrapper needed, no audit log, no revalidation), while a write needs the
whole `defineAction` machinery (auth, permission, Zod re-parse, audit,
`revalidatePath`) covered in
[website-nextjs-fullstack-server-actions](../website-nextjs-fullstack-server-actions/SKILL.md).
Note `queries.ts` still converts a domain `NotFoundError` into `null` at
this boundary — a Server Component wants "not found" as a value it renders
around, not an exception it has to catch.

The `import 'server-only'` at the top of `queries.ts` (and, transitively,
`service.ts`/`repository.ts`) is a real safety net, not decoration — it
makes it a build error for a Client Component to accidentally import this
file, instead of a runtime surprise.

### Re-exporting client-safe constants through `service.ts`

A `list-constants.ts` file (sort field enums, page-size options) sometimes
needs to be imported from a **Client Component** (a table header, a
page-size selector) that must never pull in `repository.ts`'s Prisma
import. Keep those constants in their own tiny file and re-export them
through `service.ts` so the familiar import path still works:

```ts
// features/companies/service.ts
export { PER_PAGE_OPTIONS, SORTABLE_FIELDS, type PerPage, type SortField } from './list-constants';
```

## Why

Splitting reads and writes into `queries.ts`/`actions.ts` on top of a
shared `service.ts` isn't in most people's mental model of "three-layer
architecture" (actions → service → repository) until a real app forces the
distinction: writes need a completely different wrapper (permission +
Zod + audit + revalidate, all inside a Server Action) than reads (called
directly from RSC render, no wrapper needed). Cramming both into one
`actions.ts` either forces read paths through action-wrapper ceremony they
don't need, or forces the wrapper to become conditional. Splitting them is
one file each, no conditionals. The **one-file-one-Prisma-import** rule
(`repository.ts` only) exists so that "did this leak a raw Prisma model
type past the service boundary" is answerable by grep, not by reading every
call site.

## Exceptions

- **This whole pattern assumes a full-stack, multi-role dashboard/admin
  app.** A simple website, a marketing site, a single-user tool, or
  anything that doesn't need RBAC or an audit trail has no business
  reaching for a five-file layering per entity — one file, or even inline
  logic in the route, is correct there. Don't apply this skill just
  because a project happens to be Next.js.
- A very small, read-mostly domain (a lookup table, a settings singleton)
  doesn't need all five files — a single `service.ts` with a couple of
  functions is fine until the domain grows real mutations and its own
  permission model.
- Not every entity needs its own `queries.ts` split from day one if it has
  exactly one read function and no Server Component calls it directly yet
  — but split it out the moment a second read path appears, rather than
  letting `service.ts` accumulate both read and write exports.
- The "loose validator for real-world text fields" rule doesn't apply to
  anything that drives a hard business invariant (an enum status, a
  foreign key id) — those should fail fast and specifically.

## See also

- [website-nextjs-fullstack-server-actions](../website-nextjs-fullstack-server-actions/SKILL.md) — what `actions.ts` actually wraps `service.ts` calls in, and how a client component calls one.
- [website-nextjs-fullstack-rbac](../website-nextjs-fullstack-rbac/SKILL.md) — the `requirePermission` calls that open every service function.
- [website-nextjs-fullstack-list-page-pattern](../website-nextjs-fullstack-list-page-pattern/SKILL.md) — how `queries.ts`'s list functions feed a Server Component list page.
