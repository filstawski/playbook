# design-interface-polish — sources

## Based on

- **[make-interfaces-feel-better](https://github.com/jakubkrehel/make-interfaces-feel-better)**
  by Jakub Krehel (MIT). It was installed in the four newest website repos
  and invoked on the company website. Its systematic detail rules (radius
  maths, layered elevation rings, image outlines, hit areas, text wrapping,
  numerals, icon strokes, transition hygiene) and its quick/full review
  format are restated here in our own words.
- **The user's own polish corrections, Sep–Nov 2026**, across two dashboard
  apps, the company website and the client sites: pointer cursors, locked
  states, buttons that keep their size, measured optical centring, even
  card rows, neutral short shadows, primitive-level fixes.

## Adapted or dropped

- **Press scale** follows the user's tokens (0.96 controls, 0.99 wide rows)
  instead of a single value.
- **Icon-swap motion** values from the upstream skill (no-bounce springs)
  are not adopted; motion lives in
  [website-motion](../../website/website-motion/SKILL.md).
- **Upstream stagger and scale defaults** were too generic in practice: on
  the company website, a large panel that scaled in read as a zoom. Those
  cases are now covered by the overlay rules in the motion skill.

## Licence notice

The upstream skill is distributed under the MIT License:

> Copyright (c) 2026 Jakub Krehel
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
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
> FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
> DEALINGS IN THE SOFTWARE.
