# Components

How UI components are sourced, placed and kept reusable in React apps. Where
files go in a dashboard app is detailed in
[website-nextjs-dashboard-project-structure](../../skills/website/nextjs/website-nextjs-dashboard-project-structure/SKILL.md),
which was revised on 2026-11-03 to match the placement rule below.

## Use the installed component kit first, always

**MUST** · 2026-09 → 2026-10 · dashboard apps (4 sources)

Before building any UI piece, even a placeholder, check `components/ui/` and
the kit's registry, and use its component. That covers titles, breadcrumbs,
menus, dialogs, avatars, OTP inputs and spinners. Add missing ones with the
shadcn CLI, then restyle them. Decline CLI prompts that would overwrite
primitives you have already customized.

**Why:** "Use shadcn's breadcrumb. How often do I have to say use the shadcn
components."

## components/ui is for kit components only

**MUST** · 2026-09 → 2026-11 · dashboard apps (4 sources)

`components/ui/` holds components sourced from the kit (shadcn on Base UI)
and direct extensions of them, however reworked. Other files go elsewhere:

| What | Where |
| --- | --- |
| Hand-built generic components (bars, filter menus, value displays) | flat in `components/` |
| Cross-cutting groups of components | `components/<group>/` |
| Shared state (context + hook) | `src/contexts/` |
| Thin provider wrappers | `src/providers/` |
| Code used by one route only | that route's `_components/`, `_lib/` and `_hooks/` |

Import the headless library (Base UI) only inside `components/ui/`; features
compose those wrappers. Check the structure skill before creating a file;
don't place it by feel.

**Exception:** a marketing site without a kit (as built from the website template) keeps
its own hand-built primitives (button, layout, prose) in `components/ui/`
and motion primitives in `components/motion/`. This rule applies to apps
built on a kit.

**Why:** the user keeps `components/ui/` "for just shadcn UI things and
maybe extensions". Components that imported Base UI directly ended up
duplicating a filter's styling.

## Shape the kit for the house style; fix behaviour in the primitive

**SHOULD** · 2026-09 → 2026-10 · dashboard apps

shadcn is the base, not the look ("they almost never stay plain shadcn, but
we have a good base"):

- After `shadcn init`, point its colour, radius and shadow names at the
  project's tokens, and switch off Tailwind's default palette, radii and
  shadows.
- Rework stock primitives that look bare (select, dialog, checkbox).
- Put cross-cutting behaviour into the primitive, opt-in through a prop when
  it could change existing uses: tab content height, invalid shake, busy
  state, cursor, dropdown width. Don't patch it screen by screen.

Feature code reuses existing primitives instead of copying their look line
by line.

**Why:** the user wants behaviour such as animations reused, so it goes into
the primitive: "implement that logic directly into the tabs component to
have it all in one place".

## Build generic mechanics as primitives on first use

**MUST** · 2026-09 → 2026-11 · dashboard apps (5 sources)

A generic mechanic gets its own file the first time it's needed: height
animation, press feedback, label swap, highlight, breadcrumb state. Give it
a generic name, a doc comment, and the options the next use will plausibly
need (`axis: "height" | "width" | "both"`, `transition`, `animateInitial`).
Never squeeze it into the feature that first needed it, and never wait for
the third copy. Merge near-duplicates: create and edit forms become one
form; ten copies of a spring become one constant.

**Why:** "I told you multiple times that you have to build the code future
oriented … don't squeeze it into the login component, make it its own
component."

**See also:** [extract-reusable-primitives](../../skills/extract-reusable-primitives/SKILL.md)

## Prefer a future-oriented API over hard-coded markup

**SHOULD** · 2026-09 · client dashboard app

Shell state that pages override (breadcrumbs, titles) is a provider plus a
hook, with a tiny client component that renders nothing, so async server
pages can set it too:

```tsx
// in a server page
<SetBreadcrumb items={[{ label: labels.projects, href: "/projects" }, { label: project.name }]} />
```

**Why:** "Can we use some more modern, reusable, future-oriented approach
like context, where we can just do useBreadcrumb … This is how I expect you
to work."

## One hook per concern; components stay readable

**SHOULD** · 2026-10 · dashboard apps (3 sources)

When a component juggles many `useState`/`useEffect`/`useMemo` hooks for
one concern, move that concern into a named hook (`useSearchAnswer`:
debounce, request, keep the last answer while loading). A parent doing
several jobs hands each stateful concern to a route-local
`_hooks/use-*.ts`, and its children own their own side effects. Count the
hooks per component before handing over UI work.

**Why:** "Some components … have like 100 hooks instead of cleaning them
up." One composer went from 9 hooks in about 230 lines to 2 hooks in 65.

## Server pages stay lean

**SHOULD** · 2026-10 · client dashboard app

A server page fetches, then calls one function from
`_lib/<name>-view.ts` that returns exactly what the JSX places. The page body
only lays out values.

**Why:** a page "looked a bit bloated on the top before the HTML", and the
user asked for it to be cleaned up.

## Presentational lists don't bring their own card

**SHOULD** · 2026-08 · dashboard app

A table or list component renders only the table. The page or card that
hosts it adds the surface (border, radius, padding). Otherwise reusing it
inside a card gives double borders, doubled padding and clipped rings.

## Base UI specifics

**SHOULD** · 2026-08 → 2026-10 · dashboard apps

shadcn on Base UI differs from the Radix flavour:

- **Polymorphism** is `render={<Link />}`, not `asChild`. A router link that
  looks like a button is its own `ButtonLink`, not `Button render`, which
  adds `role="button"`.
- **Select** needs an explicit `items={[{ value, label }]}` on the root at
  every call site, or the trigger shows the raw value. Don't auto-collect
  labels from the item children: that captures icons and secondary text.
- **Menu labels:** `DropdownMenuLabel` must sit inside `DropdownMenuGroup`,
  or it throws.
- **Keyboard:** dialogs stop keydown from bubbling and radio groups swallow
  Enter, so global shortcuts need capture-phase listeners.
- **Disabled:** `focusableWhenDisabled` sets `data-disabled` and
  `aria-disabled`, so style those attributes.
- **react-hook-form:** field-array `update` regenerates ids, so key rows by a
  stable domain key. A submit event bubbles through portals into an outer
  form; stop it at the inner form.
