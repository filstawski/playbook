# Next.js and React

Rules and traps from building Next.js 16 / React 19 apps and sites. Read the
bundled docs first (see
[../stacks/choosing-dependencies.md](../stacks/choosing-dependencies.md)):
Next.js 16 differs from what models remember.

## Server first; the first client render matches the server

**MUST** · 2026-10 → 2026-11 · websites, dashboard apps (4 sources)

- **Server and client.** Pages and layouts are Server Components. Client
  islands stay small, at the leaves, and get their strings as props.
- **Browser-only values.** What only the browser knows (reduced motion,
  viewport, time, local storage) never changes the first client render. It
  switches after hydration, or lives in CSS (`motion-reduce:`).
- **`<html>` and `<body>`.** Never set attributes on them before React
  hydrates. Set flags when they matter: `onRouterTransitionStart` in
  `instrumentation-client`, or an effect.
- **React Compiler lints.** No setState in effects, and no ref reads during
  render.

**Why:** two hydration errors shipped to a preview this way; only the dev
server reports them, so a production smoke test passed.

```tsx
// Reduced motion without a hydration mismatch: start at full strength, switch after mount.
const strength = useMotionValue(1);
const reduce = useReducedMotion();
useEffect(() => strength.set(reduce ? 0 : 1), [reduce, strength]);
```

## Server–client boundary rules

**MUST** · 2026-08 → 2026-10 · dashboard apps

- **Imports.** A value imported from a `"use client"` module reaches server
  code as a client reference. Put shared constants in a plain module with
  no server imports (`list-constants.ts`). Search-param parsers and client
  tables import from there, never from `queries.ts`, which pulls
  `server-only` and the database driver into the browser bundle.
- **Props.** Props from a server component to a client component must be
  serializable. Pass `icon={<Mail className="size-4" />}`, never
  `icon={Mail}`.
- **`'use server'` files** export only async functions. Re-exporting a type
  from one broke a feature at runtime.
- **One app folder.** Never have both a root `app/` and `src/app/`: Next
  picks the root one, and every route under `src/app` vanishes ("why are
  all the pages nuked").

## Next.js 16 behaviours that bite

**SHOULD** · 2026-10 → 2026-11 · dashboard apps, websites

- **Kept-alive pages.** Next keeps left pages alive in React Activity, so
  state survives navigation (stale signed-in UI after sign-out) and Motion
  exit animations stall while hidden. Reset per visit deliberately.
- **Cache Components.** Pages that read cookies or the session need Suspense
  or `instant = false`, and layout guards don't re-run on client navigation.
  For a handful of sub-pages, use static folders sharing one component; a
  `[slug]` route that reads `params` stops being static.
- **404s under a dynamic root layout.** With `[locale]` as the root layout,
  `notFound()` at request time renders client-only. Have `proxy.ts` rewrite
  unknown paths to the prerendered not-found page with status 404, and
  derive "current page" from layout segments rather than `usePathname()`.
- **Stale generated types.** After deleting a route, remove `.next/types`.
- **Standalone tracing.** A `child_process.spawn` with a computed path makes
  the standalone build trace the whole project. Mark it
  `/*turbopackIgnore: true*/`.

## Turbopack's dev CSS can be stale

**SHOULD** · 2026-10 · dashboard app

Turbopack recompiles dev CSS only for open pages, and a restart may restore
it from `.next/dev`. Don't claim the user's tab updates by itself ("I can't
see the changes, my dashboard is still blueish"). Re-save the file with the
page open, or delete `.next/dev` and restart. Before a local production
build after CSS edits, clear `.next/cache/turbopack`.

## Raise the heap through .npmrc when type checks outgrow it

**CONSIDER** · 2026-10 · dashboard app

When `tsc` or `next build` exceeds Node's default heap, one line in
`.npmrc` covers local scripts, CI, the e2e web server and the Docker build:

```ini
# Type checking the whole app needs ~5 GB; the default heap is ~4.3 GB.
node-options=--max-old-space-size=6144
```

## Forms

**MUST** · 2026-08 → 2026-10 · dashboard apps, websites

- **Library.** Every form uses react-hook-form with `zodResolver`, and the
  client schema is the one the server action extends. Never `useState` per
  field ("haven't I told you to work with zod forms and not plain
  setEmail, setPassword?").
- **Client validation.** Mirror required server rules on the client, so
  errors show before submit.
- **Server errors.** When the server returns field errors, focus and scroll
  to the first one in the shared helper, and repeat the root error next to
  the submit buttons. "Nothing happened when I clicked create" was an error
  under a field scrolled out of view.
- **Enter to submit.** Browsers drop implicit Enter-submit while the submit
  button is disabled, so quick-entry inputs handle Enter themselves and
  dedupe.

See [website-nextjs-dashboard-forms](../../skills/website/nextjs/website-nextjs-dashboard-forms/SKILL.md);
form UX rules are in [../ui-ux/forms.md](../ui-ux/forms.md).

## Mobile web apps

**MUST** · 2026-10 · dashboard app

The phone keyboard shortens the window; nothing may push the app shell up
("the whole page shifts upwards … make sure to fix it generally"):

- Set the viewport to `interactive-widget=resizes-content`.
- Use `overflow: clip` (not `hidden`) on the shell, and stop the document
  scrolling under it.
- Don't autofocus text fields on touch devices when a panel opens.
- Add an e2e test that shrinks the viewport.

On iOS, an installed web app blurs a band under the status bar unless an
element is fixed to the top edge. Add an ~8 px fixed strip in the
background colour under `@media (display-mode: standalone)`.

## Small traps worth checking first

**CONSIDER** · 2026-09 → 2026-10 · dashboard apps

- `scale-x-*` and `scale-y-*` together compile to competing `scale`
  declarations; use `scale-[x_y]`.
- Variant-prefixed classes (`group-*`, `data-*`) outrank plain overrides;
  fix it in the primitive.
- `overflow-hidden` parents clip rings and shadows; draw rims inset or add
  padding. A transformed ancestor becomes the containing block for
  `absolute` children.
- Space collapsible content with padding inside it, not with the parent's
  `gap`, which lingers when the child collapses. A container query can't
  target its own element.
- Chrome's autofill fires keydown with `key` undefined, so read keys
  through a helper that returns `""`.
- When a button swaps out the region it sits in, move focus to the new
  field yourself.
- In JSX, a line break before `{expression}` drops the space.
  `tabular-nums` belongs on numbers only.

## Performance on effect-heavy pages

**SHOULD** · 2026-10 → 2026-11 · company website

- **LCP element.** The page's largest element (heading or hero image) arrives
  by transform only and is visible from the first frame. Chrome counts an
  opacity animation into LCP until it ends.
- **`:has()`.** Never hang it on `body`, `html` or page containers; Chrome
  restyles the whole subtree on every change.
- **Heavy work.** Move pixel-by-pixel work into a Web Worker, and preload
  the largest texture with high fetch priority.
- **Measuring.** Measure on an emulated mid-range phone (4× CPU, slow 4G):
  TBT, LCP, scroll stalls, tap latency. One pass cut main-thread blocking
  from 265–546 ms to 64–146 ms with no visible change.

## Accessibility: WCAG 2.2 AA is the bar

**SHOULD** · 2026-11 · websites, dashboard apps

- **Structure.** One `h1` per page, ordered headings, landmarks, and a skip
  link first.
- **Keyboard.** Everything is operable by keyboard, with a visible focus
  ring.
- **Overlays.** They make the rest of the page inert, move focus in, close
  on Escape and restore focus.
- **Text alternatives.** Meaningful `alt` text is in the UI language, and
  decorative images get `alt=""`.
- **Forms.** Fields have labels, `autocomplete`,
  `aria-invalid`/`aria-describedby`, and the first wrong field gets focus on
  submit.
- **Contrast.** Note each text pairing's contrast ratio beside its token.

**Why:** an accessibility pass on a site whose design otherwise looked done
still found five problems.
