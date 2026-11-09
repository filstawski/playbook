# website-motion — sources

This README is provenance for maintainers; agents read `SKILL.md`.

| File | What it holds |
| --- | --- |
| [SKILL.md](SKILL.md) | the rules, the two token profiles, CSS vs Motion, which pattern for what |
| [patterns.md](patterns.md) | P0–P19: runnable code for every pattern, with pitfalls and fixes |
| [verification.md](verification.md) | how motion is checked before reporting, with probe and capture code |

## Based on

- **The user's own projects, Sep–Nov 2026.** The code, rules and the
  user's feedback come from: two full-stack dashboard apps (the newer one's
  token file is the canonical app profile), a company website in two
  generations, the client-site template and three client sites built from
  it, and a prototype. Project names and domain details are removed.
- **Memory notes and transcripts** in which the user approved, rejected or
  tuned motion (nothing teleports, smooth swaps, continuous motion, busy
  buttons, verification by filming).
- **[apple-design](https://github.com/emilkowalski/skills/tree/main/skills/apple-design)**
  by Emil Kowalski (MIT), a web translation of Apple's WWDC talks, chiefly
  *Designing Fluid Interfaces* (2018). Added 2026-11-09 and restated in our
  own words. It is a source of ideas, not of decisions, and our rules win
  wherever the two disagree. What was taken: the gesture physics in P19
  (1:1 tracking, catching mid-flight, slop, rubber-banding, velocity
  handoff, momentum projection), the ratio/response conversion in
  SKILL.md, the reduced-transparency and more-contrast overrides in P18,
  and the caution about large slow loops in P17. The projection and
  rubber-band formulas were checked against Apple's sample code before
  adoption. None of it has been tuned by the user yet.
- **No other third-party skill text.** Some general principles also appear in
  `make-interfaces-feel-better` by Jakub Krehel (MIT, see
  [design-interface-polish](../../design/design-interface-polish/README.md)):
  exits shorter than entrances, never animating from scale 0, and restraint.
  They are stated here in the form the user's projects settled on.

## Dropped on purpose

The "liquid glass" design language of an earlier company website (glass
materials, caustics, WebGL objects, pointer-lit surfaces) is outdated and
not carried over. Only its motion lessons that later projects kept are
here.

From apple-design, these were left out or changed on purpose:

- **Critically damped by default, bounce only after a flick:** not
  adopted. Our springs respond as fast as Apple's; the bounce is the
  user's decision (SKILL.md, "Reading spring values from elsewhere").
- **Mirrored easing, the same path in and out:** only the direction is
  kept (a sheet leaves toward its edge). Exits stay shorter and without
  bounce ("bouncy in, clean out").
- **Translucent materials and glass chrome:** not adopted, for the same
  reason as the liquid-glass language above. Only the accessibility
  overrides for translucent surfaces we still have were taken.
- **"Motion's `bounce`/`duration` maps closely to damping/response":**
  wrong. Motion's `duration` is the settle time.
- **Synchronised haptics:** not possible on the user's iPhone, because
  iOS Safari has no Vibration API.
- **Hand-rolled pointer history everywhere:** only for snap panels (P19).
  Motion's own `drag` already measures velocity well for free drags (P5).
- **Motion blur for fast motion, typography, the eight design principles
  and process:** out of scope for a motion skill or not yet seen in the
  user's projects. Typography and principles belong to the design skills.

## Licence notice

apple-design is distributed under the MIT License:

> Copyright (c) 2026 Emil Kowalski
>
> Permission is hereby granted, free of charge, to any person obtaining a
> copy of this software and associated documentation files (the
> "Software"), to deal in the Software without restriction, including
> without limitation the rights to use, copy, modify, merge, publish,
> distribute, sublicense, and/or sell copies of the Software, and to permit
> persons to whom the Software is furnished to do so, subject to the
> following conditions:
>
> The above copyright notice and this permission notice shall be included
> in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
> OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
> MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
> NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
> DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
> OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
> USE OR OTHER DEALINGS IN THE SOFTWARE.
