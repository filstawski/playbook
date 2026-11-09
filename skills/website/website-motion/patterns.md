# Motion patterns

Real, runnable code from the user's projects, with names generalized. Assumes Next.js 16,
React 19.2+, Tailwind 4, `motion` ≥13.4 (`motion/react`, `motion/react-m`), a `cn()` helper, and an
`@/` alias.

## P0. Foundation: tokens, CSS twins, provider

**When:** every project, first.

```ts
// src/lib/motion.ts — type-only imports so `node scripts/springs.mjs` can load it.
import type { Transition } from "motion/react";

/** Small things popping in (menu, tooltip, check); jelly width. ~38% overshoot. */
export const SPRING_IN: Transition = { type: "spring", stiffness: 750, damping: 16 };
/** Surfaces and content arriving; jelly height. ~10%. */
export const LIFT: Transition = { type: "spring", stiffness: 390, damping: 23 };
/** Big shapes where a wobble reads as a mistake (sidebar width). ~5%. */
export const SETTLE: Transition = { type: "spring", stiffness: 420, damping: 28 };
/** Heights and positions in flow. No overshoot: it would shove what's below. */
export const ITEM_REORDER: Transition = { type: "spring", stiffness: 480, damping: 40 };
/** Opacity is always a tween. */
export const ITEM_ENTER: Transition = { duration: 0.2 };
export const ITEM_EXIT: Transition = { duration: 0.12, ease: "easeOut" };
/** A new list item waits while its neighbours glide, so the two never cross. */
export const ARRIVE_DELAY = 0.1;
/** Physics springs, so a release mid-press carries its velocity into the rebound. */
export const PRESS_TRANSITION: Transition = { type: "spring", stiffness: 2000, damping: 80 };
export const RELEASE_TRANSITION: Transition = { type: "spring", stiffness: 500, damping: 16 };

/** The springs CSS plays too, written into motion-tokens.css by scripts/springs.mjs. */
export const CSS_SPRINGS = {
  "spring-in": SPRING_IN,
  "spring-lift": LIFT,
  "spring-settle": SETTLE,
  "spring-reorder": ITEM_REORDER,
} as const;
```

```js
// scripts/springs.mjs — `node scripts/springs.mjs` writes, `--check` fails CI when stale.
// (Node ≥22.18 / ≥23.6 strips TS types by default; older 22.x needs `--experimental-strip-types`.)
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { spring } from "motion";
import { CSS_SPRINGS } from "../src/lib/motion.ts";

const FILE = fileURLToPath(new URL("../src/app/motion-tokens.css", import.meta.url));
const BEGIN = "/* BEGIN generated springs */";
const END = "/* END generated springs */";

const lines = Object.entries(CSS_SPRINGS).flatMap(([name, { stiffness, damping }]) => {
  // Motion serialises a spring as "<duration>ms linear(…)".
  const [duration, ...curve] = String(spring({ keyframes: [0, 1], stiffness, damping })).split(" ");
  return [`  --${name}: ${curve.join(" ")};`, `  --${name}-duration: ${duration};`];
});

const css = readFileSync(FILE, "utf8");
const start = css.indexOf(BEGIN);
const end = css.indexOf(END);
if (start === -1 || end === -1) throw new Error("motion-tokens.css lost its generated-block markers.");
const next = `${css.slice(0, start + BEGIN.length)}\n${lines.join("\n")}\n  ${css.slice(end)}`;

if (process.argv.includes("--check")) {
  if (next !== css) {
    console.error("motion-tokens.css is out of date: run `node scripts/springs.mjs`.");
    process.exit(1);
  }
} else {
  writeFileSync(FILE, next);
}
```

```css
/* src/app/motion-tokens.css — imported by globals.css before motion.css */
:root {
  /* BEGIN generated springs */
  /* (filled by the script: --spring-in, --spring-in-duration, …) */
  /* END generated springs */

  --ease-out: cubic-bezier(0.16, 1, 0.3, 1); /* hovers, underlines */
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1); /* state changes over 300ms */
  --fade-in: 200ms;
  --fade-out: 120ms;
  --arrive-shift: 12px;
  --stagger: 70ms;
  --page-out: 100ms;
  --page-in: 160ms;
  --page-in-after: 50ms;
  --page-shift: 10px;
  --tab-shift: 16px;
}

/* Reduced motion keeps the fades and drops the travel. */
@media (prefers-reduced-motion: reduce) {
  :root {
    --arrive-shift: 0px;
    --page-shift: 0px;
    --tab-shift: 0px;
  }
}
```

```tsx
// src/lib/motion-features.ts — domMax (not domAnimation) because layout/layoutId need it.
export { domMax as default } from "motion/react";

// src/providers/motion.tsx — mounted once in the root layout.
"use client";
import { LazyMotion, MotionConfig } from "motion/react";
import type { ReactNode } from "react";

const loadFeatures = () => import("@/lib/motion-features").then((mod) => mod.default);

/** Reduced motion honoured here once (transforms/layout off, fades stay). `strict` rejects `motion.*`. */
export function MotionProvider({ children }: { children: ReactNode }) {
  return (
    <MotionConfig reducedMotion="user">
      <LazyMotion features={loadFeatures} strict>
        {children}
      </LazyMotion>
    </MotionConfig>
  );
}
```

**Pitfalls:** `motion/react` has no `"use client"` of its own → wrap in a client provider.
`MotionConfig reducedMotion="user"` only stops transforms/layout; CSS must quiet the rest. Animations
that read an element's own `--delay` must be declared in Tailwind `@theme inline` (in plain `@theme`
they resolve on `:root` and silently don't run). The generated block must be formatted the way the
repo's Prettier formats CSS, or `format:check` and `motion:check` fight.


---

## P1. Presence enter/exit and content swaps (`ContentSwap`)

**When:** a label, status line or block is replaced by another (badge text, a step of a wizard,
list vs board, skeleton → data).

- `overlap`: old and new cross in one grid cell (labels).
- `sequence`: old leaves before the new arrives (blocks of very different size), inside `AnimateDimensions`.
- Only a change animates (`initial={false}`), so the server's HTML is what shows first.
- `reserve` (newest marketing site): lay every possible content invisibly in the same cell so the box is as
  tall as the tallest from the start.

```tsx
"use client";
import { AnimatePresence } from "motion/react";
import * as m from "motion/react-m";
import type { ReactNode } from "react";
import { ITEM_ENTER, ITEM_EXIT, SPRING_IN } from "@/lib/motion";
import { cn } from "@/lib/utils";

/** Swaps content when `swapKey` changes: new rises `shift` px into place, old drifts half as far up and fades. */
export function ContentSwap({
  swapKey,
  mode = "overlap",
  shift = 6,
  as = "span",
  reserve,
  className,
  children,
}: {
  swapKey: string | number;
  mode?: "overlap" | "sequence";
  shift?: number;
  as?: "span" | "div";
  /** Everything it may show, kept invisible in the same cell so nothing around it moves (overlap only). */
  reserve?: ReactNode;
  className?: string;
  children: ReactNode;
}) {
  const overlap = mode === "overlap";
  const Box = as;
  const Item = as === "div" ? m.div : m.span;
  return (
    <Box className={cn(overlap && (as === "div" ? "grid" : "inline-grid"), className)}>
      {overlap && reserve ? (
        <Box aria-hidden inert className="invisible col-start-1 row-start-1 grid opacity-0 *:col-start-1 *:row-start-1">
          {reserve}
        </Box>
      ) : null}
      <AnimatePresence initial={false} mode={overlap ? "sync" : "wait"}>
        <Item
          key={swapKey}
          className={cn(overlap ? "col-start-1 row-start-1" : as === "span" && "block")}
          initial={{ opacity: 0, y: shift }}
          animate={{ opacity: 1, y: 0, transition: { opacity: ITEM_ENTER, y: SPRING_IN } }}
          exit={{ opacity: 0, y: -shift / 2, transition: ITEM_EXIT }}
        >
          {children}
        </Item>
      </AnimatePresence>
    </Box>
  );
}
```

Element that comes and goes in place (a button leaving after an action):

```tsx
<AnimatePresence initial={false}>
  {canUpload ? (
    <m.div
      key="upload"
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1, transition: { opacity: ITEM_ENTER, scale: SPRING_IN } }}
      exit={{ opacity: 0, scale: 0.96, transition: ITEM_EXIT }}
    >
      <UploadButton />
    </m.div>
  ) : null}
</AnimatePresence>
```

**Pitfalls/fixes:**
- A component that unmounts can't play its exit: render it always and move the condition inside
  its `AnimatePresence`.
- `AnimatePresence initial={false}` also suppresses the first animation of nested motion elements
  (useful: an already-done check isn't redrawn on page load).
- Don't use `popLayout` for swaps inside a size-animating box (measured: both panels in flow ~150 ms,
  the wrapper ballooned to the sum of both). Use `wait` + a fast exit.
- A word that fades out over a control in the same grid cell must get `pointer-events: none` (at
  opacity 0 it still takes the click).
- A badge whose words change: key a new badge rather than crossing the words inside one (its width
  would change at once under gliding neighbours).


---

## P2. Height/width "auto" (`Collapse`, `AnimateDimensions`, `FieldError`)

**When:** content opens/closes (`Collapse`); a box whose content is swapped at once must not snap
(`AnimateDimensions`: tab panels, dialog bodies, steps, lists that gain items); an error under a
field (`FieldError`).

```tsx
// Collapse — opens by growing its height, fades; only a change animates.
"use client";
import { AnimatePresence, PresenceContext, type Transition, useReducedMotion, type Variants } from "motion/react";
import * as m from "motion/react-m";
import { type ReactNode, useContext, useState } from "react";
import { ITEM_ENTER, ITEM_EXIT, ITEM_REORDER } from "@/lib/motion";

const INSTANT: Transition = { duration: 0 };

/** Space it with padding via className — never the parent's gap or a margin (they jump at start/end). */
export function Collapse({ open, className, children }: { open: boolean; className?: string; children: ReactNode }) {
  return (
    <AnimatePresence initial={false}>
      {open ? (
        <CollapseBox key="collapse" className={className}>
          {children}
        </CollapseBox>
      ) : null}
    </AnimatePresence>
  );
}

function CollapseBox({ className, children }: { className?: string; children: ReactNode }) {
  const height = useReducedMotion() ? INSTANT : ITEM_REORDER;
  // A box open on the first render has nothing to finish; otherwise it would clip forever.
  const presence = useContext(PresenceContext);
  const [settled, setSettled] = useState(presence?.initial === false);
  const variants: Variants = {
    closed: { height: 0, opacity: 0, overflow: "hidden", transition: { height, opacity: ITEM_EXIT } },
    open: { height: "auto", opacity: 1, overflow: "hidden", transition: { height, opacity: ITEM_ENTER } },
    // Motion drops transitionEnd after easing to "auto", so un-clip through a state of its own.
    settled: { height: "auto", opacity: 1, overflow: "visible", transition: INSTANT },
  };
  return (
    <m.div
      variants={variants}
      initial="closed"
      animate={settled ? "settled" : "open"}
      exit="closed"
      onAnimationComplete={(name) => {
        if (name === "open") setSettled(true);
      }}
    >
      <div className={className}>{children}</div>
    </m.div>
  );
}
```

```tsx
// AnimateDimensions — the box never snaps to a new size.
"use client";
import { animate, type Transition, useMotionValue } from "motion/react";
import { type CSSProperties, type ReactNode, useLayoutEffect, useRef } from "react";
import { ITEM_REORDER } from "@/lib/motion";

type Dimension = "height" | "width";
type Size = Record<Dimension, number>;
const MARGIN = { height: "marginBottom", width: "marginRight" } as const;
const measure = (el: HTMLElement): Size => ({ width: el.offsetWidth, height: el.offsetHeight });
// Nodes/text swapped or a restyling attribute: the size changed at once. `style` changes are
// how Motion moves things frame by frame (content animating its own size) and are followed live.
const changedAtOnce = (records: MutationRecord[]) =>
  records.some((r) => r.type !== "attributes" || r.attributeName !== "style");

// Nested boxes ease innermost first, in one microtask, before anything paints.
const pending = new Map<HTMLElement, () => void>();
const depthOf = (node: Node) => {
  let depth = 0;
  for (let at = node.parentNode; at; at = at.parentNode) depth += 1;
  return depth;
};
function easeSoon(el: HTMLElement, change: () => void) {
  if (pending.size === 0) {
    queueMicrotask(() => {
      const changes = [...pending].sort(([a], [b]) => depthOf(b) - depthOf(a));
      pending.clear();
      for (const [, run] of changes) run();
    });
  }
  pending.set(el, change);
}

/**
 * Content that animates its own size is followed frame by frame (the box has its size). A change
 * that happens at once holds the old size via a margin on the content that springs back to 0.
 * Not Motion `layout` (scale-based, distorts children with their own transforms). Clips only while easing.
 */
export function AnimateDimensions({
  children,
  axis = "height",
  transition = ITEM_REORDER,
  className,
  style,
}: {
  children: ReactNode;
  axis?: "height" | "width" | "both";
  transition?: Transition;
  className?: string;
  style?: CSSProperties;
}) {
  const boxRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const heightOffset = useMotionValue(0); // a number, never "auto": "auto" never tracks velocity
  const widthOffset = useMotionValue(0);
  const latest = useRef(transition);
  useLayoutEffect(() => {
    latest.current = transition;
  });

  useLayoutEffect(() => {
    const box = boxRef.current;
    const el = contentRef.current;
    if (!box || !el) return;
    const offsets = (
      [
        ["height", heightOffset],
        ["width", widthOffset],
      ] as const
    ).filter(([d]) => axis === "both" || axis === d);

    const unsubscribes = offsets.map(([d, offset]) =>
      offset.on("change", (value) => {
        el.style[MARGIN[d]] = `${value}px`;
        box.style.overflow = offsets.some(([, o]) => o.get() !== 0) ? "hidden" : "";
      }),
    );

    function ease(from: Size, to: Size) {
      for (const [d, offset] of offsets) {
        const diff = from[d] - to[d];
        if (diff === 0) continue;
        const velocity = offset.getVelocity(); // keep speed if still easing from a change before
        offset.jump(offset.get() + diff);
        animate(offset, 0, { ...latest.current, velocity });
      }
    }

    let shown = measure(el);
    const mutations = new MutationObserver((records) => {
      if (!changedAtOnce(records)) return;
      easeSoon(el, () => {
        const size = measure(el);
        ease(shown, size);
        shown = size;
      });
    });
    mutations.observe(el, { childList: true, characterData: true, attributes: true, subtree: true });
    const resizes = new ResizeObserver(() => {
      shown = measure(el);
    });
    resizes.observe(el);

    return () => {
      pending.delete(el);
      mutations.disconnect();
      resizes.disconnect();
      for (const [d, offset] of offsets) {
        offset.jump(0);
        el.style[MARGIN[d]] = "";
      }
      box.style.overflow = "";
      for (const off of unsubscribes) off();
    };
  }, [axis, heightOffset, widthOffset]);

  return (
    <div ref={boxRef} data-slot="animate-dimensions" className={className} style={style}>
      <div ref={contentRef}>{children}</div>
    </div>
  );
}
```

```tsx
// FieldError — the parent's gap is taken back as a negative margin and given out as padding inside,
// so while its height is 0 it takes no room at all (the "gap trap").
function FieldErrorMessage({ children }: { children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);
  const [gap, setGap] = useState(0);
  useLayoutEffect(() => {
    const parent = ref.current?.parentElement;
    if (parent) setGap(Number.parseFloat(getComputedStyle(parent).rowGap) || 0);
  }, []);
  return (
    <m.div
      ref={ref}
      className="overflow-hidden"
      style={{ marginTop: -gap }}
      initial={{ height: 0, opacity: 0 }}
      animate={{ height: "auto", opacity: 1, transition: { height: ITEM_REORDER, opacity: ITEM_ENTER } }}
      exit={{ height: 0, opacity: 0, transition: { height: ITEM_REORDER, opacity: ITEM_EXIT } }}
    >
      <div role="alert" className="text-sm text-error" style={{ paddingTop: gap }}>
        {children}
      </div>
    </m.div>
  );
}
// Usage: <AnimatePresence initial={false}>{message ? <FieldErrorMessage key="e">{message}</FieldErrorMessage> : null}</AnimatePresence>
```

An invalid field's rim also eases (300 ms in-out) and a ring ripples out once:

```css
@keyframes well-invalid {
  from { outline: 2px solid color-mix(in oklch, var(--error) 45%, transparent); outline-offset: 0; }
  to { outline: 2px solid transparent; outline-offset: 5px; }
}
@utility animate-well-invalid {
  animation: well-invalid 550ms ease-out;
  @media (prefers-reduced-motion: reduce) { animation: none; }
}
```

**Pitfalls/fixes (all measured):**
- Spacing by the parent's `gap` or a margin jumps in before the height grows and out after it shrinks: pad inside.
- What must glide while the box eases (a form's buttons, a glow) stands after the box, not in it:
  inside, it lost its glow at rest and dropped into place as the box shrank.
- Don't put `max-h` on the padded inner box of a dialog body (the box hides overflow); let the
  dialog cap its own height and the body scroll.
- A spring starts at zero velocity, so a 12 px height change looked "late" next to a 24 px slide;
  the user then tuned a height tween to 0.05 s and asked for "a slight spring" ("it doesnt bounce"):
  on 12 px any overshoot is sub-pixel; duration, not bounce, is the lever.
- Clips only while easing, so focus rings/shadows inside show at rest; give room as padding with a
  matching negative margin (`className="-m-1 p-1"`).


---

## P3. Stable swaps and busy buttons (`StableSwap`, `BusyIcon`, `useHeld`)

**When:** a button's label or icon changes (copy → copied, save → spinner, send → stop).


```css
/* One icon of a set that swaps in place: old shrinks and fades; new grows in on LIFT once the old
   is half gone (never overlapping). CSS, so React's work on the same click can't stall it. */
@utility swap-icon {
  opacity: 0;
  scale: 0.6;
  visibility: hidden;
  transition:
    opacity var(--fade-out) ease-out,
    scale var(--fade-out) ease-out,
    visibility 0s var(--fade-out);

  &[data-active] {
    opacity: 1;
    scale: none;
    visibility: visible;
    transition:
      opacity var(--fade-in) ease-out calc(var(--fade-out) / 2),
      scale var(--spring-lift-duration) var(--spring-lift) calc(var(--fade-out) / 2),
      visibility 0s;
  }

  @media (prefers-reduced-motion: reduce) {
    scale: none;
  }
}
```

```tsx
"use client";
import type { Variants } from "motion/react";
import * as m from "motion/react-m";
import { type ReactNode, useEffect, useState } from "react";
import { ITEM_ENTER, ITEM_EXIT, SPRING_IN } from "@/lib/motion";
import { cn } from "@/lib/utils";

/** All states mounted in one grid cell, sized by the largest; inactive ones invisible + aria-hidden. */
export function StableSwap<K extends string>({
  active,
  states,
  shift = 6,
  icon = false,
  className,
}: {
  active: K;
  states: Record<K, ReactNode>;
  shift?: number;
  /** Icons pop (CSS swap-icon) instead of rising. */
  icon?: boolean;
  className?: string;
}) {
  const variants: Variants = {
    shown: { opacity: 1, y: [shift, 0], transition: { opacity: ITEM_ENTER, y: SPRING_IN } },
    hidden: { opacity: 0, y: -shift / 2, transition: ITEM_EXIT },
  };
  return (
    <span className={cn("inline-grid", className)}>
      {(Object.keys(states) as K[]).map((key) => {
        const shown = key === active;
        return icon ? (
          <span
            key={key}
            data-active={shown || undefined}
            aria-hidden={shown ? undefined : true}
            className="swap-icon col-start-1 row-start-1 inline-flex items-center justify-center"
          >
            {states[key]}
          </span>
        ) : (
          <m.span
            key={key}
            data-active={shown || undefined}
            aria-hidden={shown ? undefined : true}
            // Visibility in CSS: hidden right when the 120ms fade ends, visible at once.
            className="invisible col-start-1 row-start-1 inline-flex items-center transition-[visibility] delay-120 duration-0 data-active:visible data-active:delay-0"
            variants={variants}
            initial={false}
            animate={shown ? "shown" : "hidden"}
          >
            {states[key]}
          </m.span>
        );
      })}
    </span>
  );
}

/** Once on, stays on for at least `min` ms, so a quick spinner doesn't blink. */
export function useHeld(on: boolean, min: number): boolean {
  const [was, setWas] = useState(on);
  const [holding, setHolding] = useState(false);
  if (was !== on) {
    setWas(on);
    if (on) setHolding(true);
  }
  useEffect(() => {
    if (!holding) return;
    const timer = window.setTimeout(() => setHolding(false), min);
    return () => window.clearTimeout(timer);
  }, [holding, min]);
  return on || holding;
}

/** A button's icon that turns into a spinner while busy, in the same spot. */
export function BusyIcon({ busy, icon }: { busy: boolean; icon: ReactNode }) {
  const spinning = useHeld(busy, 600);
  return (
    <StableSwap
      icon
      active={spinning ? "busy" : "ready"}
      states={{ ready: icon, busy: <Spinner aria-hidden className="size-3.5" /> }}
    />
  );
}

// Usage: busy looks disabled but keeps focus (Base UI: focusableWhenDisabled), says aria-busy.
// <Button disabled={busy} focusableWhenDisabled aria-busy={busy || undefined}>
//   <BusyIcon busy={busy} icon={<Save />} /> Save
// </Button>
```

```css
/* The button greying out as it goes busy: even, 300ms in-out (an ease-out lands it in ~50ms = a
   jump). Press and disabled use the SAME filter functions in the same order, or Chrome jumps
   discretely between them. */
.control {
  transition: filter 240ms var(--ease-out), box-shadow 240ms var(--ease-out);
}
.control:active { filter: saturate(1) brightness(0.94); transition-duration: 110ms; }
.control:disabled,
.control[data-disabled] {
  filter: saturate(0.4) brightness(0.8);
  transition: filter 300ms var(--ease-in-out), box-shadow 300ms var(--ease-in-out);
}
```

**Pitfalls/fixes:** pause/hide what isn't showing (a hidden spinner spun forever at opacity 0 on
every page); `display: none` on a pseudo-element cuts (fade its opacity); states worded to similar
length (a long state made a confirm button a third too wide); an icon-only variant for a phone row
keeps rows one line. The client-site template and its sites use a simpler `IconSwap` (AnimatePresence
`popLayout`, scale 0.25 + blur 4 px on `SPRING_FAST`) — fine for a site, but the CSS swap above is
the one the user approved after three rounds.


---

## P4. Shared-element morph via `layoutId`: selection/hover indicator, tab & segmented pill

**When:** a mark that shows which item is current/hovered in a nav, menu, select, segmented
control, tabs, table rows.

Core rule: moving between items is a **bare `layoutId` takeover** — the old item's mark unmounts,
the new item's mounts with the same `layoutId`, Motion slides it. Plain `{cond ? <Mark/> : null}`;
**no `AnimatePresence`, no `initial`/`exit`** on it (they replay on every move); `initial={false}`
is the one safe form. Presence (grow in from nothing / shrink out) lives in shared MotionValues.

```tsx
"use client";
import { animate, type MotionValue, type Transition, useMotionValue } from "motion/react";
import * as m from "motion/react-m";
import { type FocusEvent, useEffect, useId, useState } from "react";

const SLIDE: Transition = { type: "spring", bounce: 0.2, duration: 0.35 };
const STRETCH: Transition = { type: "spring", stiffness: 600, damping: 30 };
const MOVING_STRETCH = 1.04;
const MOVING_SQUASH = 0.97;
const HIDDEN_SCALE = 0.4;
const ENTER = { opacity: { duration: 0.2 }, scale: { type: "spring", stiffness: 420, damping: 26 } } satisfies Record<string, Transition>;
// easeIn keeps it visible while it shrinks; a plain fade hid the shrink ("too short or doesnt work").
const EXIT = { opacity: { duration: 0.15, ease: "easeIn" }, scale: { type: "spring", stiffness: 260, damping: 28 } } satisfies Record<string, Transition>;
const SLIDE_BACK_MIN_OPACITY = 0.2;

export function SelectionIndicator({
  layoutId,
  opacity,
  scale,
  axis = "x",
  className,
}: {
  layoutId: string;
  opacity: MotionValue<number>;
  scale: MotionValue<number>;
  axis?: "x" | "y";
  className: string;
}) {
  // Local: an interrupted slide never fires its completion, and a lifted flag would stick.
  const [moving, setMoving] = useState(false);
  // Stable per instance (re-renders never re-measure it, so a popup positioning itself doesn't
  // "jump" the mark), different between instances (or Motion skips the slide). Never `layoutId`.
  const layoutDependency = useId();
  return (
    <m.span
      data-slot="selection-indicator"
      layoutId={layoutId}
      layoutDependency={layoutDependency}
      className={`pointer-events-none absolute ${className}`}
      style={{ opacity, scale }}
      initial={false}
      animate={
        axis === "x"
          ? { scaleX: moving ? MOVING_STRETCH : 1, scaleY: moving ? MOVING_SQUASH : 1 }
          : { scaleX: moving ? MOVING_SQUASH : 1, scaleY: moving ? MOVING_STRETCH : 1 }
      }
      transition={{ layout: SLIDE, scaleX: STRETCH, scaleY: STRETCH }}
      onLayoutAnimationStart={() => setMoving(true)}
      onLayoutAnimationComplete={() => setMoving(false)}
    />
  );
}

/** Follows pointer and focus, rests on `restKey` (current page) or grows in/shrinks out without one. */
export function useHighlight(restKey: string | null) {
  const baseId = useId(); // unique per group, or marks fly between unrelated menus
  const [hoveredKey, setHoveredKey] = useState<string | null>(null);
  // Two ids alternate: a mark that faded away grows in fresh instead of flying over.
  const [parity, setParity] = useState(0);
  const shownKey = hoveredKey ?? restKey;
  // Where it's drawn: stays put when nothing is shown, so it shrinks out there.
  const [indicatorKey, setIndicatorKey] = useState(shownKey);
  if (shownKey !== null && shownKey !== indicatorKey) setIndicatorKey(shownKey);

  const shown = shownKey !== null;
  const opacity = useMotionValue(shown ? 1 : 0);
  const scale = useMotionValue(shown ? 1 : HIDDEN_SCALE);
  useEffect(() => {
    animate(opacity, shown ? 1 : 0, shown ? ENTER.opacity : EXIT.opacity);
    animate(scale, shown ? 1 : HIDDEN_SCALE, shown ? ENTER.scale : EXIT.scale);
  }, [shown, opacity, scale]);

  const highlight = (key: string) => {
    if (!shown && indicatorKey !== key && opacity.get() < SLIDE_BACK_MIN_OPACITY) setParity((p) => 1 - p);
    setHoveredKey(key);
  };

  return {
    indicatorKey,
    indicatorProps: { layoutId: `${baseId}-${parity}`, opacity, scale },
    // Leaving the group clears it; gaps/separators between items don't.
    groupProps: {
      onPointerLeave: () => setHoveredKey(null),
      onBlur: (event: FocusEvent<HTMLElement>) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setHoveredKey(null);
      },
    },
    itemProps: (key: string) => ({ onPointerEnter: () => highlight(key), onFocus: () => highlight(key) }),
  };
}

// Usage: a nav whose mark rests on the current page and follows the pointer.
export function Nav({ items, current }: { items: { href: string; label: string }[]; current: string }) {
  const { indicatorKey, indicatorProps, groupProps, itemProps } = useHighlight(current);
  return (
    <ul className="flex gap-1" {...groupProps}>
      {items.map((item) => (
        <li key={item.href} className="relative">
          {indicatorKey === item.href ? (
            <SelectionIndicator {...indicatorProps} className="inset-0 rounded-full bg-white/10" />
          ) : null}
          {/* content lifted above every mark: rows NOT isolated, content relative z-10 */}
          <a href={item.href} className="relative z-10 block px-3 py-1.5" {...itemProps(item.href)}>
            {item.label}
          </a>
        </li>
      ))}
    </ul>
  );
}
```

Simplest form, for a group that always has a selection (segmented control / tabs):

```tsx
export function SegmentedControl<T extends string>({ options, value, onChange, label }: {
  options: { value: T; label: string }[];
  value: T;
  onChange: (value: T) => void;
  label: string;
}) {
  const pillId = useId();
  return (
    <div role="group" aria-label={label} className="flex w-max gap-1 rounded-md bg-black/5 p-1">
      {options.map((option) => {
        const selected = option.value === value;
        return (
          <button
            key={option.value}
            type="button"
            aria-pressed={selected}
            onClick={() => onChange(option.value)}
            className="relative h-9 rounded px-4 transition-colors duration-150"
          >
            {selected ? (
              <m.span layoutId={pillId} className="absolute inset-0 rounded bg-black" transition={{ type: "spring", bounce: 0.2, duration: 0.35 }} />
            ) : null}
            <span className={selected ? "relative text-white" : "relative text-black/70"}>{option.label}</span>
          </button>
        );
      })}
    </div>
  );
}
```

**Pitfalls/fixes (measured in the first dashboard app):**
- `initial` on the mark replayed a shrink→grow on every move; `AnimatePresence` kept two stack
  members alive → Motion crossfaded them (opacity dipped to ~0.5 mid-move).
- `layoutDependency={layoutId}` made every pill in the app warp instead of slide.
- Stacking: the mark leaves its own row while sliding, so it must sit behind **every** row's content.
  Either rows not isolated + content `relative z-10`, or `isolate` on the container of all rows +
  mark `-z-10`. `isolate`/opacity/transform on a row brings back "the indicator is above the items while sliding".
- A Tailwind class colour on the mark snaps (layoutId doesn't track class backgrounds): keep the
  mark one colour, signal destructive via text colour.
- Set transforms on a layoutId element via Motion only; for its own press scale, nest two elements.
  Don't scale an ancestor while it moves (it measures a shrunken box and snaps at the end).
- Between items of different widths side by side (tabs, filters), slide the whole mark on one
  spring; a liquid leading/trailing-edge bead carried a long tab's width out of a short one
  ("looks horrible for a split second").
- A grid of columns gets one mark per column, or it flies across diagonally.
- Hovering an item inside a radio-segment row should clear the menu's hover mark so two never show.

**Liquid alternative (`SelectionBead`)** — used in the newest app: a positioned span whose four
edges run on hand-stepped springs (leading edge `BEAD.lead` 620/36, trailing `BEAD.trail` 280/24),
so it stretches on the way and gathers on arrival; length clamped to 0.7–2.5× its target row;
overshoot damped to ≤3 px on long trips; reduced motion places it; a server-rendered `BeadRest`
marks the current row until it hydrates. Stepper:

```ts
// spring.ts — one value on a spring, stepped at 240 Hz so it's stable at any frame rate.
export type Sprung = { value: number; velocity: number };
const STEP = 1 / 240;
export function spring(s: Sprung, target: number, elapsed: number, { stiffness, damping }: { stiffness: number; damping: number }, atRest: number) {
  for (let left = elapsed; left > 0; left -= STEP) {
    const step = Math.min(left, STEP);
    s.velocity += (-stiffness * (s.value - target) - damping * s.velocity) * step;
    s.value += s.velocity * step;
  }
  return Math.abs(s.value - target) > atRest || Math.abs(s.velocity) > atRest; // still moving?
}
```


---

## P5. Card moving between containers (manual FLIP "flight") and list reorder

**When:** an item changes column/group after an action (kanban move via menu or drop) and must
travel from where it was.

```tsx
// Board: record where a card left from, then let the card that lands fly from there on LIFT.
const FlightsContext = createContext<RefObject<Map<string, { from: DOMRect; scale: number }>> | null>(null);

function Board({ items, move }: { items: Item[]; move: (id: string, to: string) => void }) {
  const flights = useRef(new Map<string, { from: DOMRect; scale: number }>());
  const moveCard = (id: string, to: string, scale = 1) => {
    const card = document.querySelector(`[data-card="${CSS.escape(id)}"]`);
    if (card) flights.current.set(id, { from: card.getBoundingClientRect(), scale });
    move(id, to);
  };
  return <FlightsContext.Provider value={flights}>{/* columns render <Card onMove={moveCard} /> */}</FlightsContext.Provider>;
}

function Card({ item }: { item: Item }) {
  const flights = useContext(FlightsContext);
  const ref = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const scale = useMotionValue(1);
  useLayoutEffect(() => {
    const flight = flights?.current.get(item.id);
    const el = ref.current;
    if (!flights || !flight || !el) return;
    flights.current.delete(item.id);
    const to = el.getBoundingClientRect();
    x.jump(flight.from.left + flight.from.width / 2 - (to.left + to.width / 2));
    y.jump(flight.from.top + flight.from.height / 2 - (to.top + to.height / 2));
    scale.jump(flight.scale);
    animate(x, 0, LIFT);
    animate(y, 0, LIFT);
    animate(scale, 1, LIFT);
  }, [flights, item.id, item.group, x, y, scale]);
  return (
    <m.div
      ref={ref}
      data-card={item.id}
      layout="position" // siblings glide to close/make room
      transition={{ layout: ITEM_REORDER }}
      style={{ x, y, scale }}
      drag
      dragSnapToOrigin
      dragMomentum={false}
      whileDrag={{ scale: 1.03, zIndex: 30, cursor: "grabbing" }}
    >
      {/* card */}
    </m.div>
  );
}
```

**Pitfalls:** a drag ends with pointer-up over the card's link → swallow that click; boards inside
recessed containers looked odd with elevated cards (user disliked "an elevated element within a
recessed element"). Also always offer a non-drag way to move (menu/buttons).


---

## P6. List add / remove / reorder

**When:** chips in a combobox, rows in a settings list, badges/buttons in a row.

```tsx
// A row of things that come and go (badges, buttons): one going fades where it was, popped out of
// flow; the others glide; one coming fades in once they've made room.
export function ArrivingRow({ className, children }: { className?: string; children: ReactNode }) {
  return (
    <div className={cn("relative flex flex-wrap items-center", className)}>
      <AnimatePresence initial={false} mode="popLayout">
        {children}
      </AnimatePresence>
    </div>
  );
}

export function ArrivingItem({ ref, children }: { ref?: Ref<HTMLSpanElement>; children: ReactNode }) {
  return (
    <m.span
      ref={ref} // forwarded: popLayout measures it to pop it out
      layout="position"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, transition: ITEM_EXIT }}
      transition={{ layout: ITEM_REORDER, opacity: { ...ITEM_ENTER, delay: ARRIVE_DELAY } }}
      className="inline-flex"
    >
      {children}
    </m.span>
  );
}

// A vertical list with an empty state, the box easing as rows come and go:
<AnimateDimensions className="-m-1 p-1">
  <AnimatePresence initial={false} mode="popLayout">
    {rows.length === 0 ? (
      <m.p key="none" initial={{ opacity: 0 }} animate={{ opacity: 1, transition: ITEM_ENTER }} exit={{ opacity: 0, transition: ITEM_EXIT }}>
        Nothing here yet.
      </m.p>
    ) : null}
  </AnimatePresence>
  <ul>
    <AnimatePresence initial={false}>
      {rows.map((row) => (
        <m.li
          key={row.id}
          layout="position"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0, transition: ITEM_EXIT }}
          transition={{ layout: ITEM_REORDER, opacity: ITEM_ENTER }}
        >
          {row.name}
        </m.li>
      ))}
    </AnimatePresence>
  </ul>
</AnimateDimensions>
```

**Pitfalls:** `layout="position"` (not `layout`) so rows don't scale; no bounce on reorder (several
items overshooting past each other is noise); a new row showed through the one making room until
it waited `ARRIVE_DELAY`; a badge widening under a gliding neighbour → key a new badge; a library's
DOM nodes (toasts) must never be removed by tests. Stop staggering past ~8 items.


---

## P7. View Transitions for route/tab changes in an app (content-only page turn)

**When:** navigating between pages or a record's tabs in an app with persistent chrome.


```ts
// src/hooks/use-navigation-move.ts
"use client";
import { useLayoutEffect, useState } from "react";
export type Move = "forward" | "back" | "none";

/** Writes `data-{name}-move` on <html> as the new key commits (inside the transition), so CSS sees
 *  the direction for the old snapshot as well as the new. Direction comes from the two routes. */
export function useNavigationMove(name: string, key: string, direction: (from: string, to: string) => Exclude<Move, "none">): Move {
  const [shown, setShown] = useState<{ key: string; move: Move }>({ key, move: "none" });
  if (shown.key !== key) setShown({ key, move: direction(shown.key, key) });
  useLayoutEffect(() => {
    const root = document.documentElement;
    root.setAttribute(`data-${name}-move`, shown.move);
    return () => root.setAttribute(`data-${name}-move`, "none");
  }, [name, shown]);
  return shown.move;
}
```

```tsx
// src/components/navigation/content-transition.tsx
"use client";
import { useSelectedLayoutSegments } from "next/navigation";
import { ViewTransition, type ReactNode } from "react";
import { useNavigationMove } from "@/hooks/use-navigation-move";

const NAV_ORDER = ["/", "/inbox", "/projects", "/settings"]; // the sidebar's order, top to bottom
const rank = (path: string) => {
  const i = NAV_ORDER.indexOf(path === "/" ? "/" : `/${path.split("/")[1]}`);
  return i === -1 ? NAV_ORDER.length : i;
};
const depth = (path: string) => path.split("/").filter(Boolean).length;
/** Down the sidebar or deeper into a section is forward; up or back out is back. */
function direction(fromKey: string, toKey: string) {
  const from = `/${fromKey}`;
  const to = `/${toKey}`;
  if (rank(from) !== rank(to)) return rank(to) > rank(from) ? "forward" : "back";
  return depth(to) >= depth(from) ? "forward" : "back";
}

export function ContentTransition({ children }: { children: ReactNode }) {
  const segments = useSelectedLayoutSegments();
  const tabs = segments.indexOf("(tabs)"); // a page's tabs are one page here
  const key = (tabs === -1 ? segments : segments.slice(0, tabs)).join("/");
  const move = useNavigationMove("page", key, direction);
  return (
    <ViewTransition key={key} enter={move === "none" ? "none" : "page"} exit="page" default="none">
      <div data-slot="page" className="absolute inset-0 overflow-y-auto overscroll-contain">
        {children}
      </div>
    </ViewTransition>
  );
}
```

```css
/* Only the content moves; the chrome (with its sliding mark) swaps live — a crossfaded root
   snapshot left a ghost of the mark where it was. */
html::view-transition-old(root) { display: none; }
html::view-transition-new(root) { animation: none; }
::view-transition { pointer-events: none; } /* clicks reach the live page */

/* Pages clip to the content plane, so what drifts past an edge slips under it. */
::view-transition-group(.page) { overflow: clip; border-radius: var(--plane-radius, 12px); }

@keyframes page-fade-out { to { opacity: 0; } }
@keyframes page-move-out { to { translate: 0 var(--out-y, 0); } }
@keyframes page-fade-in { from { opacity: 0; } }
@keyframes page-move-in { from { translate: 0 var(--in-y, 0); } }

html[data-page-move="forward"]::view-transition-old(.page),
html[data-page-move="back"]::view-transition-old(.page) {
  animation:
    var(--page-out) ease-out both page-fade-out,
    var(--spring-reorder-duration) var(--spring-reorder) both page-move-out;
}
html[data-page-move="forward"]::view-transition-new(.page),
html[data-page-move="back"]::view-transition-new(.page) {
  animation:
    var(--page-in) ease-out var(--page-in-after) both page-fade-in,
    var(--spring-lift-duration) var(--spring-lift) both page-move-in;
}
/* The old page drifts half as far the other way. */
html[data-page-move="forward"]::view-transition-old(.page) { --out-y: calc(var(--page-shift) * -0.5); }
html[data-page-move="forward"]::view-transition-new(.page) { --in-y: var(--page-shift); }
html[data-page-move="back"]::view-transition-old(.page) { --out-y: calc(var(--page-shift) * 0.5); }
html[data-page-move="back"]::view-transition-new(.page) { --in-y: calc(var(--page-shift) * -1); }

/* Back/forward commit synchronously (no view transition): the arriving page animates itself. */
html[data-traverse] [data-slot="page"] {
  animation:
    var(--page-in) ease-out both page-fade-in,
    var(--spring-lift-duration) var(--spring-lift) both page-move-in;
}
html[data-traverse][data-page-move="forward"] [data-slot="page"] { --in-y: var(--page-shift); }
html[data-traverse][data-page-move="back"] [data-slot="page"] { --in-y: calc(var(--page-shift) * -1); }

/* First load arrives part by part; after the first navigation, pages arrive by the turn only. */
@keyframes arrive-fade { from { opacity: 0; } }
@keyframes arrive-rise { from { translate: 0 var(--arrive-shift); } }
@utility animate-arrive {
  html:not([data-navigated]) & {
    animation:
      arrive-fade var(--fade-in) ease-out backwards,
      arrive-rise var(--spring-lift-duration) var(--spring-lift) backwards;
    animation-delay: var(--arrive-delay, 0ms);
  }
}
```

```ts
// src/instrumentation-client.ts — marks navigations (never touch <html> before hydration otherwise).
export function onRouterTransitionStart(_url: string, navigationType: "push" | "replace" | "traverse") {
  const root = document.documentElement;
  root.dataset.navigated = "";
  if (navigationType === "traverse") root.dataset.traverse = "";
  else delete root.dataset.traverse;
}
```

Tab panels: same pattern with class `tab` and a horizontal shift; the tab mark moves optimistically
on click (`useOptimistic` + `startTransition(() => router.push(href, { scroll: false }))`), the
panel's boundary is keyed on the **real** segment (`useSelectedLayoutSegment()`), inside
`AnimateDimensions`; pending content dims after 150 ms (`transition-opacity duration-200
data-pending:opacity-60 data-pending:delay-150`).

Title morph (one shared element per navigation):

```tsx
import { ViewTransition, type ReactElement } from "react";
const nameOf = (key: string) => `title-${key.replace(/[^a-zA-Z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
/** Same name on the list row's title and the page heading; the child must hug its text (inline-block). */
export function TitleTransition({ id, children }: { id: string; children: ReactElement }) {
  return (
    <ViewTransition name={nameOf(id)} share="page-title" default="none">
      {children}
    </ViewTransition>
  );
}
```
```css
::view-transition-group(.page-title) {
  z-index: 1;
  animation-duration: var(--spring-reorder-duration); /* no overshoot: it crosses half the page */
  animation-timing-function: var(--spring-reorder);
}
::view-transition-old(.page-title),
::view-transition-new(.page-title) { animation-duration: var(--page-out); animation-timing-function: ease-out; }
@media (prefers-reduced-motion: reduce) { ::view-transition-group(.page-title) { animation-duration: 0s; } }
```

Wait for a running transition before opening something over the page (a sheet):

```ts
export async function afterViewTransitions(): Promise<void> {
  await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r))); // it starts a frame or two late
  const running = document.getAnimations().filter((a) => {
    const effect = a.effect;
    return effect instanceof KeyframeEffect && (effect.pseudoElement?.startsWith("::view-transition") ?? false);
  });
  await Promise.all(running.map((a) => a.finished.catch(() => undefined)));
}
```

**Pitfalls/fixes (measured):**
- `default="none"` on every boundary, or every boundary crossfades on any transition (filters too).
- Transition **types** on `<Link>` reached another commit (Next commits the link's pending state
  first): only 6/14 tab switches slid. Derive direction from the routes.
- **Any update in the frame before a view transition starts skips it** (a hidden tooltip still
  repositioning made every sidebar navigation snap). Log `transition.ready` for a skip first.
- A near-critical spring on 8 px reads as a CSS ease: check overshoot in px (`shift * (peak-1)`).
- Named elements are skipped by hit-testing during the transition: don't name what's clicked quickly.
- An element with `view-transition-name` is a backdrop root: a `backdrop-filter` inside it blurs
  only itself. Name translucent (backdrop-filtered) chrome only while a transition runs:
  `[html:active-view-transition_&]:[view-transition-name:site-header]`.
- What lies outside the named page is the live page during a transition; rules on
  `::view-transition-*(root)` change nothing — ease live chrome with CSS transitions.
- Back/forward: React applies traverses synchronously → no transition; animate the arriving page itself.
- Don't do App-Router page transitions with `AnimatePresence` in a template (old page unmounts at once).


---

## P8. Page transitions on a marketing site (+ cross-document fallback, theme switch)

**When:** a website with a fixed header.

```tsx
// src/components/page-transition.tsx — around the page in the layout, keyed on the path.
"use client";
import { usePathname } from "next/navigation";
import { ViewTransition, type ReactNode } from "react";
export function PageTransition({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  return (
    <ViewTransition key={pathname} enter="page" exit="page" default="none">
      {children}
    </ViewTransition>
  );
}
// Alternative used in the client-site template: <ViewTransition enter="page" exit="page" default="none">
// inside each page (not a layout: layouts persist, their enter/exit never fire).
```

```css
@keyframes page-fade-out { to { opacity: 0; } }
@keyframes page-move-out { to { translate: 0 calc(var(--page-shift) * -0.5); } }
@keyframes page-fade-in { from { opacity: 0; } }
@keyframes page-move-in { from { translate: 0 var(--page-shift); } }

/* Fades overlap a little: the page dissolves rather than blinks. */
::view-transition-old(.page) {
  animation: 200ms ease-out both page-fade-out, 350ms var(--ease-spring-out) both page-move-out;
}
::view-transition-new(.page) {
  animation: 260ms ease-out both page-fade-in, 850ms var(--ease-spring-in) both page-move-in;
}
/* Everything but the page swaps at once; the header holds still above it. */
::view-transition-old(root) { display: none; }
::view-transition-new(root) { animation: none; }
::view-transition-group(site-header) { z-index: 1; animation: none; }
::view-transition-old(site-header) { display: none; }
::view-transition-new(site-header) { animation: none; }
::view-transition { pointer-events: none; }

/* A full page load within the site crossfades too, where the browser can. */
@view-transition { navigation: auto; types: full-load; }
html:active-view-transition-type(full-load)::view-transition-old(root) { display: block; animation: 150ms ease-out both page-fade-out; }
html:active-view-transition-type(full-load)::view-transition-new(root) { animation: 300ms ease-out both page-fade-in; }

@media (prefers-reduced-motion: reduce) {
  :root { --page-shift: 0px; }
}
```

```tsx
// <html data-scroll-behavior="smooth">: anchors glide (CSS scroll-behavior), but Next makes the
// scroll instant on page changes, so a new page starts at its top at once (Next 16 no longer does
// this by itself).
<html lang={locale} data-scroll-behavior="smooth">
```

```ts
// Header state that changes with scroll is held until the transition ends, then eased:
const inViewTransition = () => document.getAnimations().some((a) =>
  a.effect instanceof KeyframeEffect && (a.effect.pseudoElement?.startsWith("::view-transition") ?? false));
function afterViewTransition(then: () => void) {
  const wait = () => (inViewTransition() ? requestAnimationFrame(wait) : then());
  requestAnimationFrame(wait);
}
```

Theme switch as one crossfade (app):

```ts
"use client";
import { useTheme } from "next-themes"; // ThemeProvider with disableTransitionOnChange
import { useCallback } from "react";
import { flushSync } from "react-dom";
export function useThemeTransition() {
  const { setTheme, ...rest } = useTheme();
  const set = useCallback((next: string) => {
    if (!document.startViewTransition || matchMedia("(prefers-reduced-motion: reduce)").matches) return setTheme(next);
    const root = document.documentElement;
    root.dataset.themeTransition = "";
    // next-themes applies the class in an effect; flushSync runs it before the new snapshot.
    const t = document.startViewTransition(() => flushSync(() => setTheme(next)));
    t.finished.catch(() => {}).finally(() => delete root.dataset.themeTransition); // skipped if clicked fast
  }, [setTheme]);
  return { ...rest, setTheme: set };
}
```
```css
html[data-theme-transition]::view-transition-old(root),
html[data-theme-transition]::view-transition-new(root) { animation-duration: 300ms; animation-timing-function: ease-in-out; }
/* The switcher stays live (its mark keeps sliding) — one element only, names must be unique. */
html[data-theme-transition] [data-theme-transition-live] { view-transition-name: theme-live; }
html[data-theme-transition]::view-transition-group(theme-live),
html[data-theme-transition]::view-transition-new(theme-live) { animation: none; }
html[data-theme-transition]::view-transition-old(theme-live) { display: none; }
/* The page-turn rule hiding root's old snapshot must exclude theme switches: */
html:not([data-theme-transition])::view-transition-old(root) { display: none; }
```

**Pitfalls/fixes:** page snapshot drawn over the header made it vanish on every switch (name the
header); a page opened from far down arrived scrolled and slid up (`data-scroll-behavior`); a
scroll-linked hero fade flashed for a frame during the transition (pause it under
`:root:active-view-transition`); an ambient light per page restarted and jumped → one light in the
layout eased between looks via registered custom properties (`@property` with px initial values);
change a selected mark in an ordinary commit, not inside the transition's update callback (it warped).


---

## P9. Skeleton / loading → content crossfade

**When:** data arrives after an action (a picker loading folders, a view switch answered by the
server, an assistant reply).

```tsx
// Inside a fixed-min-height well: skeleton, empty state and rows all go through one swap.
<div className="max-h-72 min-h-40 overflow-y-auto">
  <ContentSwap as="div" swapKey={rows === null ? "loading" : JSON.stringify(location)}>
    {rows === null ? (
      <div className="flex flex-col gap-1.5 p-2">
        {[70, 55, 62].map((w) => (
          <Skeleton key={w} className="h-7" style={{ width: `${w}%` }} />
        ))}
      </div>
    ) : rows.length === 0 ? (
      <p className="px-3 py-6 text-center text-sm">No folders here.</p>
    ) : (
      <RowList rows={rows} />
    )}
  </ContentSwap>
</div>

// A view switch: the control moves on the click, the content swaps once the server answers.
const [active, setActive] = useOptimistic(view);
const [isPending, startTransition] = useTransition();
// …onClick: startTransition(() => { setActive(next); router.push(href, { scroll: false }); })
<div data-pending={isPending || undefined} className="transition-opacity duration-200 data-pending:opacity-60 data-pending:delay-150">
  <AnimateDimensions>
    <ContentSwap as="div" mode="sequence" swapKey={view /* the rendered one, not the clicked one */}>
      {view === "board" ? <Board /> : <List />}
    </ContentSwap>
  </AnimateDimensions>
</div>
```

**Rules from incidents:** one page width for every view (width chosen by the click but content by
the server made everything slide back and forth); keep view switches away from search fields (the
mark slid into the search); the busy indicator exists from the moment of the click; the default
`animate-pulse` skeleton is the shadcn one (no custom shimmer was made). A page or tab with no data
is never blank: an Empty state says why and offers the next step.


---

## P10. Number / text morph (rolling letters, digit roll, word morph, streamed tokens)

**When:** a label that reacts to hover (nav links), a counter that changes, a word that changes with
locale, streamed AI text. Note: "counters counting up" from 0 were
banned on the marketing site (render "0", claim precision) — change numbers by rolling, don't count.

Rolling letters on hover (CSS, nothing clipped, two layers):

```tsx
import { Fragment } from "react";
/** Put `group/roll` on the link. Screen readers get the label whole. */
export function RollText({ text }: { text: string }) {
  const words = text.split(" ");
  let at = 0;
  const offsets = words.map((w) => { const start = at; at += w.length + 1; return start; });
  const layer = (roll: "roll-out" | "roll-in") => (
    <span className="col-start-1 row-start-1">
      {words.map((word, i) => (
        <Fragment key={i}>
          {i > 0 && " "}
          <span className="whitespace-nowrap">
            {[...word].map((letter, j) => (
              <span key={j} className={roll} style={{ "--i": offsets[i] + j } as React.CSSProperties}>
                {letter}
              </span>
            ))}
          </span>
        </Fragment>
      ))}
    </span>
  );
  return (
    <>
      <span aria-hidden className="inline-grid">{layer("roll-out")}{layer("roll-in")}</span>
      <span className="sr-only">{text}</span>
    </>
  );
}
```
```css
/* Each letter a beat (14ms) after the one before; the copy rises in a moment after (+90ms), so the
   two are seldom seen together; short rises so nothing passes a pill's edge. Touch never leaves it rolled. */
@utility roll-out {
  display: inline-block;
  white-space: pre;
  transition:
    translate 450ms var(--ease-lift) calc(var(--i) * 14ms),
    opacity 260ms var(--ease-fade) calc(var(--i) * 14ms + 90ms);
  @media (prefers-reduced-motion: no-preference) {
    :where(.group\/roll:focus-visible) & { translate: 0 -0.3lh; opacity: 0; transition-duration: 450ms, 160ms; transition-delay: calc(var(--i) * 14ms), calc(var(--i) * 14ms); }
    @media (hover: hover) {
      :where(.group\/roll:hover) & { translate: 0 -0.3lh; opacity: 0; transition-duration: 450ms, 160ms; transition-delay: calc(var(--i) * 14ms), calc(var(--i) * 14ms); }
    }
  }
}
@utility roll-in {
  display: inline-block;
  white-space: pre;
  translate: 0 0.3lh;
  opacity: 0;
  transition:
    translate 450ms var(--ease-lift) calc(var(--i) * 14ms),
    opacity 160ms var(--ease-fade) calc(var(--i) * 14ms);
  @media (prefers-reduced-motion: no-preference) {
    :where(.group\/roll:focus-visible) & { translate: 0 0; opacity: 1; transition-duration: 450ms, 260ms; transition-delay: calc(var(--i) * 14ms), calc(var(--i) * 14ms + 90ms); }
    @media (hover: hover) {
      :where(.group\/roll:hover) & { translate: 0 0; opacity: 1; transition-duration: 450ms, 260ms; transition-delay: calc(var(--i) * 14ms), calc(var(--i) * 14ms + 90ms); }
    }
  }
}
```

Digit roll (an index "02 / 04" following scroll) — here a 1.2 em clip is acceptable because the
whole digit is replaced in one step:

```tsx
<span className="relative inline-flex h-[1.2em] overflow-hidden tabular-nums">
  <AnimatePresence mode="popLayout" initial={false}>
    <m.span key={index} initial={{ y: "100%" }} animate={{ y: "0%" }} exit={{ y: "-100%" }} transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}>
      {index}
    </m.span>
  </AnimatePresence>
</span>
```

Word morph (only the differing tail re-types, e.g. a word in two languages):

```tsx
const tail: Variants = { hidden: {}, shown: { transition: { staggerChildren: 0.03 } }, exit: { transition: { staggerChildren: 0.015, staggerDirection: -1 } } };
const letter: Variants = {
  hidden: { opacity: 0, y: "0.3em", filter: "blur(4px)" },
  shown: { opacity: 1, y: 0, filter: "blur(0px)", transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
  exit: { opacity: 0, y: "-0.2em", filter: "blur(4px)", transition: { duration: 0.15 } },
};
export function MorphWord({ word, shared }: { word: string; shared: number /* common prefix length */ }) {
  const rest = word.slice(shared);
  return (
    <>
      {word.slice(0, shared)}
      <AnimatePresence mode="wait" initial={false}>
        <m.span key={rest} className="inline-flex" variants={tail} initial="hidden" animate="shown" exit="exit">
          {Array.from(rest, (c, i) => <m.span key={i} className="inline-block" variants={letter}>{c}</m.span>)}
        </m.span>
      </AnimatePresence>
    </>
  );
}
```

Streamed tokens (each word once, never the whole reply again):

```css
@keyframes token-in {
  from { opacity: 0; filter: blur(6px); translate: 0 0.25em; }
  40% { opacity: 1; }
}
@utility token { display: inline-block; animation: token-in 600ms var(--ease-out) both;
  @media (prefers-reduced-motion: reduce) { animation: arrive-fade var(--fade-in) ease-out both; } }
```

Page-load heading word by word (CSS from server HTML; WordsReveal):
`<span className="inline-block motion-safe:animate-enter" style={{ "--delay": `${delay + i * 0.06}s` }}>`
with `--animate-enter: enter 0.7s cubic-bezier(0.22,1,0.36,1) var(--delay,0s) both` in `@theme inline`.

**Pitfalls:** tight tracking pushed the last glyph past its box → clipped background text lost ~3 px
(give room via padding/negative margin); `tabular-nums` only on numbers (it widened a hyphen in names);
never move/settle text that has `background-clip: text` (it "bugged around" without its gradient).


---

## P11. Scroll reveal (one-shot arrival as it scrolls into view)

**When:** objects (panels, cards, images, footer) below the fold. Not text in the flow; not every
section.

```tsx
"use client";
import { animate, inView } from "motion/react";
import { type ReactNode, useEffect, useRef } from "react";

const HIDDEN = { opacity: 0, y: 32, filter: "blur(8px)" };
const FADE = { duration: 0.7, ease: [0.2, 0, 0, 1] as const };
const MOVE = { type: "spring" as const, stiffness: 120, damping: 18 };

/**
 * Server HTML shows it as is; only what is still below the fold once interactive is held back.
 * Without JS, with reduced motion and on paper it's simply there.
 */
export function Reveal({ children, delay = 0, className }: { children: ReactNode; delay?: number; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    if (el.getBoundingClientRect().top < window.innerHeight) return; // already seen: never hide it
    animate(el, HIDDEN, { duration: 0 });
    const stop = inView(
      el,
      () => {
        animate(el, { opacity: 1, filter: "blur(0px)" }, { ...FADE, delay });
        animate(el, { y: 0 }, { ...MOVE, delay });
        stop(); // once
      },
      { margin: "0px 0px -12% 0px" }, // when a little of it shows, not its first pixel
    );
    return stop;
  }, [delay]);
  return <div ref={ref} data-reveal className={className}>{children}</div>;
}
```

Image wipe variant: observe the outer box, clip an inner one (a fully clipped element never
reports being in view); `clip-path: inset(100% 0 0 0)` → `inset(0)` over 0.8 s in-out while the image
settles from scale 1.12 over 1.2 s.

"Play when the visitor is on it" (showcases, sequences): start when the element stands in the upper
three quarters of the screen (or after ~1 s if the screen shows it whole), not at first visibility
(the user missed half the animation when it started at 30% visible). Hold its CSS animations
paused at their start until then (`[data-showcase]:not([data-playing]) * { animation-play-state: paused }`).

**Pitfalls:** a page reached from far down another must reset to its top before measuring what's
"below the fold"; a reveal on the wrapper while hover scales the card inside (two layers);
one observer per reveal, disconnected after firing; stagger neighbours a beat apart (70–110 ms).


---

## P12. Scroll-linked progress, parallax and sticky stages

**When:** marketing-site sections where position means something (a line drawing down a process,
words brightening as read, a hero receding, stacked cards).

CSS scroll timelines (preferred: off the main thread, reversible, no JS):

```css
/* Every effect: behind @supports, motion welcome, on screen only (on paper a timeline sits at its
   start). Without support the page shows the end state. */
@utility scroll-recede {
  @supports (animation-timeline: view()) {
    @media screen and (prefers-reduced-motion: no-preference) {
      animation: recede linear both;
      animation-timeline: view(block 0px); /* whole screen: view() is inset by scroll-padding */
      animation-range: exit 0% exit 85%;
      :root:active-view-transition & { animation: none; } /* misplaced during page changes */
    }
  }
}
@keyframes recede { to { opacity: 0; scale: 0.94; translate: 0 12%; } }

/* A line growing over its stretch of a named timeline, and markers popping as it reaches them. */
@utility scroll-grow {
  @supports (animation-timeline: view()) {
    @media screen and (prefers-reduced-motion: no-preference) {
      animation: grow linear both;
      animation-timeline: var(--timeline);
      animation-range: var(--range);
    }
  }
}
@keyframes grow { from { scale: var(--grow-from, 1 0); } }
@utility scroll-pop {
  @supports (animation-timeline: view()) {
    @media screen and (prefers-reduced-motion: no-preference) {
      animation: pop-scale var(--ease-spring-in) both; /* a spring curve as a scrubbed easing */
      animation-timeline: var(--timeline);
      animation-range: var(--range);
    }
  }
}
@keyframes pop-scale { from { scale: 0; } }

/* Ink brightening while read: each word over its own stretch. */
@keyframes ink { from { color: var(--color-muted); } }

/* A stage the page scrolls through while its content sticks; collapses where it can't play. */
@utility scroll-stage {
  @supports (animation-timeline: view()) {
    @media screen and (prefers-reduced-motion: no-preference) { height: 220svh; }
  }
}
```

```tsx
// The timeline owner names it; children read it (a sticky child's own view() stands still).
<section style={{ viewTimelineName: "--process" } as React.CSSProperties} className="overflow-clip">
  <span className="scroll-grow" style={{ "--timeline": "--process", "--range": "cover 10% cover 60%" } as React.CSSProperties} />
</section>
// Use `overflow: clip`, never `hidden`, on anything around a scroll-linked effect: `hidden` makes a
// scroll container that captures the timeline (effects never ran on phones). Elements outside the
// owner need `timeline-scope` on a common ancestor.
```

Motion-driven parallax (client-site template; reduced motion stands still, SSR-safe):

```tsx
"use client";
import { useEffect, useRef, type ReactNode } from "react";
import { useMotionValue, useReducedMotion, useScroll, useTransform } from "motion/react";
import * as m from "motion/react-m";

/** 1 normally, 0 with reduced motion, switched after mount so SSR and first render match. */
function useMotionStrength() {
  const reduced = useReducedMotion();
  const strength = useMotionValue(1);
  useEffect(() => strength.set(reduced ? 0 : 1), [reduced, strength]);
  return strength;
}

export function Parallax({ children, depth = 40, className }: { children: ReactNode; depth?: number; className?: string }) {
  const ref = useRef<HTMLDivElement>(null); // measure the static wrapper, move only the inner layer
  const strength = useMotionStrength();
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });
  const y = useTransform([scrollYProgress, strength], ([p, s]: number[]) => (1 - 2 * p) * depth * s);
  return (
    <div ref={ref} className={className}>
      <m.div style={{ y }}>{children}</m.div>
    </div>
  );
}
```

Other scroll pieces seen: a header bob answering scroll **velocity** (≤5 px, spring 260/13, passive
listener only pushes the spring; a jump pushes nothing); a reading-progress light along the header's
edge (CSS `scroll()` timeline); scroll strips whose edges fade (mask-image driven by
`data-more-before/after` from a ResizeObserver + scroll listener); a sticky photo frame where each
item crossing the middle band (`useInView` margin `-45% 0px -45% 0px`) cuts in its photo via an
animated `clip-path` polygon; pull-to-refresh with `useTransform` from the pull distance.

**Pitfalls:** a scroll effect needs a stretch of scroll to play on — something only reachable in the
last few px (a footer on a phone) plays in its own time on `inView` instead; scroll position never in
React state; no scroll-jacking or smooth-scroll libraries; two textures must never meet in one
gradient while scrolling (keep them apart in space or time).


---

## P13. Hover and press feedback

**When:** every control and clickable row.

Press (keycap model):

```tsx
"use client";
import * as m from "motion/react-m";
import { type ComponentProps, type KeyboardEvent, type PointerEvent, useEffect, useState } from "react";
import { PRESS_TRANSITION, RELEASE_TRANSITION } from "@/lib/motion";

/** Pressed from pointerdown/Enter until the release, wherever it happens. Spread on the pressed element. */
export function usePress() {
  const [pressed, setPressed] = useState(false);
  useEffect(() => {
    if (!pressed) return;
    const release = () => setPressed(false);
    const events = ["pointerup", "pointercancel", "keyup", "blur"] as const;
    for (const t of events) window.addEventListener(t, release);
    return () => { for (const t of events) window.removeEventListener(t, release); };
  }, [pressed]);
  return {
    pressed,
    pressProps: {
      onPointerDown: (e: PointerEvent) => { if (e.button === 0) setPressed(true); },
      onKeyDown: (e: KeyboardEvent) => { if (e.key === "Enter") setPressed(true); },
    },
  };
}

/** The content (icon + label) sinks; the surface stays. Rows: origin-left; wide rows use 0.99. */
export function PressScale({ pressed, scale = 0.96, ...props }: ComponentProps<typeof m.span> & { pressed: boolean; scale?: number }) {
  return (
    <m.span
      className="inline-flex items-center gap-2"
      initial={false}
      animate={{ scale: pressed ? scale : 1 }}
      transition={pressed ? PRESS_TRANSITION : RELEASE_TRANSITION}
      {...props}
    />
  );
}
```

Jelly on a control (site, or dashboard at a third of the amplitude): width and height on two
springs by giving `scale` (x) and `transform: scaleY` separate transitions:

```css
@utility jelly-control {
  -webkit-tap-highlight-color: transparent;
  transition:
    box-shadow 240ms var(--ease-out),
    filter 240ms var(--ease-out),
    scale var(--spring-in-duration) var(--spring-in),          /* width */
    transform var(--spring-lift-duration) var(--spring-lift);  /* height */
  @media (prefers-reduced-motion: no-preference) {
    @media (hover: hover) {
      &:hover { scale: var(--control-hover, 1.025) 1; transform: scaleY(var(--control-hover, 1.025)); }
    }
    &:active, &[data-pressed] {
      scale: var(--control-press-x, 0.97) 1;
      transform: scaleY(var(--control-press-y, 0.93));
    }
  }
  &:active, &[data-pressed] { transition-duration: 110ms, 110ms, 110ms, 110ms; transition-timing-function: var(--ease-out); }
}
```

Links and arrows:

```css
/* Underline draws from the left. */
@utility link-underline {
  background-image: linear-gradient(currentColor, currentColor);
  background-position: 0 100%;
  background-repeat: no-repeat;
  background-size: 0% 1px;
  transition: background-size 200ms var(--ease-out);
  &:hover, &:focus-visible { background-size: 100% 1px; }
}
/* An arrow passes through: the shown one slides on and fades quickly, its twin slides in from behind
   and fades up a moment later — no clipping box. `--pass` (0→1) is set on the link while hovered/focused. */
@utility pass-out {
  opacity: calc(1 - var(--pass, 0));
  transition-property: translate, opacity;
  transition-timing-function: var(--ease-lift), var(--ease-fade);
  transition-duration: 500ms, calc(260ms - var(--pass, 0) * 100ms);
  transition-delay: 0ms, calc((1 - var(--pass, 0)) * 90ms);
}
@utility pass-in {
  opacity: var(--pass, 0);
  transition-property: translate, opacity;
  transition-timing-function: var(--ease-lift), var(--ease-fade);
  transition-duration: 500ms, calc(160ms + var(--pass, 0) * 100ms);
  transition-delay: 0ms, calc(var(--pass, 0) * 90ms);
}
```

```tsx
import { ArrowRight } from "lucide-react";
/** On the link/button: `--pass` is 1 while pointed at or focused (any parent can set it). */
export const PASSES = "hover:[--pass:1] focus-visible:[--pass:1]";
/** Two arrows in one grid cell: the shown one leaves the way it points (60% of its size), its twin
 *  comes in from behind. `--pass` needn't be registered: translate/opacity are what transition. */
export function PassArrow({ className = "" }: { className?: string }) {
  const arrow = "[grid-area:1/1] size-full motion-reduce:translate-none";
  return (
    <span aria-hidden className={`inline-grid shrink-0 ${className}`}>
      <ArrowRight className={`${arrow} pass-out translate-x-[calc(var(--pass,0)*60%)]`} />
      <ArrowRight className={`${arrow} pass-in translate-x-[calc((var(--pass,0)_-_1)*60%)]`} />
    </span>
  );
}
// <a href="/contact" className={`group/roll inline-flex items-center gap-2 ${PASSES}`}><RollText text="Contact" /><PassArrow className="size-4" /></a>
```

Icons in motion (app): one document-level listener marks icons `data-icon-play` on pointerover from
outside the control, pointerdown, or focus-visible; removes it on `animationend` (fallback 1.2 s);
skips rows/options/checkboxes/disabled and invisible icons; starts after load + 2 rAFs (a mark on a
hydrating part would mismatch the server's HTML). CSS per Lucide class:

```css
@keyframes icon-clock { to { --icon-clock: 1; } } /* each playing icon times itself */
@keyframes icon-turn { to { rotate: 90deg; } }
@media (prefers-reduced-motion: no-preference) {
  .lucide[data-icon-play] { overflow: visible; }
  /* The plus turns a quarter on LIFT, a little past and back; ends looking as it began. */
  .lucide-plus[data-icon-play] { animation: icon-turn var(--spring-lift-duration) var(--spring-lift); }
  /* A stroke picked by place (unit-test that the icon library still draws it there). */
  .lucide-trash[data-icon-play] { animation: icon-clock 560ms; }
  .lucide-trash[data-icon-play] path:nth-child(4),
  .lucide-trash[data-icon-play] path:nth-child(5) { transform-box: view-box; transform-origin: 3px 6px; animation: icon-lid 560ms; }
}
@keyframes icon-lid { 35% { translate: 0 -2.5px; rotate: -14deg; } 70% { translate: 0 0.3px; rotate: 2deg; } }
```

```tsx
"use client";
import { useEffect } from "react";
const MOVING_ICON = ["plus", "trash", "check", "pencil", "x"].map((n) => `svg.lucide-${n}`).join(", ");
const CONTROL = 'button, a[data-slot="button"], [role="button"], [role="menuitem"], [role="tab"]';
const STILL = '[role="option"], [role="checkbox"], [role="radio"], [role="switch"], :disabled, [aria-disabled="true"], [data-disabled]';

export function IconMotion() {
  useEffect(() => {
    const reduced = matchMedia("(prefers-reduced-motion: reduce)");
    const timers = new WeakMap<Element, number>();
    const end = (icon: Element) => { icon.removeAttribute("data-icon-play"); clearTimeout(timers.get(icon)); };
    const controlOf = (t: EventTarget | null) => {
      const c = t instanceof Element ? t.closest(CONTROL) : null;
      return c && !c.matches(STILL) ? c : null;
    };
    const play = (control: Element) => {
      if (reduced.matches) return;
      for (const icon of control.querySelectorAll(MOVING_ICON)) {
        if (icon.hasAttribute("data-icon-play") || icon.closest(CONTROL) !== control) continue;
        if (!icon.checkVisibility({ opacityProperty: true, visibilityProperty: true })) continue;
        icon.setAttribute("data-icon-play", "");
        timers.set(icon, window.setTimeout(() => end(icon), 1200));
      }
    };
    const over = (e: PointerEvent) => {
      const c = controlOf(e.target);
      if (c && !(e.relatedTarget instanceof Node && c.contains(e.relatedTarget))) play(c);
    };
    const down = (e: PointerEvent) => { const c = controlOf(e.target); if (c) play(c); };
    const focus = (e: FocusEvent) => { const c = controlOf(e.target); if (c?.matches(":focus-visible")) play(c); };
    const done = (e: AnimationEvent) => { if (e.target instanceof Element && e.target.hasAttribute("data-icon-play")) end(e.target); };
    let raf = 0;
    const start = () => (raf = requestAnimationFrame(() => (raf = requestAnimationFrame(() => {
      document.addEventListener("pointerover", over, { passive: true });
      document.addEventListener("pointerdown", down, { passive: true });
      document.addEventListener("focusin", focus);
      document.addEventListener("animationend", done);
      document.addEventListener("animationcancel", done);
    }))));
    if (document.readyState === "complete") start(); else addEventListener("load", start, { once: true });
    return () => {
      removeEventListener("load", start);
      cancelAnimationFrame(raf);
      document.removeEventListener("pointerover", over);
      document.removeEventListener("pointerdown", down);
      document.removeEventListener("focusin", focus);
      document.removeEventListener("animationend", done);
      document.removeEventListener("animationcancel", done);
    };
  }, []);
  return null;
}
```

**Pitfalls/fixes:** `whileTap` gives a non-focusable ancestor `tabIndex=0` and only reaches one
element — use `usePress` on the pressed element; a stock `transition-all` on a button fights Motion
every frame (give the shadow its own `m.span` layer); a click target inside sinking content shrinks
and the release lands outside → extend its `::after` past the row; `-webkit-tap-highlight-color:
transparent` on anything with its own press; hover in custom CSS behind `@media (hover: hover)`;
only the element under the pointer answers (no neighbour glow on a dashboard); a hover light written
into custom properties on enter/move, nothing re-renders. Mark `cursor: pointer` on everything
clickable.


---

## P14. Dialogs, sheets, menus, popovers, flyouts

**When:** any overlay.

Base UI (shadcn-style) marks first/last frames with `data-starting-style` / `data-ending-style` and
waits for CSS transitions before unmounting. Add `@starting-style` for overlays mounted already open.

```css
/* Menus, tooltips, popovers: grow out of the trigger (origin from Base UI's --transform-origin). */
@utility overlay-appear {
  transition:
    opacity var(--fade-in) ease-out,
    scale var(--spring-in-duration) var(--spring-in),
    translate var(--spring-in-duration) var(--spring-in);
  &[data-starting-style] { opacity: 0; scale: 0.95; translate: var(--appear-x, 0) var(--appear-y, -0.25rem); }
  @starting-style { opacity: 0; scale: 0.95; translate: var(--appear-x, 0) var(--appear-y, -0.25rem); }
  &[data-ending-style] {
    opacity: 0; scale: 0.97; translate: var(--appear-x, 0) var(--appear-y, -0.1875rem);
    transition:
      opacity var(--fade-out) ease-out,
      scale var(--spring-reorder-duration) var(--spring-reorder),
      translate var(--spring-reorder-duration) var(--spring-reorder);
  }
  &[data-side="top"] { --appear-y: 0.25rem; }
  &[data-side="right"] { --appear-x: -0.25rem; --appear-y: 0; }
  &[data-side="left"] { --appear-x: 0.25rem; --appear-y: 0; }
  @media (prefers-reduced-motion: reduce) {
    &[data-starting-style], &[data-ending-style] { scale: 1; translate: 0 0; }
    @starting-style { scale: 1; translate: 0 0; }
  }
}

/* A dialog lands: rises 16px on LIFT, grows from 0.92 on SPRING_IN; leaves quicker, no bounce. */
@utility dialog-in {
  transition:
    opacity var(--fade-in) ease-out,
    scale var(--spring-in-duration) var(--spring-in),
    translate var(--spring-lift-duration) var(--spring-lift);
  &[data-starting-style] { opacity: 0; scale: 0.92; translate: 0 1rem; }
  @starting-style { opacity: 0; scale: 0.92; translate: 0 1rem; }
  &[data-ending-style] {
    opacity: 0; scale: 0.96; translate: 0 0.5rem;
    transition:
      opacity var(--fade-out) ease-out,
      scale var(--spring-reorder-duration) var(--spring-reorder),
      translate var(--spring-reorder-duration) var(--spring-reorder);
  }
  @media (prefers-reduced-motion: reduce) {
    &[data-starting-style], &[data-ending-style] { scale: none; translate: none; }
    @starting-style { scale: none; translate: none; }
  }
}

/* A sheet slides 24px from its edge on SPRING_IN (a short way: a bounce over its whole width would
   swing far past), grows from 0.98 at that edge on LIFT; leaves back toward its edge, no bounce. */
@utility sheet-in {
  transform-origin: var(--sheet-origin, left center);
  transition:
    opacity var(--fade-in) ease-out,
    translate var(--spring-in-duration) var(--spring-in),
    scale var(--spring-lift-duration) var(--spring-lift);
  &[data-starting-style] { opacity: 0; translate: var(--sheet-from, -1.5rem 0); scale: 0.98; }
  @starting-style { opacity: 0; translate: var(--sheet-from, -1.5rem 0); scale: 0.98; }
  &[data-ending-style] {
    opacity: 0; translate: var(--sheet-to, -1rem 0); scale: 0.98;
    transition:
      opacity var(--fade-out) ease-out,
      translate var(--spring-reorder-duration) var(--spring-reorder),
      scale var(--spring-reorder-duration) var(--spring-reorder);
  }
  &[data-side="right"] { --sheet-from: 1.5rem 0; --sheet-to: 1rem 0; --sheet-origin: right center; }
  &[data-side="bottom"] { --sheet-from: 0 1.5rem; --sheet-to: 0 1rem; --sheet-origin: center bottom; }
  &[data-side="top"] { --sheet-from: 0 -1.5rem; --sheet-to: 0 -1rem; --sheet-origin: center top; }
  @media (prefers-reduced-motion: reduce) {
    &[data-starting-style], &[data-ending-style] { translate: none; scale: none; }
    @starting-style { translate: none; scale: none; }
  }
}

/* The page behind dims (no blur on moving content; a 2px static depth-of-field blur was OK). */
@utility dim {
  transition: opacity var(--fade-in) ease-out;
  &[data-starting-style], &[data-ending-style] { opacity: 0; }
  @starting-style { opacity: 0; }
  &[data-ending-style] { transition-duration: var(--fade-out); }
}
```

```tsx
// Dialog primitive: centred by margins (m-auto), not a translate the landing animates.
<DialogPrimitive.Portal>
  <DialogPrimitive.Backdrop forceRender className="fixed inset-0 z-50 bg-black/60 dim" />
  <DialogPrimitive.Popup className="fixed inset-0 z-50 m-auto h-fit w-[calc(100%-2rem)] max-w-md dialog-in rounded-lg p-5">
    {children /* body wrapped in <AnimateDimensions> so errors/steps ease its height */}
  </DialogPrimitive.Popup>
</DialogPrimitive.Portal>

// A dialog that asks something: mounted once, reset only after it has closed.
<AlertDialog
  open={open}
  onOpenChange={setOpen}
  onOpenChangeComplete={(isOpen) => { if (!isOpen) { setError(null); form.reset(); } }}
>
```

Without Base UI (site header flyout / language popover), toggle `data-open` and keep it mounted:

```css
@utility popover-panel {             /* small: grows out of its button as one piece */
  visibility: hidden; opacity: 0; scale: 0.96;
  transition: opacity 120ms var(--ease-fade), scale 160ms var(--ease-fade), visibility 0s 160ms;
  &[data-open] { visibility: visible; opacity: 1; scale: none; transition: opacity 160ms var(--ease-fade), scale 240ms var(--ease-fade), visibility 0s; }
  @media (prefers-reduced-motion: reduce) { scale: none; }
}
@utility flyout-panel {              /* large: settles, never scales */
  visibility: hidden; opacity: 0; translate: 0 -0.375rem;
  transition: opacity 180ms var(--ease-fade), translate 240ms var(--ease-fade), visibility 0s 180ms;
  &[data-open] { visibility: visible; opacity: 1; translate: none; transition: opacity 260ms var(--ease-fade), translate 560ms var(--ease-fade), visibility 0s; }
  @media (prefers-reduced-motion: reduce) { translate: none; }
}
@utility flyout-row {                /* rows arrive top to bottom, leave all at once */
  --wait: calc(40ms + var(--row, 0) * 28ms);
  opacity: 0; translate: 0 -0.25rem; filter: blur(3px);
  transition: opacity 140ms var(--ease-fade), translate 140ms var(--ease-fade), filter 140ms var(--ease-fade);
  [data-open] & {
    opacity: 1; translate: none; filter: none;
    transition: opacity 360ms var(--ease-fade) var(--wait), translate 560ms var(--ease-fade) var(--wait), filter 360ms var(--ease-fade) var(--wait);
  }
  @media (prefers-reduced-motion: reduce) { translate: none; filter: none; }
}
```

Older Motion-driven alternative (first dashboard app): `AnimatePresence` around the popup, Base UI's
`actionsRef` + `eventDetails.preventUnmountOnClose()`, `onExitComplete={() => actionsRef.current?.unmount()}`,
`transformOrigin: var(--transform-origin)`; a controlled close turned into `actionsRef.current.close()`
from an effect (else it unmounts before Motion's first frame).

**Pitfalls:** an overlay rebuilt (remounted) on each opening popped in with no animation; overlays
must stay mounted; a guard e2e test opens a dialog twice and polls `getAnimations()` for a running
`scale`/`translate` transition; Escape inside a nested list closes only the list; a hover-open menu
needs a pointer bridge strip over the gap so moving down doesn't close it; what covers the page makes
the page `inert`; a dialog opened from a sheet dims the sheet too (`forceRender` backdrop); widen a
right sheet with `data-[side=right]:sm:max-w-lg`.


---

## P15. Toasts

No custom toast motion exists in the repos: the first dashboard app uses `sonner` with its defaults; the newest dashboard app, the
websites and the template have no toasts. The only lesson: never remove a toast library's DOM nodes
in tests (React owns them). Apply the general rules if building one: enter on LIFT (rise + fade),
exit as a fast tween, stacked toasts reflow on `ITEM_REORDER`, a status change inside one goes through
`ContentSwap`. See OPEN.


---

## P16. Progress in beats, drawn checks, arrival choreography

**When:** completion moments (signed in, step done, document accepted), steppers, first load.


```tsx
// A check that draws itself once, short arm to long, after its marker lights.
<svg viewBox="0 0 24 24" fill="none" className="size-5">
  <m.path
    d="M5 12.5l4.5 4.5L19 7.5"
    stroke="currentColor"
    strokeWidth={2.5}
    strokeLinecap="round"
    strokeLinejoin="round"
    initial={{ pathLength: 0 }}
    animate={{ pathLength: 1 }}
    transition={{ duration: 0.35, ease: "easeOut", delay: 0.2 }}
  />
</svg>
```
```css
/* A marker taking the light: gives a little and springs past its size, once, after --arrive-delay. */
@keyframes marker-give { 35% { scale: 0.9; } 65% { scale: 1.045; } 85% { scale: 0.995; } }
@utility animate-light {
  animation: marker-light 300ms var(--ease-out) backwards, marker-give 650ms ease-out;
  animation-delay: var(--arrive-delay, 0ms);
  @media (prefers-reduced-motion: reduce) { animation: marker-light 300ms var(--ease-out) backwards; animation-delay: var(--arrive-delay, 0ms); }
}
/* One ring leaving it, for something reached. */
@keyframes marker-ripple { from { opacity: 0.7; scale: 1; } to { opacity: 0; scale: 1.7; } }
```

Choreography rules: first-load parts in order (mark → card as a fade only → heading → content →
footer), 40–70 ms apart, at most 5 parts on a dashboard, stop staggering past 8 rows. A stepper runs
in 160 ms beats: a finished step fills from its middle (spring without overshoot — a fill past full
reads as a glitch), its check pops, the line fills, the current step lights and ripples once; on load
start after the part has risen; on change start right away. A step swap scrolls back to the top with
the height ease. A goal reached in view replays its moment by keying on a counter of reachings
(`useReached`). What's already done on load is simply there.


---

## P17. Ambient / continuous motion (only where asked)

**When:** AI surfaces' light, an ambient frame or aurora, a "fire" on a gamified progress card.

```css
/* Tongues rising from an edge: steady linear loops that never reverse, out of step, fading out
   before each restart; transform + opacity only. */
@keyframes lick {
  0% { opacity: 0; translate: 0 20%; scale: 0.8 0.6; }
  20% { opacity: 1; }
  80% { opacity: 0.8; }
  100% { opacity: 0; translate: 0 -60%; scale: 1 1.2; }
}
.tongue {
  will-change: transform, opacity;
  animation: lick 1.6s linear infinite;
}
.tongue:nth-child(2) { animation-duration: 1.9s; animation-delay: -0.7s; }
.tongue:nth-child(3) { animation-duration: 1.3s; animation-delay: -1.1s; }
@media (prefers-reduced-motion: reduce) { .tongue { animation: none; opacity: 0.6; } }
```

JS: never chain (`onComplete` → next or `await` → next) — each seam clamps at its end and drops a
frame; one `animate()` whose `ease` is the speed profile (spin-up into a steady spin). Shadows and
gradients inside a rotated element rotate with it: cast the shade from a non-rotating parent. Measure
with a per-frame rAF trace, not by eye. Draw WebGL/canvas loops only while on screen (paused in a
hidden tab, ≤30–60 fps), still with reduced motion. Make an ambient motion visible enough (1.5% over
6 s was "too faint") and hand over the numbers to tune down. Check the space the effect spills into at
each width (never over buttons or a neighbour).

Large and slow is the risky combination. A full-viewport background that sways back and forth, or a
whole-page breathing scale, with a cycle of roughly 3–10 s sits in the band (around 0.2 Hz) most tied
to motion sickness. That figure comes from research on vehicle motion; Apple's design guidance carries
it over to screens, and it has not come up in the user's projects. The loops above already flow one
way and never reverse. Keep any back-and-forth loop to a part of the page, never the whole viewport;
reduced motion stops it anyway (P18).


---

## P18. Reduced motion (summary across patterns)

| Moment | Full | Reduced |
|---|---|---|
| Arrival / page turn / tab | fade + rise/slide | fades only (shift tokens 0) |
| Title morph | travels | instant swap (group duration 0) |
| Reveal / scroll effects | lands / scrubs | simply there / end state |
| Press, jelly, pops, icon motion | moves | colour/shadow change only; nothing marked |
| Sliding mark | slides | jumps (Motion layout off) |
| Height (Collapse) | eases | instant |
| Loops, WebGL | flow | one still frame |
| Sequences | play | finished state; "play again" not offered |

Implement with: `MotionConfig reducedMotion="user"` (once), CSS tokens zeroed under
`prefers-reduced-motion: reduce`, `@media (prefers-reduced-motion: no-preference)` around decorative
CSS, `useReducedMotion()` only to choose transitions/values (never to render different elements),
`useMotionStrength()` for scroll-linked values. Test both: Playwright `reducedMotion: "reduce"` as the
suite default and `"no-preference"` in motion specs; a site checker renders every page both ways.

Two more settings touch the surfaces motion runs on. Any translucent surface (a sticky header or app
bar with `backdrop-filter`, a blurred dim behind a dialog) keeps its own values and gets these
overrides beside them:

```css
.translucent {
  /* Less transparency: solid, no blur. Where a browser doesn't support the query, it never matches. */
  @media (prefers-reduced-transparency: reduce) {
    background-color: var(--background);
    backdrop-filter: none;
  }
  /* More contrast: solid too, and a hairline edge (if it has one) at full strength. */
  @media (prefers-contrast: more) {
    background-color: var(--background);
    backdrop-filter: none;
    border-color: currentColor;
  }
}
```


---

## P19. Drag, swipe and snap (sheets, drawers, carousels)

**When:** something the user drags and lets go of: a bottom sheet swiped down to close, a drawer
pulled between half and full height, a carousel flicked to the next slide. For a free drag that just
returns or drops (a board card), Motion's own `drag` is enough (P5).

**Status:** new on 2026-11-09, and not yet tuned by the user. The mechanics are Apple's published
fluid-interface rules (see the README); the springs are ours. Treat the slop, deceleration rate and
dismiss point as starting values and put them on the lab page before settling them.

What a drag must do:

- **Follow 1:1** under the pointer, from where it was grabbed, with pointer capture so it keeps
  tracking off the handle.
- **Catch mid-flight.** Touching a panel that is still settling stops it where it is on screen and
  drags on from there, never from its target. Input is never locked during a transition.
- **Wait 10 px before moving** (the slop), so a press isn't a drag, then count from that point so
  crossing it doesn't jump the panel.
- **Resist past its ends progressively** (rubber-banding): almost 1:1 at first, less the further it
  goes. A hard stop reads as frozen.
- **On release, keep the pointer's speed.** The spring starts at the release velocity, so there's no
  seam between dragging and animating. Measure that velocity over the last ~100 ms of samples: one
  jittery `pointermove` must not decide it, and a pointer that rested before letting go has none.
- **Snap to where the flick is going**, not to the nearest point from where it was let go: project
  the resting point first, then pick the snap point nearest that.
- **Land on our springs.** Snaps settle on `SETTLE` (≈5%): a release often travels hundreds of pixels,
  and `LIFT`'s 10% would swing far past (principle 4). A dismiss leaves on `ITEM_REORDER`, without
  bounce: bouncy in, clean out.

```ts
// src/lib/gesture.ts — pure, unit-tested.

/**
 * How far a flick travels before it comes to rest, from its velocity in px/s. Exponential decay, as
 * iOS scroll views decelerate (the form in Apple's "Designing Fluid Interfaces" sample code, not the
 * textbook v²/2a). `rate` is the speed kept per millisecond: 0.998 normal, 0.99 stops quickly.
 */
export function project(velocity: number, rate = 0.998) {
  return ((velocity / 1000) * rate) / (1 - rate);
}

/** Past an edge: follows almost 1:1 at first, then less and less, and never more than `dimension`. */
export function rubberband(overshoot: number, dimension: number, constant = 0.55) {
  return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot));
}

/** `value` kept inside [min, max], with the part outside rubber-banded. */
export function resist(value: number, min: number, max: number, dimension: number) {
  if (value < min) return min + rubberband(value - min, dimension);
  if (value > max) return max + rubberband(value - max, dimension);
  return value;
}

/** The point nearest to `to`. */
export function nearest(points: readonly number[], to: number) {
  return points.reduce((best, p) => (Math.abs(p - to) < Math.abs(best - to) ? p : best));
}

/** A pointer that hasn't moved for this long before letting go was holding still. */
const AT_REST_MS = 50;

/** Velocity in px/s over the last `windowMs` of samples (timestamps in ms, from the events). */
export function createVelocityTracker(windowMs = 100) {
  let samples: { t: number; value: number }[] = [];
  return {
    reset() {
      samples = [];
    },
    add(t: number, value: number) {
      samples.push({ t, value });
      while (samples.length > 2 && t - samples[0].t > windowMs) samples.shift();
    },
    velocity(now: number) {
      const first = samples[0];
      const last = samples.at(-1);
      if (!first || !last || last.t === first.t || now - last.t > AT_REST_MS) return 0;
      return ((last.value - first.value) / (last.t - first.t)) * 1000;
    },
  };
}
```

```tsx
// src/hooks/use-drag-to-snap.ts
"use client";
import { animate, useMotionValue, useReducedMotion } from "motion/react";
import { type PointerEvent, useRef } from "react";
import { createVelocityTracker, nearest, project, resist } from "@/lib/gesture";
import { ITEM_REORDER, SETTLE } from "@/lib/motion";

type Options = {
  axis?: "x" | "y";
  /** Resting offsets in px along the axis. 0 is where the panel rests when open (or the first slide). */
  snaps: readonly number[];
  /** The panel's size along the axis, read when a gesture starts: the rubber-band scale and the dismiss distance. */
  size: () => number;
  /** Called once a dismissing flick has carried the panel out (toward positive offsets). Omit if it can't be dismissed. */
  onDismiss?: () => void;
};

/** Below this, a press is still a press and the panel doesn't move. */
const SLOP = 10;

/**
 * Drag a panel between snap points: 1:1 under the pointer, caught mid-flight, resisting past its ends,
 * and on release it keeps the pointer's speed toward the point the flick projects to. Spread
 * `handleProps` on the handle (which needs `touch-action: none`) and put `offset` on the panel's own
 * motion layer: `style={{ y: offset }}`.
 */
export function useDragToSnap({ axis = "y", snaps, size, onDismiss }: Options) {
  const offset = useMotionValue(0);
  const reduced = useReducedMotion();
  const tracker = useRef(createVelocityTracker());
  const gesture = useRef<{ id: number; start: number; from: number; size: number; dragging: boolean } | null>(null);
  const along = (e: PointerEvent) => (axis === "y" ? e.clientY : e.clientX);

  const onPointerDown = (e: PointerEvent<HTMLElement>) => {
    if (e.button !== 0 || gesture.current) return;
    offset.stop(); // caught mid-flight: it stays where it is on screen
    e.currentTarget.setPointerCapture(e.pointerId);
    gesture.current = { id: e.pointerId, start: along(e), from: offset.get(), size: size(), dragging: false };
  };

  const onPointerMove = (e: PointerEvent<HTMLElement>) => {
    const g = gesture.current;
    if (!g || e.pointerId !== g.id) return;
    if (!g.dragging) {
      if (Math.abs(along(e) - g.start) < SLOP) return;
      g.dragging = true;
      g.start = along(e); // count from here, so crossing the slop doesn't jump the panel
      tracker.current.reset();
    }
    const min = Math.min(...snaps);
    const max = onDismiss ? g.size : Math.max(...snaps);
    const next = resist(g.from + along(e) - g.start, min, max, g.size);
    offset.set(next);
    tracker.current.add(e.timeStamp, next);
  };

  const onRelease = (e: PointerEvent<HTMLElement>) => {
    const g = gesture.current;
    if (!g || e.pointerId !== g.id) return;
    gesture.current = null;
    // A cancelled pointer (the browser took the gesture) and a tap carry no speed.
    const velocity = g.dragging && e.type === "pointerup" ? tracker.current.velocity(e.timeStamp) : 0;
    const dismissAt = onDismiss ? g.size : undefined;
    const target = nearest(dismissAt === undefined ? snaps : [...snaps, dismissAt], offset.get() + project(velocity));
    if (target === dismissAt) {
      animate(offset, target, { ...ITEM_REORDER, velocity, onComplete: onDismiss });
    } else {
      // A tap that caught it mid-flight lands here too, with no speed, and settles to the nearest point.
      animate(offset, target, { ...(reduced ? ITEM_REORDER : SETTLE), velocity });
    }
  };

  return {
    offset,
    /** Put the panel back without motion, once its overlay has finished closing. */
    reset: () => offset.jump(0),
    handleProps: { onPointerDown, onPointerMove, onPointerUp: onRelease, onPointerCancel: onRelease },
  };
}
```

A bottom sheet that swipes closed, on the mounted overlay from P14:

```tsx
"use client";
import { Dialog as DialogPrimitive } from "@base-ui/react/dialog";
import * as m from "motion/react-m";
import { type ReactNode, useRef } from "react";
import { useDragToSnap } from "@/hooks/use-drag-to-snap";

export function BottomSheet({ open, onOpenChange, children }: { open: boolean; onOpenChange: (open: boolean) => void; children: ReactNode }) {
  const panel = useRef<HTMLDivElement>(null);
  const { offset, reset, handleProps } = useDragToSnap({
    snaps: [0],
    size: () => panel.current?.offsetHeight ?? window.innerHeight,
    onDismiss: () => onOpenChange(false),
  });
  return (
    <DialogPrimitive.Root open={open} onOpenChange={onOpenChange} onOpenChangeComplete={(isOpen) => { if (!isOpen) reset(); }}>
      <DialogPrimitive.Portal>
        <DialogPrimitive.Backdrop forceRender className="fixed inset-0 z-50 bg-black/60 dim" />
        {/* The popup's CSS owns opening and closing (translate, scale, opacity); the drag owns the inner
            layer's transform. Never both on one element (principle 6). */}
        <DialogPrimitive.Popup data-side="bottom" className="fixed inset-x-0 bottom-0 z-50 sheet-in">
          <m.div ref={panel} style={{ y: offset }} className="rounded-t-2xl bg-background pb-[env(safe-area-inset-bottom)]">
            <div {...handleProps} aria-hidden className="flex h-7 cursor-grab touch-none items-center justify-center active:cursor-grabbing">
              <span className="h-1 w-10 rounded-full bg-muted-foreground/40" />
            </div>
            {children /* includes a close button: dragging is never the only way out */}
          </m.div>
        </DialogPrimitive.Popup>
      </DialogPrimitive.Portal>
    </DialogPrimitive.Root>
  );
}
```

A drawer with two heights uses `snaps: [0, half]` (offset 0 = full height, `half` = how far down
the half-open state sits). A carousel uses `axis: "x"`, `snaps` at `0, -w, -2w…` and no `onDismiss`.

```ts
// src/lib/gesture.test.ts
import { describe, expect, it } from "vitest";
import { createVelocityTracker, nearest, project, resist, rubberband } from "./gesture";

describe("gesture math", () => {
  it("projects a 1000 px/s flick about 500 px at the normal rate", () => {
    expect(project(1000)).toBeCloseTo(499, 0);
    expect(project(-1000)).toBeCloseTo(-499, 0);
  });
  it("rubber-bands progressively and never past the dimension", () => {
    expect(rubberband(10, 800)).toBeCloseTo(5.46, 1); // near the edge: about half
    expect(rubberband(100, 800)).toBeCloseTo(51.5, 1);
    expect(rubberband(1e6, 800)).toBeLessThan(800);
    expect(resist(50, 0, 100, 800)).toBe(50); // inside: untouched
  });
  it("snaps to the point nearest the projection, not the release point", () => {
    expect(nearest([0, 600], 200 + project(1000))).toBe(600);
    expect(nearest([0, 600], 200)).toBe(0);
  });
  it("reads no speed from a pointer that rested before letting go", () => {
    const v = createVelocityTracker();
    v.add(0, 0);
    v.add(16, 16);
    expect(v.velocity(16)).toBeCloseTo(1000, 0);
    expect(v.velocity(200)).toBe(0);
  });
});
```

**Pitfalls:**

- Without `touch-action: none` on the handle, the browser takes the touch for scrolling and sends
  `pointercancel` halfway; it only shows on a phone. For a vertical drag inside something that
  scrolls sideways, `touch-action: pan-x`.
- Start with a handle. Dragging the whole sheet means fighting its scrolling content: start the drag
  only when the content is scrolled to its top and the move is downward, otherwise let it scroll.
- A 2D throw (a floating panel to a corner) runs one offset per axis, each with its own velocity, as
  P5 does: one spring over the diagonal distance desyncs when the two speeds differ.
- Motion's own `drag` resists linearly past `dragConstraints` (`dragElastic`), and its momentum
  projects `power × velocity` (default 0.8, about 60% further than the 0.998 rate). That is fine for
  P5. For snap panels, use this hook. If you stay on Motion's `drag` anyway, use
  `dragTransition={{ power: 0.5, modifyTarget: snap }}` to come close.
- No haptics: the Vibration API doesn't exist in iOS Safari, and the user tests on an iPhone. Feedback
  for a snap stays visual.
- Reduced motion keeps the 1:1 drag (the user is moving it) and drops only the release overshoot.


---
