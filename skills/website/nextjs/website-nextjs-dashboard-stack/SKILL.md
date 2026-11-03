---
name: website-nextjs-dashboard-stack
description: >-
  Default stack and library choices for a Next.js-based internal/product
  dashboard (App Router, latest React, Tailwind v4, Radix-based shadcn-style UI
  primitives with CVA variants, TanStack Query, react-hook-form + Zod,
  motion, sonner). Use when scaffolding a new dashboard-style Next.js app,
  choosing a UI component approach, or deciding how a design-system
  component (button, card, field) should be built. This is specifically for
  a logged-in product dashboard, not a marketing/content site — see the
  Exceptions section.
metadata:
  type: practice
  category: tooling
---

## Rule

### The stack, concretely

- **Framework.** Next.js App Router, latest stable release, latest React,
  TypeScript, `"use client"` on every interactive layout/page — this is a
  dashboard behind auth, not a content site, so there is little upside to
  chasing RSC purity. Server Components stay reserved for the rare case
  that's genuinely static (e.g. an OG image route). Always install
  whatever `next`/`react` versions are actually current when scaffolding —
  don't pin to a version number named in this skill, which will drift out
  of date the moment a new major ships.
- **Styling.** Tailwind, latest major (v4 at time of writing —
  `@tailwindcss/postcss`, CSS-first config via `@theme inline` in
  `globals.css`, no `tailwind.config.js`). This detail is genuinely
  version-specific: v4's CSS-first config is a real break from v3's
  `tailwind.config.js` model, so confirm which major a new project is
  actually on before assuming this shape applies. Plus `tw-animate-css`
  for animation utility classes Tailwind doesn't ship,
  `class-variance-authority` (CVA) for variant props, `tailwind-merge` +
  `clsx` (wrapped as `cn()`) for merging conditional class strings without
  specificity fights.
- **UI primitives.** A shadcn-style local component library under
  `components/ui/` — thin wrappers around `radix-ui` (the unified
  `radix-ui` package, not per-primitive `@radix-ui/react-*` packages)
  giving unstyled, accessible behavior, styled with Tailwind + CVA variants.
  Every primitive is source you own and edit directly, not a black-box
  dependency — see the component example below.
- **Data/server state.** TanStack Query v5 (`@tanstack/react-query`) for
  request lifecycle (loading/error/retry/caching), never bespoke
  `useEffect` + `useState` fetch code.
- **Forms.** `react-hook-form` + `zod` via `@hookform/resolvers/zod`. See
  [website-nextjs-dashboard-forms](../website-nextjs-dashboard-forms/SKILL.md)
  for the full pattern.
- **Animation.** `motion` (the renamed `framer-motion`, imported as
  `motion/react`) for layout transitions, `AnimatePresence` mount/unmount,
  and spring-based micro-interactions on buttons/cards.
- **Feedback.** `sonner` for toasts, mounted once at the root layout as
  `<Toaster />`.
- **Auxiliary, pull in as needed, don't pre-install speculatively:**
  `@dnd-kit/core` + `@dnd-kit/utilities` (drag and drop, e.g. dragging
  items into folders), `vaul` (mobile-style drawers), `react-colorful`
  (color pickers), `js-cookie` (reading an auth token client-side),
  `next-themes` (light/dark), `@discordjs/collection` (a `Map` subclass
  with array-like helpers — generically useful, not Discord-specific
  despite the package name).

### UI primitives are CVA-variant wrappers you own, not a dependency

Every `components/ui/*` file follows the same shape: a `cva(...)` call
defining the variant → class-string map, a thin component that resolves
`className` through `cn(variants({...}), className)`, and `data-slot` /
`data-variant` attributes so the DOM stays inspectable and CSS-selectable
(`data-[variant=...]:...`) without prop-drilling extra classes.

```tsx
// components/ui/card.tsx
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const cardVariants = cva(
  "text-card-foreground flex flex-col gap-6 rounded-xl py-6 bg-card border shadow-sm",
  {
    variants: {
      variant: {
        default: "",
        destructive: "border-destructive/20 bg-destructive/5 shadow-none",
        warning: "border-warning/20 bg-warning/5 shadow-none",
        outline:
          "border-border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground",
      },
    },
    defaultVariants: { variant: "default" },
  },
);

function Card({
  className,
  variant,
  ...props
}: React.ComponentProps<"div"> & VariantProps<typeof cardVariants>) {
  return (
    <div
      data-slot="card"
      data-variant={variant}
      className={cn(cardVariants({ variant }), className)}
      {...props}
    />
  );
}

export { Card, cardVariants };
```

`cn()` itself is two lines and lives in `lib/utils.ts` — every component
imports it instead of hand-rolling `className={`${a} ${b}`}`, so
conditionally-conflicting Tailwind classes (e.g. two different `px-*`
utilities) resolve deterministically via `tailwind-merge` instead of
whichever string happens to come last:

```ts
// lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

A component can optionally support two "dimensions" — a flat variant and a
more decorated one — by defining a second `cva` map and switching on a
prop, rather than making the base variants themselves try to encode both
looks:

```tsx
// components/ui/button.tsx (excerpt)
const sizes = {
  default: "h-9 px-4 py-2 has-[>svg]:px-3",
  sm: "h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5",
  icon: "size-9",
  // ...
} as const;

const buttonVariants = cva(base, {
  variants: { variant: { default: "...", destructive: "...", outline: "..." }, size: sizes },
  defaultVariants: { variant: "default", size: "default" },
});

// A second, more visually elaborate variant map for the "3d" look
// (gradient surface, inset highlight/shadow, spring hover/tap via motion).
const button3dVariants = cva(`${base} relative isolate transition-[box-shadow,filter,background-image] duration-150 ease-out`, {
  variants: { variant: { /* gradient + shadow classes per variant */ }, size: sizes },
  defaultVariants: { variant: "default", size: "default" },
});

export type ButtonProps = React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & { asChild?: boolean; dimension?: "2d" | "3d" };

function Button({ dimension = "3d", variant = "default", size = "default", asChild, className, ...props }: ButtonProps) {
  const variants = dimension === "3d" ? button3dVariants : buttonVariants;
  const classes = cn(variants({ variant, size, className }));
  const Comp = asChild ? Slot.Root : "button";
  return <Comp data-slot="button" data-variant={variant} data-size={size} className={classes} {...props} />;
}
```

`asChild` + Radix's `Slot` is the standard escape hatch for "render this
component's styling/behavior onto whatever child element the caller
passes" (e.g. a `Button` that's actually a `next/link` `<a>`), instead of
writing a separate `LinkButton` component.

### Path aliasing and local package linking

```json
// tsconfig.json
{ "compilerOptions": { "paths": { "@/*": ["./src/*"] } } }
```

Every import uses `@/...` instead of relative `../../../` chains — this
matters a lot once route-private `_components`/`_hooks`/`_lib` folders
nest several levels deep (see
[website-nextjs-dashboard-route-organization](../website-nextjs-dashboard-route-organization/SKILL.md)).

When the dashboard consumes a sibling package under active local
development (a generated SDK, a shared types package) rather than a
published version, link it via `file:`:

```json
// package.json
{ "dependencies": { "@myorg/sdk": "file:../sdk" } }
```

```ts
// next.config.ts
const nextConfig: NextConfig = {
  transpilePackages: ["@myorg/sdk"],
  // Turbopack (Next.js's default bundler as of recent major versions) frequently fails to resolve
  // file:/npm-link packages that live outside the app's own directory tree.
  // Pointing the trace root at the monorepo parent fixes resolution.
  outputFileTracingRoot: path.join(process.cwd(), ".."),
};
```

`transpilePackages` is required because a locally-linked TypeScript package
usually ships untranspiled source, not a prebuilt `dist/` — without it,
Next's bundler chokes on the package's raw `.ts` files.

## Why

A shadcn-style local component library (own the source, wrap Radix, style
with Tailwind+CVA) beats both "hand-roll every primitive from scratch" and
"depend on an opaque component library": you get accessible behavior for
free from Radix, but full control over markup/styling/variants when a
design requirement doesn't fit the library's assumptions — which happens
constantly in a dashboard with dense, custom UI (drag-and-drop grids,
inline-editable fields, popover-portaled menus). TanStack Query instead of
hand-rolled fetch state exists because request lifecycle (loading, error,
retry, cache invalidation, background refetch) is exactly the kind of thing
that's tedious and error-prone to reimplement per-component, and doing it
consistently matters more in a data-dense dashboard than almost anywhere
else in the app.

## Exceptions

- This is a **product dashboard** stack — a logged-in app with dense,
  interactive, data-driven screens. A marketing/content site (landing
  pages, pricing, legal) wants a different, lighter stack (more static
  rendering, less client-side state, no TanStack Query) — that's a
  separate future skill, not this one. If a route in the same repo is
  clearly a content page (see the `(landing)` route group example in
  [website-nextjs-dashboard-route-organization](../website-nextjs-dashboard-route-organization/SKILL.md)),
  don't force this stack's patterns onto it.
- `dimension="3d"` / gradient-surface component variants are a visual
  preference, not a structural requirement — a flat `variant`/`size` CVA
  map with no second "look" is completely fine and is in fact the more
  common case; only reach for a second variant map when a component
  genuinely needs two distinct visual treatments selectable at runtime.
- **Newer projects (Oct 2026 on) use shadcn on Base UI**, not on Radix:
  polymorphism is `render={<Link />}` instead of `asChild`, and Select
  needs an explicit `items` map. Apps that own their backend replace
  TanStack Query reads with Server Components. See
  [guidelines/stacks/web-stack.md](../../../../guidelines/stacks/web-stack.md)
  and [guidelines/frontend/components.md](../../../../guidelines/frontend/components.md).
  This skill stays as the thin-client variant (decided 2026-11-03).
- Don't reach for `file:` package linking + `transpilePackages` unless a
  sibling package is under active local co-development. Once it's stable,
  publish it (even to a private registry) — resolving raw TypeScript
  source through the bundler on every dev-server start is slower than
  consuming a built package.
