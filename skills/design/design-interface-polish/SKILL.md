---
name: design-interface-polish
description: >-
  The detail pass that makes an interface feel finished: concentric radii,
  optical alignment, neutral elevation and image edges, hit areas, text
  wrapping and numerals, icon strokes and states, press and hover feedback,
  pointer cursors, locked states and transition hygiene, plus a review
  report format. Use when building or reviewing UI components, when
  something "feels off", or before calling UI work done.
metadata:
  type: practice
  category: design
---

## Rule

Express every fix in the project's existing styling system (Tailwind
tokens, the component kit's primitives). Never add a second styling system
for a polish fix. Put cross-cutting fixes into the shared primitive, not into
the screen where they were noticed, and apply a correction to every place it
occurs. Motion details beyond press and hover are in
[website-motion](../../website/website-motion/SKILL.md); the visual language
is in [design-taste](../design-taste/SKILL.md).

### Surfaces and shape

- **Concentric radius.** Outer radius = inner radius + the padding between
  them. Same-radius nesting is the most common reason a UI "feels off".
  Above about 24 px of padding, choose each radius on its own.

  ```tsx
  // 8px inner + 8px padding = 16px outer
  <div className="rounded-2xl p-2"><div className="rounded-lg">…</div></div>
  ```

- **One radius scale** (≈ 8 / 12 / 16–22 px by element size). Buttons are
  never rounder than the surfaces around them, and pills appear only for
  buttons and tracks.
- **Neutral elevation.** Shadows and glows are never brand-coloured. Prefer a
  layered, translucent, neutral `box-shadow` ring over a solid border for
  cards, menus and dialogs; keep real borders for structure (dividers, table
  lines, input outlines, selected and focus states).

  ```css
  :root {
    --elev: 0 0 0 1px oklch(0 0 0 / .06), 0 1px 2px -1px oklch(0 0 0 / .06), 0 2px 4px oklch(0 0 0 / .04);
    --elev-hover: 0 0 0 1px oklch(0 0 0 / .08), 0 1px 2px -1px oklch(0 0 0 / .08), 0 2px 4px oklch(0 0 0 / .06);
  }
  .dark { --elev: 0 0 0 1px oklch(1 0 0 / .08); --elev-hover: 0 0 0 1px oklch(1 0 0 / .13); }
  .surface { box-shadow: var(--elev); transition: box-shadow 150ms ease-out; }
  .surface:hover { box-shadow: var(--elev-hover); }
  ```

- **Short shadows.** Control shadows stay around 16 px at rest and 24 px on
  hover. "More decent" means cutting reach and opacity by about a third.
- **Image edges.** Images get a 1 px inset outline in pure black or white at
  10%. Never a tinted grey or the accent, which reads as dirt.

  ```tsx
  <img className="outline outline-1 -outline-offset-1 outline-black/10 dark:outline-white/10" alt="…" />
  ```

- **No clipping of rings, glows or focus.** `overflow: hidden` parents cut
  rings and shadows. Draw rims inset or add padding. A hover or selection
  highlight never touches its container's border.

### Alignment

- **Optical over geometric.** A button with an icon pads the icon side about
  2 px less (`pl-4 pr-3.5`). A play triangle sits about 2 px right of centre.
  Fix asymmetric glyphs in the SVG itself.
- **Measure, don't eyeball.** For adornments inside inputs (a colour dot, an
  icon button), measure the inset on every side in the browser and make
  them equal. The user notices few-pixel offsets in screenshots.
- **Cards in a row end evenly.** Pin footers with `mt-auto`, and measure the
  gap under each card's content.

### Hit areas and pointer

- **Hit areas** are 44 × 44 px for touch and at least 40 × 40 px in dense
  desktop UI. Extend small controls with a centred pseudo-element. Hit areas
  of neighbouring controls never overlap.
- **Pointer cursor.** Everything clickable shows the pointer, set in one base
  rule, because Tailwind 4 resets buttons to the arrow. A row that opens
  something is clickable edge to edge, with hover and press feedback.
- **Locked controls look locked:** no brand colour, no hover, no pointer,
  and a lock icon with the reason where it is known. Style `data-disabled`
  and `data-readonly` with Base UI.

```css
@layer base {
  button:not(:disabled), [role="button"]:not([aria-disabled="true"]),
  [role="menuitem"], [role="option"] { cursor: pointer; }
}
.tiny-control { position: relative; }
.tiny-control::after { content: ""; position: absolute; inset: 50% auto auto 50%; width: 44px; height: 44px; translate: -50% -50%; }
```

### Type

- `text-wrap: balance` for headings and short blocks; `text-wrap: pretty`
  for paragraphs, captions and list items; neither for long text or code.
- Font smoothing once on the root (`antialiased` on `<html>`), never per
  element.
- `tabular-nums` only for numbers that change or align: counters, prices,
  numeric table columns, timers. Never for phone numbers, postcodes or
  names, where it widens hyphens.
- Don't put two amounts with different meanings on one figure line, and
  design out awkward wraps in narrow panels.

### Icons

- One icon set per project (lucide-react in this stack). Never draw icon
  paths by hand.
- Match the stroke to the adjacent text: 1.5 px next to regular text, 2 px
  next to medium/semibold, 2.5 px for bold or standalone emphasis. Keep one
  stroke per surface.
- Size inline icons at about `1em`–`1.25em`, using the set's native sizes
  (16/20/24).
- Draw in `currentColor`. Hover, selected and disabled come from CSS colour
  and opacity. Use the outline variant by default, and the filled variant
  only for the active state.
- Every acting button carries an icon, and the same action looks the same
  everywhere. An icon-only control has an accessible name; decorative icons
  are `aria-hidden`.

### Feedback and transitions

- **Press:** content sinks to 0.96 on controls and 0.99 on wide rows, and
  never below 0.95. Skip it on disabled buttons, and give the primitive an
  opt-out. Use the shared press and release springs from
  [website-motion](../../website/website-motion/SKILL.md).
- **Frequent interactions** (row hover, typing, repeated tab switches) get
  instant feedback, or at most a 150 ms colour or opacity change. Never
  replay an entrance on every hover.
- **Never `transition: all`** (or Tailwind `transition-all`). Name the
  properties, e.g. `transition-[scale,background-color]`.
- **`will-change`** goes only on compositor properties (transform, opacity,
  filter), and only after seeing first-frame stutter.
- **Motion is never the only signal** of a state change; pair it with
  colour, an icon or a label.
- **Buttons keep their size** when their label changes or they turn busy;
  the icon becomes the spinner.

### Review mode

When asked to review UI ("does this feel right?", "polish this screen"):

1. **Pick the mode.** `quick` covers the main path and reports at most 5
   findings (high and medium only). `full` covers every category above, at
   most 15 findings.
2. **Inspect states.** Look at hover, focus, pressed, disabled, loading and
   empty, with animations slowed to 10% (DevTools Animations panel, or the
   capture tools in
   [website-motion verification](../../website/website-motion/verification.md)).
3. **Report:**

```md
**Scope:** full · `src/app/(app)/projects` · Tailwind 4 + kit primitives
Covered: surfaces ✓ alignment ✓ hit areas ✓ type ✓ icons ✓ feedback ✓

| Severity | Where | Before | After | Why |
| --- | --- | --- | --- | --- |
| HIGH | `ui/button.tsx:41` (affects all buttons) | `transition-all` | `transition-[scale,background-color]` | Motion fought the layout spring |
| MEDIUM | `projects/_components/row.tsx:18` | radius 12 inside 12 | inner 8, outer 16 | Same-radius nesting |

**Considered, not changed:** heading tracking (matches the type scale).
**Verified:** screenshots at 1440 and 390 px, states slowed to 10%. **Not verified:** Safari.
**Verdict:** needs changes (no HIGH left after the fix above).
```

How to grade: **HIGH** when someone can't use, read or trust the screen, or
hits the problem again and again; **MEDIUM** when people notice it or it
breaks consistency; **LOW** for a one-off detail, listed only in full mode. Merge a
systemic issue into one row listing every location. Never pad the list, and
say plainly what wasn't checked.

## Why

Small things the user caught again and again add up to "feels off":

- buttons rounder than their surfaces;
- a colour dot a few pixels off-centre in an input;
- clickable rows without a pointer;
- a disabled checkbox that still looked enabled;
- shadows that were blue, or long;
- buttons that changed width when busy;
- `transition-all` fighting a spring.

Each of these became a primitive-level fix, after having been fixed screen
by screen first. The upstream skill this was rebuilt from (see the README)
supplied the systematic parts: radius maths, ring elevation, hit-area
sizes, text wrapping, icon strokes, transition hygiene and the review
format. The user's projects decided where it had to bend: neutral (never
tinted) shadows, the 0.96/0.99 press tokens, and lucide-react as the set.

## Exceptions

- **Brand surfaces.** A deliberate signature effect on a marketing page can
  break the "neutral elevation" rule in brand hues, but never as a coloured
  shadow under ordinary UI.
- **Dense data tables** keep hairline borders on rows. The ring-elevation
  rule is for cards and overlays.
- **Projects with an established design system** keep their own tokens;
  apply the principles, not these exact values.

## See also

- [design-taste](../design-taste/SKILL.md) — the visual direction these details serve.
- [website-motion](../../website/website-motion/SKILL.md) — everything that moves.
- [code-polish](../../code-polish/SKILL.md) — the code-side pass before a commit.
