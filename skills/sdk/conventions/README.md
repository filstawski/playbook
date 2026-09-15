# sdk / conventions

Naming, visibility, and file-layout rules applied across every structure
and manager file — the "how it's written," as opposed to
[../managers](../managers/README.md)'s "how it's architected."

- **[sdk-naming-conventions](sdk-naming-conventions/SKILL.md)** — `_` vs
  `$` prefixes, strict default visibility, boolean naming, no redundant
  `async`.
- **[sdk-file-section-order](sdk-file-section-order/SKILL.md)** — the
  fixed, numbered section order enforced on every structure and manager
  file, with empty slots marked rather than omitted.

These two are usually applied together while writing any single file, but
answer different questions — naming/visibility (what to call something and
who can see it) versus layout (where it goes in the file) — so they're
kept separate rather than one large "style" skill.
