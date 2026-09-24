---
name: website-nextjs-fullstack-server-actions
description: >-
  How mutations are wired in a full-stack Next.js app with no separate API
  layer — a defineAction() factory that bundles auth, RBAC permission
  checks, Zod validation, audit logging, and revalidatePath into every
  Server Action, returning a typed ActionResult<T> instead of throwing; the
  "use server" file export constraint this forces; and the client-side
  calling convention (useTransition + router.refresh() + toast + RHF field
  errors) with no client-state/mutation library involved. Use when adding a
  new mutation, wiring a form's submit handler, or deciding whether
  something needs TanStack Query at all. This documents Server Actions as
  the deliberately chosen mutation layer for one specific full-stack
  dashboard app — not a universal recommendation; plenty of other projects
  (a separate API/SDK, a mobile client, a static/marketing site) correctly
  don't use Server Actions at all.
metadata:
  type: practice
  category: architecture
---

## Rule

### `defineAction()` — one factory wraps auth, permission, validation, audit, and revalidation

```ts
// src/server/action-wrapper.ts
import { revalidatePath } from 'next/cache';
import type { ZodType } from 'zod';
import { requirePermission } from '@/features/rbac/require-permission';
import type { Permission } from '@/features/rbac/permissions';
import { emitAudit } from '@/lib/audit';
import { ForbiddenError, isAppError, ValidationError } from '@/lib/errors';
import { requireUser, type ActionContext } from './session';

export type ActionSuccess<T> = { ok: true; data: T };
export type ActionFailure = {
  ok: false;
  error: string;
  code?: string;
  fieldErrors?: Record<string, string>;
};
export type ActionResult<T> = ActionSuccess<T> | ActionFailure;

interface AuditMeta<TInput = unknown, TOutput = unknown> {
  action: string;
  entityType?: string;
  entityIdFrom?: (input: TInput, output: TOutput) => string | undefined;
}

interface DefineActionOptions<TInput, TOutput> {
  permission: Permission;
  schema: ZodType<TInput>;
  handler: (input: TInput, ctx: ActionContext) => Promise<TOutput>;
  audit?: AuditMeta<TInput, TOutput>;
  revalidatePaths?: string[] | ((input: TInput, output: TOutput) => string[]);
}

function zodFieldErrors(error: { issues: Array<{ path: PropertyKey[]; message: string }> }) {
  const fieldErrors: Record<string, string> = {};
  for (const issue of error.issues) {
    const key = issue.path[0]?.toString();
    if (key && !fieldErrors[key]) fieldErrors[key] = issue.message;
  }
  return fieldErrors;
}

function mapErrorToResult(error: unknown): ActionFailure {
  if (error instanceof ValidationError) {
    return { ok: false, error: error.message, code: error.code, fieldErrors: error.fieldErrors };
  }
  if (isAppError(error)) return { ok: false, error: error.message, code: error.code };
  console.error('[defineAction] Unhandled error:', error);
  return { ok: false, error: 'An unexpected error occurred.', code: 'INTERNAL' };
}

export function defineAction<TInput, TOutput>(opts: DefineActionOptions<TInput, TOutput>) {
  return async (input: unknown): Promise<ActionResult<TOutput>> => {
    try {
      const user = await requireUser();
      requirePermission(user, opts.permission);

      const parsed = opts.schema.safeParse(input);
      if (!parsed.success) {
        return { ok: false, error: 'Validation failed.', code: 'VALIDATION', fieldErrors: zodFieldErrors(parsed.error) };
      }

      const result = await opts.handler(parsed.data, { user });

      if (opts.audit) {
        try {
          await emitAudit({
            action: opts.audit.action,
            entityType: opts.audit.entityType,
            entityId: opts.audit.entityIdFrom?.(parsed.data, result),
            actorId: user.id,
          });
        } catch (error) {
          // An audit-log failure must not roll back a successful mutation —
          // the row's already there. Log loudly so monitoring catches it.
          console.error('[defineAction] Audit emission failed:', error);
        }
      }

      if (opts.revalidatePaths) {
        const paths = typeof opts.revalidatePaths === 'function' ? opts.revalidatePaths(parsed.data, result) : opts.revalidatePaths;
        for (const path of paths) revalidatePath(path);
      }

      return { ok: true, data: result };
    } catch (error) {
      if (error instanceof ForbiddenError) return { ok: false, error: error.message, code: error.code };
      return mapErrorToResult(error);
    }
  };
}
```

Every mutation gets the same guarantees for free: nobody can call the
handler unauthenticated, without the right permission, with unvalidated
input, or without an audit trail — and every failure mode (403, validation,
domain error, unexpected throw) maps to the same `ActionResult<T>` shape
instead of an uncaught exception reaching the client differently each time.

### The `"use server"` export constraint, and the internal-runner pattern it forces

A file marked `"use server"` may **only export async function
declarations** — not `const x = defineAction(...)` directly. Define the
wrapped action as an internal `const`, then export a thin named
`async function` per action that just calls it:

```ts
// features/companies/actions.ts
'use server';

import { defineAction } from '@/server/action-wrapper';
import { CreateCompanyInputSchema, type CreateCompanyInput } from './schemas';
import * as companyService from './service';

// Internal runners — defineAction() lives in a non-"use server" module,
// and its return value (a plain const arrow function) can't be exported
// directly from a "use server" file.
const runCreateCompany = defineAction({
  permission: 'companies.create',
  schema: CreateCompanyInputSchema,
  handler: (input, ctx) => companyService.createCompany(ctx, input),
  audit: {
    action: 'company.created',
    entityType: 'company',
    entityIdFrom: (_input, output) => output.companyId,
  },
  revalidatePaths: ['/companies'],
});

const runUpdateCompany = defineAction({
  permission: 'companies.update',
  schema: UpdateCompanyInputSchema,
  handler: ({ id, data }, ctx) => companyService.updateCompany(ctx, id, data),
  audit: { action: 'company.updated', entityType: 'company', entityIdFrom: ({ id }) => id },
  revalidatePaths: ({ id }) => ['/companies', `/companies/${id}`],
});

// "use server" files may only export async function declarations.
export async function createCompany(input: CreateCompanyInput) {
  return runCreateCompany(input);
}

export async function updateCompany(id: string, data: CreateCompanyInput) {
  return runUpdateCompany({ id, data });
}

export type { ActionResult } from '@/server/action-wrapper';
```

`revalidatePaths` takes either a fixed list or a function of
`(input, output)` — a delete only needs to revalidate the list page, but an
update needs both the list and that specific record's detail page, and only
the handler's result knows the id.

### Calling an action from a client component: `useTransition`, not a mutation library

No TanStack Query, no bespoke mutation hook. A form (or a row action)
calls the Server Action directly inside `useTransition`, branches on
`result.ok`, and refreshes:

```tsx
'use client';
import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { deleteCompany } from './actions';

function CompanyRow({ company }: { company: { id: string; name: string } }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  const onDelete = () => {
    startTransition(async () => {
      const result = await deleteCompany(company.id);
      if (result.ok) {
        toast.success(`"${company.name}" deleted`);
        router.refresh(); // re-runs the Server Component tree — no client cache to invalidate
      } else {
        toast.error(result.error ?? 'Delete failed.');
      }
    });
  };

  return <button onClick={onDelete} disabled={isPending}>Delete</button>;
}
```

For a form, the same `result.ok` branch feeds react-hook-form directly —
`fieldErrors` become per-field `form.setError(...)` calls, a bare `error`
string becomes one root-level `<Alert>`:

```tsx
const onValidSubmit = (values: CreateCompanyInput) => {
  setFormError(null);
  startTransition(async () => {
    const result = await createCompany(values);
    if (result.ok) {
      toast.success(`"${result.data.companyName}" created`);
      form.reset(DEFAULT_VALUES);
      setOpen(false);
      router.refresh();
      return;
    }
    if (result.fieldErrors) {
      for (const [key, message] of Object.entries(result.fieldErrors)) {
        form.setError(key as keyof CreateCompanyFormInput, { message });
      }
    }
    if (result.error) setFormError(result.error);
  });
};
```

react-hook-form is still driven by the same Zod schema client-side (for
instant hint UX via `zodResolver`), but the **server's re-parse of the same
schema inside `defineAction` is the authoritative one** — the client
validation can lie (devtools, a stale bundle), the server's can't.

## Why

Bundling auth/permission/validation/audit/revalidation into one factory
means a new mutation is a `defineAction({...})` call, not four repeated
lines of boilerplate a future edit can forget one of — in particular,
forgetting the permission check is the single most expensive mistake this
pattern makes structurally hard to make (see
[website-nextjs-fullstack-rbac](../website-nextjs-fullstack-rbac/SKILL.md)).
Returning a typed `ActionResult<T>` instead of throwing across the
Server-Action boundary matters because thrown errors from a Server Action
arrive at the client as an opaque, unstructured rejection — a returned
value lets the wrapper hand back exactly the shape a form or toast needs
(`fieldErrors` vs a root `error` string) every time, uniformly.

Calling the action directly inside `useTransition` and refreshing rather
than reaching for a mutation library is the accurate reflection of this
app's real stack: it never adopted TanStack Query, Zustand, or any client
cache for this — `router.refresh()` re-fetches the Server Component tree,
which is already exactly as fresh as a query cache invalidation would make
it, for a fraction of the client-side machinery. Don't add a mutation
library "to be safe" until a concrete need (optimistic UI update before the
round trip, cross-tab cache sharing) actually appears.

## Exceptions

- **Server Actions is a choice, not a given.** This pattern was
  deliberately adopted (and confirmed) for a full-stack dashboard app that
  already owns its backend, has RBAC, and needs an audit trail on every
  write. Most other projects — one with a separately deployed API/SDK
  (see the `dashboard` skills in this same domain), a mobile client behind
  a public API, or a simple site with no backend of its own — should not
  default to Server Actions just because this skill documents them in
  detail. Pick the mutation layer that fits the project actually in front
  of you.
- The audit-log call is intentionally **best-effort** — a failure there
  logs loudly but does not roll back an otherwise-successful mutation
  (the row already exists). If audit logging becomes a hard compliance
  requirement, wrap the handler and the audit write in one
  `prisma.$transaction` instead of two sequential steps — this is flagged
  as a known TODO in the source, not a settled decision.
- `router.refresh()` is the right default, but it re-runs the full Server
  Component subtree for the current route — for a mutation on a page with
  a genuinely expensive data fetch, a targeted `revalidateTag` plus a more
  surgical client update may be worth the extra complexity. Don't reach for
  it preemptively.
- If a mutation genuinely needs an optimistic UI update before the round
  trip completes (e.g. drag-and-drop reordering), `useTransition` alone
  isn't enough — that's the one legitimate trigger to introduce a client
  mutation library for that specific interaction, not a reason to convert
  every mutation in the app.

## See also

- [website-nextjs-fullstack-layered-architecture](../website-nextjs-fullstack-layered-architecture/SKILL.md) — what `service.ts` function `actions.ts` is wrapping here.
- [website-nextjs-fullstack-rbac](../website-nextjs-fullstack-rbac/SKILL.md) — the permission catalog `defineAction`'s `permission` option checks against.
