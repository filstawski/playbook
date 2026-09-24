# nextjs

Skills distilled from two real Next.js apps that are structurally very
different despite both being "a logged-in product dashboard": one is a
**thin client consuming an external SDK/backend**, the other **owns its
own backend** (Prisma, Server Actions, no separate API service) in the same
Next.js app. Every skill here carries a qualifier — `dashboard` or
`fullstack` — that names which kind it's from, so the two families never
get confused once everything is symlinked flat into `~/.claude/skills/`.
A future marketing/content-site Next.js skill would get its own qualifier
the same way.

## `dashboard` — thin client over an external SDK/API

| Skill | Covers |
| --- | --- |
| [website-nextjs-dashboard-stack](website-nextjs-dashboard-stack/SKILL.md) | Framework + library choices, the CVA/Radix component pattern |
| [website-nextjs-dashboard-project-structure](website-nextjs-dashboard-project-structure/SKILL.md) | Top-level `src/` layering — `components/ui` vs feature components vs `lib/`/`hooks/`/`contexts/`/`providers/` |
| [website-nextjs-dashboard-route-organization](website-nextjs-dashboard-route-organization/SKILL.md) | Route groups, and the `_components`/`_hooks`/`_lib` per-route private-folder convention |
| [website-nextjs-dashboard-forms](website-nextjs-dashboard-forms/SKILL.md) | react-hook-form + Zod, the `Field` primitive set, mutation-driven submission, `MutateButton` |

Reading order for a new app of this kind: `stack` → `project-structure` →
`route-organization` → `forms`.

## `fullstack` — the Next.js app *is* the backend

**Scope: multi-role, multi-user dashboard/admin apps only.** Every skill
in this section (layered architecture, Server Actions, RBAC, list pages,
soft delete) was distilled from one specific full-stack CRM with several
distinct user roles, a real permission model, and an audit trail — that's
the shape these skills assume. None of it is a default for a simple
website, a static/marketing site, a single-user tool, or a project with no
real backend of its own. In particular:

- **Server Actions** is documented in detail here because it was the
  deliberately chosen (and approved) mutation layer for *this* project —
  not a universal recommendation. Plenty of other projects, including
  several of mine, don't use Server Actions at all (a separate API/SDK,
  as in the `dashboard` skills above, or a plain client-fetched API).
- **RBAC** is only worth adopting once a project has genuinely distinct
  user roles that need enforcing server-side. Don't reach for a permission
  catalog and three enforcement layers on something with one kind of user.

| Skill | Covers |
| --- | --- |
| [website-nextjs-fullstack-layered-architecture](website-nextjs-fullstack-layered-architecture/SKILL.md) | The `schemas`/`repository`/`service`/`queries`/`actions` five-file feature-module shape |
| [website-nextjs-fullstack-server-actions](website-nextjs-fullstack-server-actions/SKILL.md) | The `defineAction()` wrapper (auth+RBAC+Zod+audit+revalidate) and the client-side calling convention |
| [website-nextjs-fullstack-rbac](website-nextjs-fullstack-rbac/SKILL.md) | Permission strings, `can()`/`requirePermission()`, three lines of defense, scoped reads |
| [website-nextjs-fullstack-list-page-pattern](website-nextjs-fullstack-list-page-pattern/SKILL.md) | RSC list pages driven entirely by `searchParams` — no client state library |
| [website-nextjs-fullstack-soft-delete-lifecycle](website-nextjs-fullstack-soft-delete-lifecycle/SKILL.md) | `deletedAt` convention, trash routes, restore/purge |

Reading order for a new app of this kind: `layered-architecture` →
`rbac` → `server-actions` → `list-page-pattern` → `soft-delete-lifecycle`.

## Deliberately not covered

- **`dashboard`'s data fetching + realtime** — wired tightly to that app's
  own generated SDK client; folding the SDK's specifics in would make the
  skill far less portable. Worth writing once there's a backend-agnostic
  version of the pattern.
- **`dashboard`'s page-level `Suspense` + loading-skeleton shape** — flagged
  as a candidate skill, but held back pending a rethink of whether the
  current shape is actually the right approach.
- **`fullstack`'s CRM-specific domain logic** — the cold-call queue's
  atomic-claim SQL, DNC/consent/UWG/DSGVO compliance rules, anything
  phone/call-specific. Too business-specific to generalize, the same call
  made for excluding `dashboard`'s SDK internals.
- **`fullstack`'s visual design-guidelines system** (color tokens,
  typography, spacing, component rules, density modes) — real and
  well-executed in the source app, held back for now.
- **Marketing/content pages** — a future qualifier in this same `nextjs/`
  folder (or `astro/`, once that framework is in play) — see the parent
  [website/README.md](../README.md).

## Why this is organized as a domain, not flat

Skills within a kind (`dashboard` or `fullstack`) share vocabulary and
cross-reference each other constantly (a `fullstack` list page's
`queries.ts` call is explained in `layered-architecture`; its delete
button is explained in `server-actions`). See the root
[CONCEPT.md](../../CONCEPT.md) and [skills/api/README.md](../../api/README.md)
for a worked example of the same reasoning applied to another domain.
