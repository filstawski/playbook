# Depth and materials

Flat, static UI is consistently rejected, and so is one effect applied to
everything. These are the rules for depth, surfaces, radius, shadows and
texture.

## Flat is rejected, from the very first version

**MUST** · 2026-10 · dashboard apps, company website (4 sources)

Even a first shell or skeleton carries the design language: transitions,
fine texture, depth from light (lit edges, layered shadows), press feedback.
Every page needs visible depth and at least one authored animation. The
opposite extreme, one material or gimmick on every surface, is rejected
too. Text always sits on solid surfaces.

**Why:** "The shell looks awful currently. There are no transitions,
animations, effects, no texture, no depth, no recessions, no bounciness."

## "Doesn't fit" usually means flat; fix the material, don't delete

**MUST** · 2026-10 · dashboard app

When the user says an element doesn't match the UI, first suspect it is flat
next to components that have depth and texture. Give it the design
language's materials instead of removing or replacing it. If the feedback is
ambiguous, ask, or show both.

**Why:** "the progress bar doesn't fit" was read as "remove the bars", and
they were replaced with numbers. The user had meant the bars looked flat:
"No man, the progress bars were fine … they don't fit since they're flat
compared to the other components."

## One depth model for an app

**SHOULD** · 2026-09 → 2026-10 · dashboard apps (3 sources)

| Layer | Treatment |
| --- | --- |
| Chrome (sidebar + top bar) | one flat plane: same background, no border between them, matched heights, one spacing unit on all sides |
| Page content | a rounded surface recessed into the chrome, shaded from the chrome's edges (inset), not a drop shadow |
| Grouped panels | one step lighter than the content plane (dark theme) |
| Inputs | wells cut into the content |
| Solid buttons | bulge out: highlight top-left, shade bottom-right, deepening on press, built into the primitive |
| Dialogs and sheets | lift above everything, with a recessed body |

New surfaces pick from these levels through tokens; they don't invent a
level of their own.

**Why:** the user wanted the sidebar and top bar on one level, above the
page content, which should look deeper and "visually separated".

## Radius scales with size and nests concentrically

**MUST** · 2026-09 → 2026-10 · dashboard apps, company website (4 sources)

Use a small radius scale that grows with the element:

| Element | Radius |
| --- | --- |
| Controls (buttons, inputs, nav rows) | ~8 px |
| Cards, tables, menus | ~12 px |
| Sheets and dialogs | ~16–22 px |

- **Nesting.** A shape inside another takes the outer radius minus the
  padding, so highlights align with their container. When an image sits
  inside a rounded control, clip it with the parent instead of giving it
  its own radius.
- **Buttons** never look rounder than the surfaces around them. Pills only
  for buttons and tracks, and never a pill next to square-ish controls.
- **Framework defaults.** Switch off the framework's larger radii so they
  can't creep back.

**Why:** "It's way too round and looks too similar to the previous
version." Big radii read as dated.

## Shadows seat an element; they don't float it

**SHOULD** · 2026-10 · dashboard app, company website

Keep shadows short, light and neutral: about 16 px at rest and 24 px on
hover for controls, not 44–64 px. No long dark shadows under the header,
footer or buttons. When asked for "more decent" depth, cut every shadow's
reach and opacity by about a third, and keep hover lift to about 0.8%
scale.

**Why:** the shadow under the header and footer was "too much", and the user
asked for all depths and shadows to be "quite a bit more decent".

## Decoration is quiet and differs in kind from structure

**SHOULD** · 2026-10 · company website, dashboard app

- **How much.** One quiet decorative element per area beats several.
- **What kind.** Decoration is soft light and fine grain, never hairlines:
  thin bright lines collide with borders and dividers and read as "liney".
- **Strength.** A background never takes focus. Start a ground treatment at
  about half the strength that looks right in isolation.
- **Meeting textures.** Two textures never blend into each other through a
  shared gradient. Separate them in space or in time, and end an area with
  one long gentle fade rather than several short ones.
- **Edges.** A decorative drawing inside a card fades out at least 6 px
  before every edge. A see-through mark is one shape with opacity on the
  whole, so overlapping paths don't show brighter.

**Why:** a background light was "way too dominant" and pulled focus from the
page, and decorative lines clashed with page borders ("it looks weird when
the lines collide").

## Grain only where it does a job

**SHOULD** · 2026-10 · company website

Put fine grain inside light and glow gradients, where it also removes
banding. Never over text, over metallic effects, over plain black, or in
the header. Keep it static, tuned per placement, and hidden in print ("I
definitely don't want it over everything").

## Chrome is one piece; an accepted treatment goes everywhere

**SHOULD** · 2026-10 · company website

Build header and footer as single blocks, without internal dividers ("make
it one blob"). When a treatment is approved for one instance of an element
(an animated logo in the header), apply it to every place the element
recurs (footer, favicon) without being asked twice. When recreating a
mockup, reproduce its depth and finish, not just its layout.

**Why:** the user had to ask separately for the header's logo treatment in
the footer, and a recreated mockup "fully missed on the gradients and
depths" the user wanted.
