# Restraint and character

How strong effects should be, how each project gets its own character, and
what reads as generic or AI-generated. The full design process (directions,
audits, pre-flight checks) is the skill
[design-taste](../../skills/design/design-taste/SKILL.md).

## "Decent" means subtle; default to the quietest option

**MUST** · 2026-10 · every UI project (5 sources)

The user writes "decent" in the sense of German *dezent* (understated).
Start effects quieter than feels necessary. Given A/B/C intensities, the
user picks the lightest one, repeatedly. Keep the strongest instance on the
main action and weaker ones elsewhere. Keep each placement's numbers
(strength, speed, density, color) in one config table, so one place can be
tuned without touching the others.

How to read the feedback:

| User says | Do |
| --- | --- |
| "too much" | cut it to about half |
| "a little bit" | visible but small |
| "too dominant" | the background is stealing focus; make it recede |
| "weniger ist mehr" / "less is more" | remove an element, don't tune it |

**Why:** nearly every effect was turned down at least once ("way too
dominant", "too aggressive", "less is more"), and tuning each placement on
its own resolved it.

## Dashboards run about 30% quieter than the website

**MUST** · 2026-10 · dashboard apps (3 sources)

An internal app shares the visual and motion vocabulary of its company's
website, toned down by about a third for density and long use ("judge every
effect as if it appears a hundred times on one screen"). The calm app
profile in [website-motion](../../skills/website/website-motion/SKILL.md) is
the floor. When toning a design down, keep the full-strength version on a
branch: the user may want it back. Large shapes and
things in flow use calm springs, and only small pops may bounce.

## AI surfaces get their own lively look

**SHOULD** · 2026-10 · dashboard apps

Whatever an AI produced, or is working on, has its own palette (away from
brand and error colors) and continuous, flowing light: drifting glows along
the edges, a slow rim, waves while working, a bloom on arrival. Never just a
colored border ("I want some nice moving wavy/glowy effects too"). It has two
intensities: working (brisk) and needs attention (slow and quiet; several
may coexist). Cap how many animate at once. Continuous motion belongs to AI
surfaces and the few chrome or signature effects the user asked for, never
to content objects; don't borrow it for emphasis
([OPEN_QUESTIONS.md](../../OPEN_QUESTIONS.md) #10).

**Why:** an AI input with only a colored border looked "too boring" to the
user. For customer-facing surfaces the user added: "don't overkill it".

## Avoid patterns that read as AI-generated

**MUST** · 2026-10 · company website

The user flagged each of these as "AI generated" or "generic":

- an eyebrow badge or pill above the hero heading;
- icons sitting in bordered square tiles on marketing cards (a small icon
  tile in a settings row is fine);
- a generic nav bar with a hover pill.

Prefer a distinctive treatment, e.g. the card's icon drawn large and faint
in its corner, cut off by the edge.

## Each client site looks like that business

**MUST** · 2026-11 · client sites

A site built from the template must look like its business, not like the
template. Identity comes from the business: its logo, colors, photos and
trade. Its 3–5 signature motion moments come from the trade too: a
movement borrowed from the craft, not a generic fade. A first version that is flat and blocky isn't
done; add a few restrained, trade-derived accents. Keep the tone friendly
rather than aggressive, and professional and simple for every audience.

**Why:** the user wanted a new site "professional and tailored to his
business", and first drafts were called "too aggressive", "too sharp" and
"blocky and empty".

## "Start from 0" means a new concept

**MUST** · 2026-09 → 2026-10 · client sites, company website

When the user says "start from zero", deliver a new concept, not a
reshuffle of the current one. When the direction is unclear, explore several
genuinely different directions side by side, and build only the one picked.
Design mockups must read as a website, not as a poster or flyer. After a
design miss, offer 3–4 previewed options rather than one more guess.

**Why:** three successive rewrites kept the same palette and structure, and
the user had to repeat the request with growing frustration. Poster-like
direction boards were rejected even when the palette was liked.

## Truthful content is part of the design

The rule is in [../frontend/websites.md](../frontend/websites.md#nothing-untrue-on-a-site):
nothing invented. As a design matter: impress with specific, checkable facts,
and keep legal and registration details on the legal pages, off the
marketing pages.
