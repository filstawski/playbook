---
name: website-motion
description: >-
  Transitions, animations, morphs and scroll effects for React/Next.js apps
  and sites with the `motion` library and CSS: the rules, the shared spring
  tokens, a runnable pattern catalogue, and how to verify motion before
  reporting. Use whenever UI appears, disappears, resizes, swaps, moves
  between places, reacts to press/hover/scroll, or changes page.
metadata:
  type: practice
  category: frontend
---

## Rule

Motion explains a change. Nothing in the interface teleports: everything
that appears, disappears, resizes, swaps or moves gets there continuously,
on a shared vocabulary of springs, and the fix always goes into the shared
primitive rather than the screen that showed the bug. Read
[patterns.md](patterns.md) for the code of every pattern below, and
[verification.md](verification.md) before reporting any motion work.

### The principles

1. **Nothing teleports.** Every appear, disappear, resize and swap animates:
   error messages, a field that grows, a list that gains a row, a button
   whose label changes. Build the mechanic once as a primitive
   (`Collapse`, `AnimateDimensions`, `ContentSwap`, `StableSwap`) with a
   generic name, a doc comment and options, and use it everywhere. Never
   squeeze it into the component that first needed it.
2. **What moves together shares one spring.** A container follows its
   content live, on the same spring, instead of easing after it. Coupled
   animations (a highlight and its label, a panel and its height) are
   driven by the same transition so they can't drift apart.
3. **Choreographed, one-shot, meaningful.** Motion plays once, in response
   to something. No decorative loops, twinkling icons or pulsing objects.
   The exceptions are continuous motion on chrome and AI surfaces, and only
   where the user asked for it (principle 11).
4. **Lively springs, small distances.** Bounce lives in the spring, not in
   the distance travelled: a few pixels, a few percent of scale. Bounce on
   what arrives, pops or is touched. No bounce on heights in flow (they
   would shove what is below) or on text being read.
5. **Opacity is always a tween, never a spring.** Exits are shorter than
   entrances: bouncy in, clean out (200 ms fade in, 120 ms out).
6. **Never animate one property twice.** Two animations never drive the
   same property of one element (Motion and a CSS `transition-all`, two
   transforms); layer them on nested elements instead. Never run motion
   through a clipping box: swap two layers that fade. Never move or resize
   text whose background is clipped to it (a static shimmer is fine).
7. **Overlays stay mounted.** Dialogs, sheets, menus and popovers are always
   in the DOM and open by `open`, animating from Base UI's
   `data-starting-style` *and* CSS `@starting-style`, so they animate both
   in and out every time. Small popovers grow out of their trigger as one
   piece; large flyouts settle without scale and stagger their rows.
8. **Busy buttons keep their size.** The icon pops into a spinner, the
   disabled look eases in over 300 ms, and the spinner stays for at least
   600 ms, so a fast response doesn't flash.
9. **One selection mark slides.** A selection or hover mark moves between
   items as one object; it never disappears and reappears. Rows to choose
   from use the shared mark, not a plain hover background.
10. **The first paint is already right.** What arrives with the page
    animates in CSS from the server's HTML; nothing above the fold waits for
    JavaScript or sits at opacity 0 until hydration. Things that arrive on
    scroll are hidden only after hydration, and only while still below the
    fold.
11. **Continuous motion never stalls, and only exists where asked.** Steady
    linear loops, out of step with each other, transform and opacity only,
    no seams. Light on an object never orbits or pulses; it answers the
    pointer or flows along a path.
12. **Scroll effects follow scroll position, never a clock.** Use CSS scroll
    timelines where possible. The page must be complete without support.
13. **Page changes don't flicker.** In apps, only the content moves, a few
    pixels in the direction of navigation (`<ViewTransition>`), while the
    chrome holds still. Check scroll restoration, scroll-linked effects and
    live chrome during the transition. Use a shared-element morph only where
    it is literally the same object in both views.
14. **Reduced motion is honoured once, at the root.** Travel goes, fades
    stay, and sequences show their finished state. Values may switch on
    `useReducedMotion()`; rendered elements may not, or server and client
    HTML differ.
15. **Cheap by construction.** `LazyMotion` in strict mode; animate
    transform, opacity and clip-path only; no layout properties in CSS
    transitions.

### Two intensity profiles, one vocabulary

The token names are the same everywhere; the values differ by kind of
project. A dashboard runs the language about **30% quieter** than a
marketing site ("judge every effect as if it appears a hundred times on one
screen"). The app profile below is the floor: never quieter than that.

| Token | App profile (current, approved) | Site profile | Use |
| --- | --- | --- | --- |
| `SPRING_IN` | spring 750/16 (≈38% overshoot) | spring 550/15 | small things popping: menus, tooltips, checks; a control springing back |
| `LIFT` | spring 390/23 (≈10%) | spring 340/21 – 420/28 | surfaces and content arriving, dialog rise, icon pop |
| `SETTLE` | spring 420/28 (≈5%) | spring 120/18 (slow reveal) | big shapes where a wobble reads as a mistake |
| `ITEM_REORDER` | spring 480/40 (no overshoot) | same | heights and positions in flow, list reorder, exits |
| `ITEM_ENTER` / `ITEM_EXIT` | 200 ms / 120 ms ease-out | same | opacity |
| `ARRIVE_DELAY` | 100 ms | same | a new item waits while its neighbours glide |
| `PRESS` / `RELEASE` | spring 2000/80 / spring 500/16 | same | content sinks on press, springs back with velocity |
| press depth | 0.96 controls, 0.99 wide rows | 0.96–0.98 | |
| `--ease-out` | `cubic-bezier(0.16, 1, 0.3, 1)` | same | hover colours, underlines |
| state change | 300 ms `cubic-bezier(0.4, 0, 0.2, 1)` | same | disabled/busy, rims |
| arrival | 12 px shift, 70 ms stagger, ≤ 5 parts | 16–36 px, 70–110 ms | first-load choreography |
| page turn | out 100 ms, in 160 ms after 50 ms, 10 px (tabs 16 px) | old 200 ms fade + 5 px drift, new 260 ms + 10 px rise | `<ViewTransition>` |
| overlays | menus from 0.95 + 4 px; dialog from 0.92 + 16 px | popover 160/240 ms from 0.96; flyout rows 28 ms apart | |

Define every token once in `src/lib/motion.ts`. Generate the CSS twins as
`linear()` curves from the same springs with a script, and fail CI when the
CSS file drifts ([patterns.md § P0](patterns.md#p0-foundation-tokens-css-twins-provider)).

### Motion (JS) or CSS

| Use CSS transitions/animations (compositor) | Use `motion` (JS) |
| --- | --- |
| things that open often or swap on a click: icon swaps, overlays, flyouts, hovers, presses, busy states | layout and size changes (`layout`, auto height), presence of lists, shared-element morphs (`layoutId`), drag and other physics |
| everything that arrives with the page (first paint) | values that follow the pointer or an interrupted gesture |
| scroll-linked effects (scroll timelines) | sequences that depend on measured sizes |

This split is the current leaning, inferred from what was built and approved
since October ([OPEN_QUESTIONS.md](../../../OPEN_QUESTIONS.md) #7). CSS plays
the same springs as Motion through the generated `linear()` curves, so both
halves feel identical. Plain CSS eases and `transition-all`
are what the user rejected early on ("the motion animations were much
cleaner than the CSS ones"); the shared spring curves are what makes CSS
acceptable.

### Which pattern for what

| Situation | Pattern |
| --- | --- |
| Setting up a project | [P0 Foundation](patterns.md#p0-foundation-tokens-css-twins-provider) |
| A label, status or block is replaced | [P1 ContentSwap](patterns.md#p1-presence-enterexit-and-content-swaps-contentswap) |
| Content opens/closes, a box's content changes size, a field error appears | [P2 Collapse / AnimateDimensions / FieldError](patterns.md#p2-heightwidth-auto-collapse-animatedimensions-fielderror) |
| A button's label or icon changes, a busy state | [P3 StableSwap / BusyIcon](patterns.md#p3-stable-swaps-and-busy-buttons-stableswap-busyicon-useheld) |
| Tabs, segmented controls, selection and hover marks | [P4 layoutId indicator](patterns.md#p4-shared-element-morph-via-layoutid-selectionhover-indicator-tab--segmented-pill) |
| A card moves to another column | [P5 FLIP flight](patterns.md#p5-card-moving-between-containers-manual-flip-flight-and-list-reorder) |
| Items are added, removed or reordered | [P6 List motion](patterns.md#p6-list-add--remove--reorder) |
| Route or tab changes in an app | [P7 View Transitions (app)](patterns.md#p7-view-transitions-for-routetab-changes-in-an-app-content-only-page-turn) |
| Page changes on a marketing site, theme switch | [P8 View Transitions (site)](patterns.md#p8-page-transitions-on-a-marketing-site--cross-document-fallback-theme-switch) |
| Loading → content | [P9 Skeleton crossfade](patterns.md#p9-skeleton--loading--content-crossfade) |
| Rolling letters, digits, word morphs, streamed AI text | [P10 Text and number morphs](patterns.md#p10-number--text-morph-rolling-letters-digit-roll-word-morph-streamed-tokens) |
| Sections arriving as they scroll into view | [P11 Scroll reveal](patterns.md#p11-scroll-reveal-one-shot-arrival-as-it-scrolls-into-view) |
| Progress bars, parallax, sticky stages tied to scroll | [P12 Scroll-linked](patterns.md#p12-scroll-linked-progress-parallax-and-sticky-stages) |
| Hover and press, icon motion | [P13 Hover and press](patterns.md#p13-hover-and-press-feedback) |
| Dialogs, sheets, menus, popovers, flyouts | [P14 Overlays](patterns.md#p14-dialogs-sheets-menus-popovers-flyouts) |
| Toasts | [P15 Toasts](patterns.md#p15-toasts) |
| Multi-step progress, drawn checks, arrival choreography | [P16 Beats](patterns.md#p16-progress-in-beats-drawn-checks-arrival-choreography) |
| Ambient loops (AI surfaces, signature effects) | [P17 Ambient](patterns.md#p17-ambient--continuous-motion-only-where-asked) |
| Reduced motion | [P18](patterns.md#p18-reduced-motion-summary-across-patterns) |

### On marketing sites

- **Signature moments.** Each client site gets 3–5 signature motion moments
  derived from the business's trade, with restraint. A template's default
  motion is a starting point, not the site's character.
- **Header.** The header reacts to scroll as one surface and holds still
  through page changes.
- **No-JS visitors.** Visitors without JavaScript, reduced-motion visitors
  and print get the finished page.

### Verification (summary)

Before reporting, film every transition the change touches, at two widths,
on a production build that isn't the user's dev server, with reduced motion
**off** in the look specs. Read the frames, report numbers, and send the
user frames or a clip. Details and probe code:
[verification.md](verification.md).

## Why

Every rule here came from the user catching a jump, a flicker or a stiff
motion in review. The rules are spread across two dashboard apps, a company
website in two generations, and several client sites, September–November
2026:

- "Nothing teleports" was repeated in more than ten places.
- Fixes made per screen came back on the next screen, which is why
  everything lives in shared primitives with one token file.
- The CSS/Motion split came from measurements: Motion on the main thread
  stalled during React work while overlays opened, and CSS with the shared
  spring curves kept the feel and fixed the stalls.
- The 30% rule came from a dashboard that copied the website's motion
  one-to-one and was "too much" a hundred times a day.
- The verification steps exist because screenshots and fast frame bursts
  missed jumps the user then found in seconds.

## Exceptions

- **Not for non-React stacks as written.** The principles and tokens carry
  over to any web stack; the code assumes React 19, Next.js 16, Tailwind 4
  and `motion` ≥ 13.
- **The intensity profile is per project.** A calm client site may sit
  between the two profiles. The client-site template currently ships
  no-bounce tweens (`bounce: 0`) that were never explicitly approved; check
  with the user before treating them as the site default
  ([OPEN_QUESTIONS.md](../../../OPEN_QUESTIONS.md)).
- **Scroll reveals and parallax** are used on the newer sites, with the
  rules above. An earlier site banned them outright; whether any of those
  bans still stand is an open question.
- **Continuous motion** (AI surfaces, ambient light, signature effects) only
  where the user asked for it, and never on content objects.
- **The liquid "bead" selection mark** (hand-stepped leading and trailing
  edges) is an approved option in one app; the simpler `layoutId` indicator
  is the default.

## See also

- [../../../guidelines/ui-ux/feedback-and-states.md](../../../guidelines/ui-ux/feedback-and-states.md) — where "nothing teleports" meets loading, empty and busy states.
- [design-interface-polish](../../design/design-interface-polish/SKILL.md) — the static details (radius, shadows, icons, hit areas) the motion sits on.
- [extract-reusable-primitives](../../extract-reusable-primitives/SKILL.md) — why every mechanic above is its own primitive.
