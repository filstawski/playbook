# Layout and typography

Density, consistency between pages, and type.

## New pages copy the existing pages' structure

**MUST** · 2026-10 · dashboard apps (3 sources)

Build every new page or module from the established anatomy:

- **Page.** The main action is in the page header. One toolbar row:
  navigation and filters on the left, view switch on the right. Content sits
  on one surface, with small group headings.
- **Rows.** About 40 px rows, with the shared hover highlight and press.
- **Filters.** Styled like the existing filter fields.
- **Spacing.** A 4/8 px grid and faint lines.

No invented labels, side bars or paddings. Agree on the look of a genuinely
new kind of page before coding it.

**Why:** a first calendar view with its own paddings and colored bars was
rejected; the rework that mirrored the list pages was accepted ("looks way
better"). On another app, four redesigns of a settings page were rejected
before its look was agreed up front.

## Settings pages reuse the record page's anatomy

**SHOULD** · 2026-10 · client dashboard app

Header, tabs, and headed sections of hairline rows: icon tile, label with a
quieter description, and the action at the end. Add a side column so the
page never looks empty. Don't cage every section in a bordered card ("still
looks awful, especially since all content is caged into these boxes"), and
don't render status checks like checkboxes; use badges.

## Cards in a row end evenly

**MUST** · 2026-10 · dashboard app

Cards sharing a grid row must not leave a blank band below their content.
Pin footers and summary lines to the bottom (`mt-auto`), let each card fill
the row height, give a short card meaningful secondary content, and keep the
bottom padding consistent. Measure each card's gap instead of eyeballing it,
and fix every page where it happens.

**Why:** stretched cards ended 31–59 px below their last line ("just an ugly
gap"), and another card was up to 40% empty depending on language. The user
asked for it to be fixed everywhere and never to recur.

## Compact controls in dense apps

**MUST** · 2026-10 · dashboard app

In data-heavy apps, use a compact button scale: default 28 px tall with a
13 px label, small 24 px, extra-small 20 px, large 32 px. Icon-only buttons
match those heights. Keep page insets tight. Inputs may stay at 32 px for
comfort.

**Why:** "on the pages where there are a lot of buttons, I expect them to
be smaller."

## Marketing pages two steps below generous defaults

**MUST** · 2026-10 · company website

Generous marketing-site spacing reads as bloat. Step the whole scale down
together (section gaps, display and section type, panel padding, radii,
control heights) rather than shrinking one thing; in a second pass include
body text. "Clumpy" is radius and padding as much as size. Measure page
heights before and after.

**Why:** asked twice on consecutive days: "too bulky, too clumpy, too big
elements. Go down further."

## One primary button per section

**MUST** · 2026-10 · dashboard apps

A section shows one visible primary button; secondary actions go behind a ⋯
menu instead of a row of three buttons. (Icons and busy states:
[interaction.md](../ui-ux/interaction.md#buttons-keep-their-size-every-action-has-an-icon).)

**Why:** the user disliked "a lot of buttons next to each other" and
suggested moving them into a menu.

## Type: weight play sparingly, modest display sizes

**SHOULD** · 2026-10 · company website, client sites

- A headline in two weights (the key phrase strong, the rest light and
  muted) is a signature. Use it only for the hero and the closing call to
  action, never on every heading ("I like playing with font weights, but
  more decent and not everywhere").
- Keep display sizes modest (a hero of about 64–92 px at most, not poster
  size). Keep the hero short: one headline, medium weight.
- In dense apps, section headings stand out by weight, not size.
- Choose a display face by setting the real headline in 3–4 candidates side
  by side.

**Why:** weight play that was everywhere and huge read as "comic", and a
hero of about 34 words was "packed" and hard to read.

## Design out awkward wraps

**SHOULD** · 2026-10 · dashboard app

Never put two amounts with different meanings (one-time and recurring) on
one figure line. The main amount is the big figure; the other sits on its
own line. In narrow panels, use fixed two-line row layouts, short state
labels, stacked rather than wrapping buttons, and compact dates instead of
long relative phrases. Apply language-specific typesetting rules (e.g. no
single-letter words at line ends in Polish).

**Why:** the user disliked "the total + monthly … pressed into one line" and
noticed inconsistent line breaks in smaller elements.

## Measure optical centering before calling UI done

**SHOULD** · 2026-10 · dashboard app

For adornments inside inputs (a color dot, an icon button), measure the
inset on all sides in the browser and make it equal. Hover backgrounds must
not be clipped by the field edge. The user notices few-pixel offsets in
screenshots.

## Mobile: floating panels, no device-corner chasing

**MUST** · 2026-10 · dashboard app

Keep mobile panels and sheets floating, with their own small radius and an
even inset. Don't compute corner radii from the device's screen curvature,
and don't turn side menus into flush full-height drawers. Scope an
unavoidable platform fix to that platform, and check the other platform too.

**Why:** two PRs of screen-matched corners and drawers looked wrong on
Android and left a gap on iOS. "The sidebar things you made are horrible,
let's roll back all of it."
