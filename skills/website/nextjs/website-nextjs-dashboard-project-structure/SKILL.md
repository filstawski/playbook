---
name: website-nextjs-dashboard-project-structure
description: >-
  What lives where under src/ in a Next.js dashboard app — the boundary
  between components/ui (generic design-system primitives), components/
  (cross-cutting feature components), route-private components (covered in
  the companion route-organization skill), lib/ (grab-bag business logic and
  utilities, one concern per file), hooks/ (reusable custom hooks),
  contexts/ (home-grown React context+hook pairs for ambient state), and
  providers/ (thin wrappers around third-party providers). Use when adding
  a new file and unsure which top-level folder it belongs in, or when a
  folder is growing unfocused and needs splitting.
metadata:
  type: practice
  category: architecture
---

## Rule

### The top-level shape

```
src/
  app/            # routes — see website-nextjs-dashboard-route-organization
  components/
    ui/           # generic design-system primitives (button, card, field, table, ...)
    <feature>/    # multi-file, cross-route feature component groups (sidebar/, achievements/)
    *.tsx         # single-file, cross-route components (error-boundary.tsx, offline-banner.tsx, ...)
  contexts/       # home-grown React context + hook pairs (app-wide ambient state)
  providers/      # thin wrappers around third-party providers (query client, etc.)
  hooks/          # reusable custom hooks, one concern per file
  lib/            # business logic + utilities that aren't components or hooks
  types/          # global ambient types, .d.ts augmentations
```

The rule for every one of these folders is the same: **one file, one
concern, named after what it does** — not one sprawling `helpers.ts` or
`utils/index.ts` that silently grows into a junk drawer. `lib/` in
particular looks like a grab-bag from the outside, but every file inside it
still has exactly one job (`constants.ts`, `storage.ts`, `motion.ts`,
`utils.ts` — generic string/byte/date helpers only, `achievements.ts` —
one domain's scoring logic). When a file starts covering two unrelated
concerns, split it before it grows further, don't keep appending.

### `components/ui/` — the component kit's primitives, and nothing else

**Revised 2026-11-03.** `components/ui/` holds only components that come
from the installed kit (shadcn, on Base UI in newer projects) and direct
extensions of them, however heavily reworked. A generic primitive you build
by hand (a bar, a filter menu, an animated-height wrapper) goes flat in
`components/` instead, even though it is just as domain-unaware. Import the
headless library only inside `components/ui/`. The user corrected this
placement repeatedly ("don't use the components/ui folder, this one is
intended for just shadcn things and maybe extensions, use /components").

Everything here must also work in a codebase that knows nothing about this
specific product. A component belongs here if you could paste it into a
different app's `components/ui/` unchanged: `button.tsx`, `card.tsx`,
`dialog.tsx`, `field.tsx`, `table.tsx`, `skeleton.tsx`. If a component
imports a domain type (`User`, `Image`, an SDK client) or reads app-specific
context, it does not belong in `ui/` — it belongs in one of the two tiers
below.

### `components/<feature>/` — multi-file feature component groups

A feature gets its own subfolder once it has **more than one file** and is
used from **more than one route** — e.g. `components/sidebar/` (multiple
files: `index.tsx`, `nav-links.tsx`, `user-menu.tsx`, `logo.tsx`,
`constants.tsx`) or `components/achievements/` (`medallion.tsx`,
`tier-ladder.tsx`, `tier-styles.ts`). This is the folder for "this is a
real cross-cutting piece of product UI, not a one-off," distinct from both
the generic primitives above and the route-private components below.

### `components/*.tsx` (flat, at the root) — single-file cross-cutting components

A component that's used by more than one route but doesn't need its own
folder (only one file) sits directly at `components/` root:
`error-boundary.tsx`, `error-card.tsx`, `offline-banner.tsx`,
`storage-banner.tsx`, `ws-disconnect-banner.tsx`, `form-submit-footer.tsx`,
`user-card.tsx`, `window-chrome.tsx`. This tier is domain-aware (unlike
`ui/`) — `user-card.tsx` knows what a `User` is — but shared, unlike a
route-private component.

A component used by exactly **one** route doesn't belong in `components/`
at all — it belongs in that route's own private `_components/` folder. See
[website-nextjs-dashboard-route-organization](../website-nextjs-dashboard-route-organization/SKILL.md).

So there are really four tiers, in increasing order of domain-specificity
and decreasing order of reuse:

| Tier | Location | Domain-aware? | Used from |
| --- | --- | --- | --- |
| Kit primitive (shadcn and its extensions) | `components/ui/*.tsx` | No | Anywhere |
| Hand-built generic primitive | `components/*.tsx` | No | Anywhere |
| Cross-cutting feature group | `components/<feature>/*.tsx` | Yes | Multiple routes |
| Cross-cutting single file | `components/*.tsx` | Yes | Multiple routes |
| Route-private | `app/<route>/_components/*.tsx` | Yes | One route only |

### `contexts/` vs `providers/` — home-grown state vs. wrapped libraries

This split is easy to blur but worth holding onto: **`providers/` wraps a
third-party provider** with app-specific defaults and nothing else;
**`contexts/` is state you wrote yourself.**

```tsx
// providers/query.tsx — wraps TanStack Query's own provider with this
// app's defaults. No app-specific state of its own.
"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ReactNode, useState } from "react";

export function QueryProvider({ children }: { children: ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            retry: false,
            gcTime: 0,
            refetchOnMount: false,
            refetchOnWindowFocus: false,
            refetchOnReconnect: false,
          },
        },
      }),
  );
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
```

```tsx
// contexts/ui.tsx — home-grown ambient UI state with no third-party
// library underneath it at all.
"use client";
import { createContext, useContext, useMemo, useState, type ReactNode } from "react";

/**
 * App-wide ambient UI state — anything that lives above feature trees and
 * needs to be readable/writable from anywhere inside the authenticated app.
 * Add new fields here as scoped properties so consumers destructure exactly
 * what they need. Keep this slim — feature-local state belongs in its own
 * context or hook, not here.
 */
type UIContextValue = {
  sidebarReceded: boolean;
  setSidebarReceded: (value: boolean) => void;
};

const UIContext = createContext<UIContextValue | null>(null);

// Inert fallback so the hook is safe to call outside the provider —
// consumers higher up (or tests) silently no-op instead of crashing.
const NOOP: UIContextValue = { sidebarReceded: false, setSidebarReceded: () => {} };

export function UIProvider({ children }: { children: ReactNode }) {
  const [sidebarReceded, setSidebarReceded] = useState(false);
  const value = useMemo(() => ({ sidebarReceded, setSidebarReceded }), [sidebarReceded]);
  return <UIContext.Provider value={value}>{children}</UIContext.Provider>;
}

export function useUI(): UIContextValue {
  return useContext(UIContext) ?? NOOP;
}
```

A context can also exist purely as a **structural guard marker** rather
than carrying real state — e.g. a context whose only job is to make "am I
currently rendering inside this route group's layout?" something a hook can
assert on, so a data hook throws a clear error instead of silently
misbehaving if it's ever called outside where it's guaranteed safe:

```tsx
// contexts/app.tsx
"use client";
import { createContext, useContext, type ReactNode } from "react";

const AppContext = createContext(true);

export function AppProvider({ children }: { children: ReactNode }) {
  return <AppContext.Provider value={true}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (ctx == null) {
    throw new Error("useApp must be used within an AppProvider (authenticated route group)");
  }
}
```

### `hooks/` — reusable custom hooks, one file per hook (or tight hook family)

Each file is named after what the hook does, not after a vague category:
`debounce.ts`, `is-online.ts`, `once.ts`, `use-media-query.ts`,
`websocket-subscription.ts`, `element-anchor.ts`. A hook goes here when
it's genuinely reusable across features (debounce, "is this mounted",
"subscribe to a websocket channel"). A hook that only makes sense for one
route's specific screen belongs in that route's private `_hooks/` folder
instead — see the route-organization skill for that boundary, including
how it scales from two files to a dozen on a data-dense route.

### `lib/` — business logic and generic utilities

The catch-all for anything that's neither a component nor a hook: Zod
schemas (`schemas.ts`), app constants (`constants.ts`), generic
string/byte/date helpers (`utils.ts`), animation timing constants
(`motion.ts`), and small domain-logic modules that don't warrant their own
top-level folder yet (`achievements.ts`, `achievement-progress.ts`,
`storage.ts`). Subfolders appear once a concern needs more than one file —
`lib/errors/` for custom `Error` subclasses (one class per file,
`share-deleted.ts`, `share-went-private-error.ts`), `lib/helpers/` for
small pure functions that support one specific `lib/` module rather than
standing alone.

```ts
// lib/utils.ts — representative of the "one small pure function per
// export, no shared state, no side effects" shape everything in lib/'s
// root should have.
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatBytes(bytes: number): string {
  if (bytes === 0) return "0 B";
  const sizes = ["B", "KB", "MB", "GB", "TB", "PB"];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;
}

export function getChangedFields<T extends Record<string, unknown>>(a: T, b: T): Partial<T> {
  const result: Partial<T> = {};
  for (const key in a) if (a[key] !== b[key]) result[key] = a[key];
  return result;
}
```

Once `lib/` has grown past maybe fifteen files with no visible substructure,
that's the signal to introduce domain subfolders (`lib/achievements/`,
`lib/storage/`) rather than letting it flatten into an unscannable list —
the same "split once it's unwieldy, not before" rule that governs this
playbook's own skill folders.

### `types/` — genuinely global types only

Reserve `types/` for ambient declarations (`.d.ts` files augmenting a
third-party module, global `Window` extensions) and types with no better
home. A type that belongs to one feature's data shape should live next to
that feature (in its schema file, its manager, or its own route's `_lib/`)
— `types/` is not a dumping ground for "types I didn't want to think about
where to put."

## Why

The four-tier component split exists because without it, every component
ends up either in one giant flat `components/` folder (no signal about
reuse or domain-awareness at a glance) or prematurely nested by feature
before a feature has enough files to justify a folder (churn every time
something moves from "one file" to "two files"). The `contexts/` vs
`providers/` split exists because conflating them makes it hard to answer
"is this app state, or is this just because some library needs a
`<Provider>` wrapper" — a question that matters when debugging why
something isn't updating, since home-grown context bugs and third-party
provider config bugs are debugged completely differently. `lib/`'s
"grab-bag but every file still has one job" rule exists because the
alternative — a single `utils.ts` with forty unrelated exports — is
exactly the kind of file nobody wants to open, read, or safely edit.

## Exceptions

- These boundaries are for a **dashboard-scale app** with dozens of routes
  and a real design system. A small app (under, say, ten routes, one or
  two shared components) doesn't need all four component tiers — `ui/` plus
  a flat `components/` is enough until the flat folder actually gets hard
  to scan.
- Don't retroactively split a two-export `lib/` file into a subfolder just
  to match this shape preemptively — split when a concern actually grows
  past one file, not on a fixed schedule.
- A context that's pure prop-drilling avoidance for a single small feature
  (not "ambient app-wide state") is fine to keep colocated with that
  feature instead of promoting it to the top-level `contexts/` folder.

## See also

- [extract-reusable-primitives](../../../extract-reusable-primitives/SKILL.md) — whether to extract a shared primitive at all (search first; one parameterized form instead of another near-duplicate). This skill is only where the file goes once you've decided to pull it out.
- [website-nextjs-dashboard-route-organization](../website-nextjs-dashboard-route-organization/SKILL.md) — the route-private counterpart to this file's top-level layers (`_components`/`_hooks`/`_lib`), and route groups.
- [website-nextjs-dashboard-stack](../website-nextjs-dashboard-stack/SKILL.md) — how the `components/ui/` primitives themselves are built (CVA + Radix).
