# Code style

Language, comments, types and formatting in frontend (and general
TypeScript) code. The pre-commit pass that enforces most of this is
[code-polish](../../skills/code-polish/SKILL.md).

## Code in English, everything users read in their language

**MUST** · 2026-09 → 2026-11 · every project type (6 sources)

Identifiers, routes, file names, comments, union members and database names
are English ("I want all source code to be English"). Everything a user
reads is in the UI language, including `aria-label` and `alt` text. On
German sites that means the formal *Sie*. Domain terms that English would
mislead keep their native name, recorded in a glossary.

**Why:** mixed code looked bad to the user: "it looks awful to have half
German and half English."

## UI text lives in label modules, never inline in components

**MUST** · 2026-10 → 2026-11 · dashboard apps

All UI copy comes from per-feature `labels.ts` files (or content modules on
a site). Type enum labels as `Record<Union, string>`, so a new member can't
ship without its label. Reviews move stray inline strings into the labels
file.

**Why:** with one source per text, the languages of a bilingual site sit
side by side, so one can't silently fall behind.

```ts
// features/projects/labels.ts
export const statusLabels: Record<ProjectStatus, string> = {
  draft: "Entwurf",
  active: "Aktiv",
  archived: "Archiviert",
};
```

**Changed:** an agent note in mid-October said static text was in practice
written inline. The newest projects (Nov 2026) enforce label files.

## Placeholders

The placeholder rule (a bare example value, selects show the action) is in
[../ui-ux/forms.md](../ui-ux/forms.md#every-input-has-a-bare-example-placeholder);
the strings come from the label modules too.

## Comments say why; types are honest

**MUST** · 2026-09 → 2026-11 · every project type

- **Comments explain why, never history.** No "used to…", no names of
  uncommitted code. Comments change with the code they describe.
- **Doc comments.** Every exported component and hook has one: purpose,
  contract, surprises. A non-obvious number gets its meaning.
- **No escape hatches without a reason.** No `any`, `@ts-ignore`,
  `eslint-disable`, or `as` without a stated reason above it. Narrow library
  types with `Omit`, and use type guards for strings from outside.
- **Fix the code, not the rule.** When an import-boundary lint rule fires,
  move the code instead of disabling the rule.

## Formatting: the repo's Prettier, never ad hoc

**SHOULD** · 2026-10 → 2026-11 · every project type

Use the repo's Prettier config (with the Tailwind plugin; Markdown excluded
and laid out by hand). In a repo with no formatter config, match the file
and wrap by hand: running a formatter with defaults reflows whole files and
wrecks a reviewed diff. Import order is packages, a blank line, `@/` imports
sorted by path, a blank line, then relative imports. Type-only names are
imported inline.

**Changed:** print width is per project (one app has no Prettier and is
wrapped at ~120 by hand; others use 100 or 120). The constant is "Prettier
in CI where configured, never ad hoc".

## One source for each value

**SHOULD** · 2026-10 → 2026-11 · dashboard apps, websites

Share values; never copy them under a new name. When a size or colour is
missing from the scale (a `2xs` text size), extend the theme rather than
scattering arbitrary values ("in such cases please extend Tailwind with
like a 2xs"). This holds for springs, design tokens, business facts and
content lists alike.

**Why:** springs scattered across files in an earlier app drifted apart.

## Tailwind 4 discipline

**SHOULD** · 2026-10 → 2026-11 · websites

Tokens over arbitrary values. No class names built at runtime
(`` `bg-${color}` `` is invisible to the compiler). On sites without a kit, a
ten-line `cn()` that joins class names replaces `tailwind-merge`.

## Enforce boundaries with lint rules

**CONSIDER** · 2026-10 · prototype, dashboard apps

Keep pure logic (scheduling, simulation, rule engines) free of React and
I/O imports, so it is unit-testable and can feed several views. Enforce
folder boundaries with `no-restricted-imports`; see
[../backend/architecture.md](../backend/architecture.md).
