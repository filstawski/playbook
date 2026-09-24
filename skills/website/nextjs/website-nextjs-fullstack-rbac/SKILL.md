---
name: website-nextjs-fullstack-rbac
description: >-
  Permission-string RBAC for a full-stack Next.js app — a flat catalog of
  "domain.verb[.scope]" permission strings, can()/scopeOf()/requirePermission()
  helpers, and three independent enforcement points (Server Action, service
  layer, UI) so no single missed check is the only thing standing between a
  user and something they shouldn't see. Covers scoped reads (own/team/all)
  and a dedicated full-page permission-denied state instead of a silent
  redirect or a misleading 404. Use when adding a new permission, gating a
  page or action, or deciding how "you can only see your own records"
  should be enforced. Only relevant to a multi-user app with genuinely
  different roles/permissions and a real need to enforce them server-side
  — not something to reach for by default on a simple website, a
  single-admin tool, or anything deployed without multiple distinct user
  roles in the first place.
metadata:
  type: practice
  category: architecture
---

## Rule

### Permission strings, not role-name checks

```ts
// features/rbac/permissions.ts
export const PERMISSIONS = [
  'leads.read.own',
  'leads.read.team',
  'leads.read.all',
  'leads.create',
  'leads.update',
  'leads.delete',
  'companies.read',
  'companies.create',
  'companies.update',
  'companies.delete',
  'users.read',
  'roles.create',
  'audit.read',
  // ...
] as const;

export type Permission = (typeof PERMISSIONS)[number];
```

```ts
if (can(user, 'leads.create')) { /* ... */ }   // ✓ — checks a capability
if (user.role.key === 'admin') { /* ... */ }   // ✗ — only acceptable inside the role-management screen itself
```

A role is just a name plus a flat list of permission strings — adding a new
custom role is data, never a code change:

```ts
// features/rbac/system-roles.ts
export const SYSTEM_ROLES = {
  admin: { isSystem: true, permissions: PERMISSIONS }, // every permission
  manager: {
    isSystem: true,
    permissions: ['leads.read.all', 'leads.create', 'leads.update', 'companies.read', 'audit.read' /* ... */],
  },
  sales_rep: {
    isSystem: true,
    permissions: ['leads.read.own', 'companies.read', 'contacts.read', 'contacts.create'],
  },
} as const;
```

### The check itself: three tiny, composable functions

```ts
// features/rbac/can.ts
import type { Permission } from './permissions';

export type AccessScope = 'own' | 'team' | 'all';

export interface RbacUser {
  id: string;
  role: { key: string; permissions: readonly Permission[] };
  teamId: string | null;
}

/** True when the user holds the exact permission string. */
export function can(user: RbacUser, permission: Permission): boolean {
  return user.role.permissions.includes(permission);
}

/**
 * Highest scope the user holds for a domain that uses scoped reads
 * (e.g. `leads.read.all` → 'all'). Null when no matching permission exists.
 */
export function scopeOf(user: RbacUser, domain: string): AccessScope | null {
  const perms = user.role.permissions;
  if (perms.includes(`${domain}.read.all` as Permission)) return 'all';
  if (perms.includes(`${domain}.read.team` as Permission)) return 'team';
  if (perms.includes(`${domain}.read.own` as Permission)) return 'own';
  if (perms.includes(`${domain}.read` as Permission)) return 'all'; // flat, unscoped read permission
  return null;
}
```

```ts
// features/rbac/require-permission.ts
import { ForbiddenError } from '@/lib/errors';
import { can, type RbacUser } from './can';
import type { Permission } from './permissions';

/** Throws ForbiddenError when the user lacks the permission. */
export function requirePermission(user: RbacUser, permission: Permission): void {
  if (!can(user, permission)) throw new ForbiddenError();
}
```

`can()` is a pure boolean for UI branching (show/hide a button);
`requirePermission()` is the throwing variant for anywhere a missing
permission should hard-stop the request.

### Three lines of defense — checked independently, not "checked once and trusted"

1. **Server Action / entry point** — `defineAction({ permission: 'leads.create', ... })` calls
   `requirePermission` before the handler ever runs (see
   [website-nextjs-fullstack-server-actions](../website-nextjs-fullstack-server-actions/SKILL.md)).
2. **Service layer** — the first line of every `service.ts` function calls
   `requirePermission` again:
   ```ts
   export async function deleteCompany(ctx: ActionContext, id: string): Promise<void> {
     requirePermission(ctx.user, 'companies.delete');
     // ...
   }
   ```
   This is deliberate duplication, not an oversight — the service **never
   trusts that its caller already checked**. A new caller of
   `deleteCompany` six months from now (a bulk-import job, a cron task) is
   automatically covered even if it forgets its own check.
3. **UI** — the same `can()` call, computed once server-side and passed
   down as a prop, decides whether to render an action at all:
   ```tsx
   // app/(app)/companies/page.tsx (Server Component)
   const user = await requireUser();
   const canDelete = can(user, 'companies.delete');
   return <CompaniesTable result={result} canDelete={canDelete} />;
   ```
   The UI check is a UX convenience (don't show a button that will 403),
   never the actual security boundary — layers 1 and 2 are what actually
   enforce anything.

### Scoped reads: `own` / `team` / `all`, enforced in the repository query itself

A permission domain that needs row-level scoping (a rep sees only their
own leads; a manager sees their team's) exposes three read permissions
instead of one, and the service resolves the caller's highest scope into a
`where` clause **before the query runs** — never by fetching everything
and filtering in application code:

```ts
// server/repository-helpers.ts
export function withScope<T extends { where?: object }>(args: T, user: RbacUser, domain: string): T {
  const scope = scopeOf(user, domain);
  if (scope === 'all') return args;
  if (scope === 'own') {
    return { ...args, where: { ...args.where, OR: [{ claimedById: user.id }, { assignedToId: user.id }] } };
  }
  // 'team' — resolve to the caller's team roster
  return { ...args, where: { ...args.where, assignedToId: { in: user.teamUserIds } } };
}
```

### Denial is a dedicated page, not a silent redirect or a misleading 404

```tsx
// features/rbac/permission-denied.tsx
export function PermissionDenied({ permission, title, description }: PermissionDeniedProps) {
  const meta = permission ? getPermissionMeta(permission) : null;
  return (
    <div className="mx-auto flex max-w-lg flex-col items-center gap-6 py-16 text-center">
      <h1>{title ?? 'No permission'}</h1>
      <p>{description ?? 'Ask an admin to add this permission to your role.'}</p>
      {meta ? (
        <div className="bg-card rounded-xl p-4 text-left">
          <p className="text-xs uppercase">Missing permission</p>
          <p className="text-sm font-medium">{meta.label}</p>
          {permission ? <p className="font-mono text-[11px]">{permission}</p> : null}
        </div>
      ) : null}
    </div>
  );
}
```

This replaced an earlier version that either `redirect('/')`ed (the user
has no idea why they bounced) or `notFound()`ed (actively misleading —
implies the resource doesn't exist rather than "you can't see it"). Naming
the exact missing permission string in the denial UI also means a user can
screenshot it directly to whoever manages roles, instead of describing
"the leads page" and hoping the admin guesses the right permission to add.

## Why

Permission strings instead of role-name branches exist so that "what can
role X do" is a data table, not something you have to `grep` across
scattered `if (role === ...)` checks to reconstruct — and so a brand-new
custom role someone creates in the admin UI works everywhere immediately,
with zero code changes. The three-lines-of-defense duplication exists
because a single enforcement point is one missed refactor away from a
silent hole — the service-layer check specifically defends against **future
callers that don't yet exist**, which is exactly the kind of check that
looks redundant right up until it's the only thing that caught something.
Resolving scope into the `where` clause instead of filtering post-fetch
matters for the same reason pagination has to be server-side: it's the
difference between a query that's `O(matching rows)` and one that's
`O(all rows)`.

## Exceptions

- **Don't add RBAC to a project that doesn't have real roles yet.** A
  simple website, a single-operator internal tool, or an early-stage app
  with exactly one kind of user gets nothing from a permission-string
  catalog and three enforcement layers except ceremony — a single
  `isAdmin` boolean (or nothing at all) is correct until a second,
  genuinely different role actually shows up. Introducing this machinery
  "because it's good practice" on a project that doesn't need it is the
  exact overengineering this playbook otherwise argues against.
- The UI-layer `can()` check is genuinely optional to wire for a very
  low-stakes action — it's a UX nicety, and skipping it just means a user
  without permission sees a button that 403s on click instead of not
  seeing it. Never skip layers 1 and 2 for the same reason, though — those
  are the actual boundary.
- `scopeOf`'s fallback (`{domain}.read` → `'all'`) is specifically for
  domains that never need per-row scoping (e.g. company-wide reference
  data) — don't reach for the `.own`/`.team`/`.all` permission triplet for
  a domain where "all" is the only scope that will ever make sense.
- Duplicating `requirePermission` in the service layer is worth it because
  services are called from more than one action/entry point over an app's
  lifetime. A private helper function called from exactly one place, with
  no plan to add a second caller, doesn't need its own redundant check.

## See also

- [website-nextjs-fullstack-layered-architecture](../website-nextjs-fullstack-layered-architecture/SKILL.md) — where the service-layer `requirePermission` call sits relative to `repository.ts`.
- [website-nextjs-fullstack-server-actions](../website-nextjs-fullstack-server-actions/SKILL.md) — how `defineAction`'s `permission` option becomes the first line of defense.
