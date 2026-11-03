# Color

How color is assigned in the user's interfaces. Tokens and contrast are
noted next to each other in the theme.

## Every color has exactly one meaning

**MUST** · 2026-10 · dashboard apps (5 sources)

| Role | Color |
| --- | --- |
| The logo | the exact brand color |
| Primary action, links, selection, "now" | a calmer, deeper tone of the brand |
| Needs attention, nothing broken | amber |
| Checked, it fits, done | green |
| Errors and destructive actions | one strong error hue (shared token) |
| Anything AI | its own palette, away from brand and error colors |

Never reuse a color that already means something. Statuses are plain words
in rows and a muted chip on a record. A new color earns its place only with
a new meaning.

**Why:** in one app a single red did five jobs next to the error red.
Focused inputs looked invalid and a warning banner looked like selected UI
("our red looks like it's an error").

## The brand color is never decoration

**MUST** · 2026-10 · dashboard apps, company website (4 sources)

Keep large surfaces, lines and text neutral grey, with at most a very slight
cool cast. Don't tint greys, surfaces, lines, muted text or hover sheens
with the brand hue; each tint is faint, but together they make the whole
page read as the brand color. The brand color stays on:

- the primary action
- the selected nav item, tab or view
- input focus
- the current step
- links, and one emphasized keyword

No brand-colored accent bars on rows, no brand badges on every "new" item.
When removing tint, keep each token's lightness so contrast stays the same.

**Why:** "I really liked the blue-ish at the beginning but it's getting too
much … accent and buttons can still be blue." A redesign with brand bars on
every row was what made one UI look "unmatching".

## Input focus: brand accent, unless the brand is red

**SHOULD** · 2026-10 · dashboard apps

Text inputs show focus as a brand-accent rim with a faint halo, not white.
An invalid field stays red while focused. Keyboard focus rings on buttons
and links stay neutral. If the brand color is red, input focus is neutral
grey too, because red on a control may only ever mean "invalid".

**Changed:** a red-branded app moved focus from brand red to grey
(2026-10-01; the user was "not 100% sure about the grey, but let's keep it").
The next, blue-branded app went back to brand focus ("we made it white
there just because red made it look like an error").

## A strong error red, one token for error and destructive

**SHOULD** · 2026-10 · dashboard app

When the brand isn't red, use a strong, saturated cherry red for errors
(e.g. `oklch(0.65 0.22 15)`), checked for AA contrast on every surface.
When the brand is red, shift and desaturate the error hue to keep the two
apart. Keep red out of decorative palettes such as tag colors.

**Why:** an earlier red-branded app kept its error red weak only because
brand red and error red would otherwise have been the same.

## Shadows are neutral, never brand-colored

**MUST** · 2026-10 · dashboard app, company website

No colored shadows or glows under dialogs, sheets, menus, buttons or logos
("a blue shadow doesn't make sense"). See
[depth-and-materials.md](depth-and-materials.md) for shadow size.

## Effects stay in the brand's own hues

**SHOULD** · 2026-10 · company website

Light effects, metallic finishes and background glows are tinted with the
brand color, not neutral silver or a trendy icy palette. Color cycles use
only saturated stops; a pale stop washes everything toward white.

**Why:** the user asked for the metallic logo emblems in the brand's blue
rather than silver, to stay with the branding.

**Changed:** an icy "glacier" tint requested on 2026-10-28 was called
outdated three days later ("let's stick to the branding").

## Take the brand from the business

**MUST** · 2026-11 · client sites (3 sources)

A client site's palette comes from the business's real identity: the logo,
plus how the owner presents it (vehicles, signage, existing print). Flag a
sampled color that looks doubtful instead of guessing. Use one brand color
on every background unless asked otherwise. Switch Tailwind's default
palette off and use role-named tokens, with each text pairing's contrast
noted next to the token.

**Why:** a first preview used the pure red that a logo file measured, while
the owner's color is orange; the user had to point it out.

```css
@theme inline {
  --color-*: initial;                       /* no stray palette colors */
  --color-ground: oklch(0.985 0.003 90);
  --color-ink: oklch(0.24 0.01 260);        /* on ground: 14.8:1 */
  --color-accent: oklch(0.52 0.13 250);     /* on ground: 5.9:1, links and primary */
  --color-danger: oklch(0.58 0.21 25);      /* errors only */
}
```
