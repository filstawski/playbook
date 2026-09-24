# nextjs

Skills distilled from a real Next.js **dashboard** — a logged-in product
app (App Router, React 19, Tailwind v4, a Radix-based component system,
TanStack Query, react-hook-form + Zod). All four skills here are prefixed
`website-nextjs-dashboard-*` on purpose: a future marketing/content-site
Next.js skill will live in this same `nextjs/` folder eventually, and the
`dashboard` qualifier in the name is what keeps the two from being confused
once everything is symlinked flat into `~/.claude/skills/`.

| Skill | Covers |
| --- | --- |
| [website-nextjs-dashboard-stack](website-nextjs-dashboard-stack/SKILL.md) | Framework + library choices, the CVA/Radix component pattern |
| [website-nextjs-dashboard-project-structure](website-nextjs-dashboard-project-structure/SKILL.md) | Top-level `src/` layering — `components/ui` vs feature components vs `lib/`/`hooks/`/`contexts/`/`providers/` |
| [website-nextjs-dashboard-route-organization](website-nextjs-dashboard-route-organization/SKILL.md) | Route groups, and the `_components`/`_hooks`/`_lib` per-route private-folder convention |
| [website-nextjs-dashboard-forms](website-nextjs-dashboard-forms/SKILL.md) | react-hook-form + Zod, the `Field` primitive set, mutation-driven submission, `MutateButton` |

## Reading order

Bootstrapping a new dashboard: `stack` → `project-structure` →
`route-organization` → `forms`, in that order. Already have one and adding
a route or form: skip straight to `route-organization` or `forms`.

## Deliberately not covered yet

- **Data fetching** (how a page loads and caches server data) and
  **realtime** (websocket-driven live updates) are real, distinctive parts
  of the source app this was distilled from, but they're wired tightly to
  that app's own generated SDK client — folding that SDK's specifics in
  here would make these skills far less portable to a different backend.
  Worth its own skill once there's a backend-agnostic version of the
  pattern to write down.
- **The page-level `Suspense` + loading-skeleton shape** every page in the
  source app follows is flagged as a candidate for its own skill, but the
  current shape has an open question about whether it's actually the right
  approach — write it down once that's settled, not before.
- **Marketing/content pages** get their own skill(s) later, in this same
  `nextjs/` folder (or `astro/`, once that framework is in play) — see the
  parent [website/README.md](../README.md).

## Why this is organized as a domain, not flat

These four skills share vocabulary and cross-reference each other
constantly (a route's private folder holds a form built from the stack's
primitives). See the root [CONCEPT.md](../../CONCEPT.md) and
[skills/api/README.md](../../api/README.md) for a worked example of the
same reasoning applied to another domain.
