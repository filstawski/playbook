---
name: design-taste
description: >-
  Decide and review the look of a site or app so it reads as designed for
  that business, not generic or AI-made: read the brief, take the identity
  from the business, show directions side by side, audit before a redesign,
  apply the house taste rules, and run a pre-flight check. Use when designing
  or redesigning pages, choosing a visual direction, or when the user says
  something looks generic, flat, ugly, "AI", too much or doesn't fit.
metadata:
  type: practice
  category: design
---

## Rule

Design work is judged by the user looking at it, and most failed rounds came
from one of three things: a generic first version, an agent guessing again
after a miss, or feedback read wrongly. This skill is the process that
avoids them. The rules themselves live in the design guidelines; read the
ones that apply before starting:

- [color](../../../guidelines/design-guidelines/color.md)
- [depth and materials](../../../guidelines/design-guidelines/depth-and-materials.md)
- [layout and typography](../../../guidelines/design-guidelines/layout-and-typography.md)
- [restraint and character](../../../guidelines/design-guidelines/restraint-and-character.md)

The small details (radius maths, optical alignment, icons, hit areas) are
[design-interface-polish](../design-interface-polish/SKILL.md); motion is
[website-motion](../../website/website-motion/SKILL.md).

### 1. Write the design read first

Before any code, write one sentence that names:

- the kind of page or app (brochure site, campaign page, dense dashboard)
- the audience
- the visual language
- the hard constraints (accessibility, legal pages, a brand that already
  exists)

> Brochure site for a regional craft business; customers are homeowners
> 40+; calm, warm, photo-led; brand colour from the van livery; German, *Sie*.

Ask a question only when the read is genuinely ambiguous, and then one
question with a recommended answer. Otherwise proceed, and list the
decisions you took.

### 2. Identity and truth come from the business

- **Colour.** The palette comes from the logo and from how the owner
  presents the business: vehicles, signage, print. Flag a sampled colour
  that looks doubtful.
- **Material.** Real photos of real work, and the business's own words and
  facts. If there are no photos, leave a clearly marked slot and list what
  is missing; never stock people or invented screenshots.
- **Signature motion.** Take 3–5 signature motion moments from the trade.
- **Nothing untrue:** no invented numbers, testimonials, logos, awards,
  team members or "trusted by" walls.

A site built from the template must look like its business, not like the
template.

### 3. Show, don't describe

The user decides looks by seeing options next to each other and then picks
quickly:

- For a visual choice (an effect, a colour, a layout), build a dev-only lab
  page or side-by-side variants in the browser. Never ask the user to
  choose from prose.
- After **one** miss, or when criticism names a problem without a
  direction, stop guessing. Offer 3–4 genuinely different directions, with
  rendered previews and a recommendation.
- "Start from 0" means a new concept, not a reshuffle of the current one.
- Mock-ups must read as a website, not as a poster or flyer.
- When exploring for a client, vary the layouts, not only the skins.

### 4. Redesigns: classify, audit, then change in order

1. **Classify the job.** Evolve the existing look, overhaul the visuals but
   keep content and structure, or start from scratch (new brand). Ask once
   if it is unclear.
2. **Audit before changing.** Note the brand tokens, the structure and
   conversion paths, which content blocks work and which are filler, the
   patterns to keep and to retire, and the SEO baseline (URLs, titles).
3. **Change in this order**, and stop when the brief is met:
   1. type
   2. spacing and rhythm
   3. colour roles
   4. depth and materials
   5. motion
   6. recomposing the hero and key sections
   7. replacing whole blocks
4. **Never change silently:** URLs (redirect every old one), main
   navigation labels, form fields, the logo, legal and consent text.
5. **Re-code, don't merge.** When re-coding someone else's page, list its
   visible behaviours first and keep every one of them.

### 5. Read the user's feedback the way it is meant

| The user says | It means |
| --- | --- |
| "doesn't fit", "looks off" | usually *flat* next to elements with depth. Add material; don't delete the element. If unsure whether they mean the thing or where it meets its neighbour, ask. |
| "too much", "too dominant" | halve it; a background stealing focus must recede |
| "a little bit" | visible but small |
| "decent" (German *dezent*) | understated; start quieter than feels necessary |
| "weniger ist mehr" | remove an element, don't tune it |
| "looks AI-generated", "generic" | one of the patterns in step 6 is present; replace it with a treatment specific to this site |
| "ugly", "awful" with no direction | stop guessing and offer 3–4 previewed directions (step 3) |
| "start from 0", "fresh shot" | a new concept |
| "refactor this" (about visible UI) | it may mean the look; ask or show |
| a fix for one page | applies to every page of that kind |

### 6. Patterns that read as generic or AI-made

The user flagged these, or they are standard tells. Replace them with a
treatment specific to the site:

- an eyebrow pill or badge above the hero heading (and eyebrows in general;
  ration them hard)
- icons in bordered square tiles on cards
- three identical feature cards in a row
- a generic nav bar with a hover pill
- purple/blue gradient glows, neon outer glows, gradient text on large
  headlines
- a centered hero over a dark gradient mesh, glass on every surface, endless
  micro-loops
- numbered section labels ("01 / Capabilities"), image counters ("01 / 4"),
  "scroll" cues, decorative status dots, crosshair grids that organize
  nothing
- pretentious or explanatory meta-lines under headings ("Quietly trusted
  by…"), hype words (seamless, elevate, unleash, next-gen)
- pills or tags laid over photos; div-built fake product screenshots
- a lone section in the inverted theme
- precise-looking numbers that aren't real data

### 7. House taste in one screen

- **Restraint.** Default to the quietest option of every effect. Keep each
  placement's strength in one config table.
- **Flat is rejected, from the first version.** Depth comes from light, fine
  texture and authored motion; but never one gimmick on everything.
- **Colour.** Neutral surfaces; the brand colour on actions, selection and
  focus only; every colour has one meaning; shadows are never coloured.
- **Shape.** A small radius scale (about 8/12/16–22 px) that nests
  concentrically. Buttons never rounder than their surroundings.
- **Density.** Marketing pages two steps below "generous" defaults.
  Dashboards use compact controls (28 px default buttons) and run about 30%
  quieter than the website.
- **Type.** Modest display sizes. Weight play only on the hero and the final
  call to action. One copy register per page.
- **Hero.** It fits the first viewport: a headline of at most two lines on
  desktop, one short lead sentence, the actions visible without scrolling.
  Use `min-h-[100dvh]`, never `h-screen`.
- **Layout.** Each layout family at most once per page, no more than two
  image/text splits in a row, and every multi-column section with its own
  phone layout.
- **Mobile.** Floating panels with their own small radius. No device-corner
  matching, no flush drawers.

### 8. Pre-flight before showing anything

- [ ] The design read is written, and the page matches it.
- [ ] Every fact, number and image is real or marked as missing (and listed
      to the user).
- [ ] Nothing from step 6 is on the page.
- [ ] The brand colour appears only in its roles; neutrals are neutral;
      text contrast meets WCAG AA on every surface.
- [ ] Radii follow the scale and nest; shadows are neutral and short.
- [ ] The hero fits the first viewport at 1440 and 1280 px; the desktop nav
      fits on one line at 1024 px.
- [ ] No horizontal scroll from 320 to 1920 px; every multi-column section
      has its phone layout.
- [ ] States exist: hover, focus, pressed, disabled, loading, empty, error.
- [ ] Motion follows [website-motion](../../website/website-motion/SKILL.md)
      and was filmed; nothing above the fold waits for JavaScript.
- [ ] The details pass [design-interface-polish](../design-interface-polish/SKILL.md).
- [ ] Screenshots at desktop and phone widths are ready to send with the
      report.

## Why

The user rejected flat first versions ("no transitions, no texture, no
depth"), overloaded ones ("way too dominant", "too liquid"), generic ones
("looks like AI"), and rounds where the agent kept guessing ("I feel like
you're getting behind"). The first three are content problems: the
guidelines and the tells list address them. The last is a process problem:
side-by-side directions, a fixed feedback table and an honest pre-flight
address it.

The upstream skills this was rebuilt from (see the README) brought the
redesign protocol, the hero and layout heuristics and much of the tells
list. Their rules that clash with this repo's decisions were dropped:

- invented realistic data
- placeholder photo services
- icon-library preferences against Lucide
- reveals that hide server HTML until hydration
- dashboards declared out of scope

## Exceptions

- **Dashboards are in scope** here, unlike in the upstream skill. Apply the
  density, colour-role and depth rules with the app profile; the
  hero/landing heuristics don't apply.
- **German typography** uses the spaced en dash as a dash (*Gedankenstrich*)
  and in ranges. The upstream ban on dashes targets English AI prose, not
  German typesetting; for English copy, see
  [marketing-copywriting](../../marketing/marketing-copywriting/SKILL.md).
- **An existing design system or a strong existing brand** outranks these
  defaults; evolve it rather than overriding it.
- **The user has the last word on feel.** When the user approves something
  that breaks a rule here, record the exception in the project's design doc
  instead of "fixing" it later.

## See also

- [design-interface-polish](../design-interface-polish/SKILL.md) — the detail pass.
- [website-motion](../../website/website-motion/SKILL.md) — all motion.
- [website-nextjs-site-setup](../../website/nextjs/website-nextjs-site-setup/SKILL.md) — where a new site's design work sits in the build order.
