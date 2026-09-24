---
name: website-nextjs-dashboard-route-organization
description: >-
  How routes are organized inside app/ in a Next.js dashboard — parenthesized
  route groups to separate layout trees (e.g. an authenticated app shell vs.
  a public marketing shell) without affecting the URL, and the underscore
  "_components/_hooks/_lib" convention for colocating a route's own private
  code so it never leaks into the shared component/hook/lib tiers. Use when
  adding a new route/page, deciding whether a component or hook is shared or
  route-private, or when a route's private folder is growing large and needs
  its own internal organization.
metadata:
  type: practice
  category: architecture
---

## Rule

### Route groups separate layout trees, not URLs

A folder wrapped in parentheses — `app/(app)/`, `app/(landing)/` — creates
a route group: it can have its own `layout.tsx`, but the group name itself
never appears in the URL. Use this to give fundamentally different parts of
the same Next.js app (a logged-in product shell vs. a public marketing
shell) completely separate layout trees, root-level UI, and data
requirements, while still sharing one `app/` tree, one `globals.css`, and
one deploy.

```
src/app/
  layout.tsx              # true root: fonts, global providers, <html>/<body>
  (app)/                  # the authenticated product — sidebar, auth guard
    layout.tsx             # sidebar shell, redirects to /login if signed out
    dashboard/page.tsx
    settings/
      layout.tsx            # nested layout: adds the settings sub-nav
      profile/page.tsx
      account/page.tsx
  (landing)/               # the public marketing site — no auth, no sidebar
    layout.tsx               # marketing header/footer shell
    page.tsx                  # "/"
    pricing/page.tsx
    legal/privacy/page.tsx
  login/page.tsx            # ungrouped: outside both shells, its own bare page
```

`(app)`'s layout is where the auth gate lives — read the current user,
redirect to `/login` if absent, and only render the sidebar/content shell
once a user is confirmed present:

```tsx
// app/(app)/layout.tsx (shape, not full implementation)
"use client";
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<ShellSkeleton />}>
      <AuthedShell>{children}</AuthedShell>
    </Suspense>
  );
}

function AuthedShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const user = useCurrentUser({ silent: true }); // null if signed out, doesn't throw

  if (!user) {
    router.push(`/login?next=${encodeURIComponent(pathname)}`);
    return null;
  }

  return (
    <div className="flex flex-1 min-h-0">
      <Sidebar />
      <section className="flex-1 min-w-0 min-h-0 overflow-y-auto">{children}</section>
    </div>
  );
}
```

`(landing)`'s layout has none of that — no auth check, no sidebar, just a
marketing header/footer wrapping static content. Every route under
`(landing)` is a different *kind* of page (public, largely static, SEO-
oriented) from every route under `(app)` (private, dynamic, data-heavy) —
that's the whole reason for the split. **Never write a component that
assumes it can run in both** (e.g. one that reads the authenticated-user
context) — if a piece of UI is genuinely needed in both shells, it belongs
in the shared `components/` tier (see the project-structure skill) and
takes whatever it needs as props, rather than reaching into either group's
ambient context.

A route can nest a second layout further down for a sub-section with its
own persistent chrome — `(app)/settings/layout.tsx` adds a settings-specific
sub-navigation that every page under `settings/` shares, without affecting
`(app)/dashboard` or any other top-level route.

### Private per-route folders: `_components/`, `_hooks/`, `_lib/`

Any folder prefixed with an underscore is excluded from routing by Next.js
— it can sit right next to a route's `page.tsx` without becoming a URL
segment. Use this to colocate everything that's genuinely private to one
route, so the shared `components/`, `hooks/`, and `lib/` tiers only ever
contain things that are actually reused (see
[website-nextjs-dashboard-project-structure](../website-nextjs-dashboard-project-structure/SKILL.md)
for that shared-tier boundary):

```
app/(app)/dashboard/
  page.tsx
  _components/
    greeting.tsx
    stats-grid.tsx
    latest-uploads.tsx
    quick-upload.tsx
    quick-actions.tsx
    notifications-card.tsx
    achievements-card.tsx
```

This convention **scales by file count, not by adding structure** — a
small route like `dashboard/` has half a dozen flat files in
`_components/`; a data-dense route keeps the exact same flat shape, just
with many more files, split across all three private folders once the
route has enough distinct hooks and pure logic to warrant it:

```
app/(app)/images/
  page.tsx
  _components/
    images-toolbar.tsx
    images-filter.tsx
    images-dnd-grid.tsx
    image-item.tsx
    image-item-actions.tsx
    image-item-title.tsx
    image-item-footer.tsx
    image-item-drag-preview.tsx
    bulk-edit-dialog.tsx
    selection-banner.tsx
    selection-checkbox.tsx
    marquee-overlay.tsx
    folder-drag-sidebar.tsx
    images-empty.tsx
    images-pagination-bar.tsx
    images-page-skeleton.tsx
  _hooks/
    use-images-data.ts
    use-images-url-state.ts
    use-image-selection.ts
    use-marquee-selection.ts
    use-images-drag-and-drop.ts
    use-images-keyboard-shortcuts.ts
    use-apply-folder-to-image.ts
    use-fresh-images-counter.ts
    use-suppress-click-after-drag.ts
  _lib/
    constants.ts
    build-images-filter.ts
    image-drag-overlay-modifier.ts
    create-snap-back-drop-animation.ts
```

Notice what didn't happen here: nobody merged `use-images-drag-and-drop.ts`
and `use-marquee-selection.ts` into one "big hook that does selection and
drag" file, and nobody promoted any of this into the shared `hooks/`
folder just because there are now nine of them. **One hook, one concern,
per file — even at this scale** — is what keeps a 15-file `_hooks/` folder
navigable instead of becoming a second monolith one level down from where
the original monolith would have been.

### The promotion rule: private until proven shared

Default every new component/hook/helper to the current route's private
folder. Promote it to the shared tier in `components/`, `hooks/`, or
`lib/` only at the moment a **second, different route** genuinely needs
the same code — not preemptively "in case something else needs this
later." Promoting too early produces shared code with exactly one caller
and speculative flexibility nobody asked for; promoting too late produces
copy-pasted near-duplicates across routes. The trigger is always the
second real caller, not a guess about a future one.

### Colocating page-level data hooks

A route's top-level data-fetching hook (the one `page.tsx` itself calls)
lives in that route's `_hooks/`, named for what it fetches, not for the
route:

```ts
// app/(app)/images/_hooks/use-images-data.ts
export function useImagesData(filter: ImagesFilter) {
  // combines whatever query/cache primitives this app uses for reads —
  // see this app's own data-fetching skill/pattern for what goes here.
}
```

Keep the *fetching* concern (this hook) separate from the *URL state*
concern (`use-images-url-state.ts`, syncing filters to search params) and
the *selection* concern (`use-image-selection.ts`) even though a page may
end up composing all three in `page.tsx` — each hook should be
independently readable and testable without the others in scope.

## Why

Route groups exist because a dashboard and a marketing site in the same
repo have almost nothing in common structurally — different auth
requirements, different rendering priorities, different root chrome — and
forcing them to share one layout tree means every layout decision has to
awkwardly account for both. Splitting them at the route-group level means
each shell's `layout.tsx` can be written as if the other doesn't exist.

The underscore-private convention exists because the alternative — every
route-specific component living in the shared `components/` tree "just in
case" — makes the shared tree impossible to trust: you can no longer tell,
by looking at `components/`, what's actually reused versus what happens to
have zero other callers today. Keeping a route's own code physically next
to that route also means deleting or moving the route is a single
directory operation instead of a repo-wide hunt for orphaned files.

## Exceptions

- A route with only one or two small private components doesn't need
  `_components/` at all — a component can sit directly in the route folder
  as a named file (or even as a non-exported function in `page.tsx` itself)
  until there's enough of it to warrant the subfolder.
- Don't split `_hooks/` and `_lib/` out prematurely for a route that only
  has one or two of either — the three-folder shape is worth the ceremony
  once a route is genuinely data-dense (`images/`-scale), not for every
  route by default.
- If a "route-private" component turns out to be needed by a second route
  soon after being written, move it immediately rather than leaving a
  cross-route import reaching into another route's `_components/` — an
  import that crosses a route's underscore boundary from outside that route
  is always a sign something should have been promoted.

## See also

- [website-nextjs-dashboard-project-structure](../website-nextjs-dashboard-project-structure/SKILL.md) — the shared-tier side of this same boundary (`components/ui`, `components/<feature>`, `hooks/`, `lib/`).
- [website-nextjs-dashboard-stack](../website-nextjs-dashboard-stack/SKILL.md) — the framework/library choices these routes are built on top of.
