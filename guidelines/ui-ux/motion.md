# Motion

Motion has its own skill with the full rules, tokens, code and verification:
[website-motion](../../skills/website/website-motion/SKILL.md). These are
the rules an agent must know even without opening it.

## Nothing teleports

**MUST** · 2026-09 → 2026-11 · every UI project (10+ sources)

Everything that appears, disappears, resizes, swaps or moves gets there
continuously. Fix it once, in the shared primitive.

**Why:** it is the user's most repeated UI complaint across projects ("the
invalid state just teleports in"). An unanimated change reads as broken next
to the rest of the UI, and per-screen fixes kept regressing.

## Dashboards are about 30% quieter than websites

See [restraint-and-character.md](../design-guidelines/restraint-and-character.md#dashboards-run-about-30-quieter-than-the-website):
the same vocabulary, a third quieter, the app profile as the floor.

## Bouncy in, clean out

**MUST** · 2026-10 → 2026-11 · dashboard apps, company website

Springs carry the bounce, over small distances. Opacity is always a short
tween, and exits are shorter than entrances.

**Why:** the user asked for "a little more bounce" on popovers but rejected
a two-spring "jelly" on dialogs. A close that reused the opening spring
stayed mounted, invisible, for about 740 ms.

## Overlays stay mounted

**MUST** · 2026-10 · dashboard apps

Dialogs, sheets and menus stay in the DOM and animate in and out every time
they open. Busy buttons are in [interaction.md](interaction.md#buttons-keep-their-size-every-action-has-an-icon).

**Why:** two dialogs were remounted on every opening to clear their forms,
and just popped up; the user asked for it to be fixed across the whole app.
Reset form state in the close-complete callback instead, and keep an e2e
guard that fails when an overlay appears without animating.

## Film every transition before reporting

**MUST** · 2026-10 → 2026-11 · dashboard apps, company website (4 sources)

Watch every transition the change touches, frame by frame, at two widths, on
a production build. Static screenshots are not proof.

**Why:** a view switch shipped that slid twice, because the page width
changed only when the server answered. Stills of each view had hidden it,
and the user asked how it could go unnoticed.

**Changed:** in September, agents were told not to check visuals themselves
("the user reviews the look"). Since October, agents film and check every
transition before reporting.

## Decide motion with variants side by side

**SHOULD** · 2026-10 · dashboard apps, company website

The user decides feel by seeing options next to each other, on a dev-only lab
page with slow-motion controls, and then picks quickly.

**Why:** one section went through four rejected guesses before a single
side-by-side preview settled it in one answer.
