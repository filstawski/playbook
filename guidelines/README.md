# guidelines/

Short, enforceable rules, grouped into the playbook's categories. Where
`skills/` holds deep, invocable procedures and patterns with full code,
`guidelines/` holds the rules an agent should know before touching a
project. Most entries come out of the user's corrections and decisions. The
navigation and reading order are in [INDEX.md](../INDEX.md).

| # | Category | Folder |
| --- | --- | --- |
| 1 | UI/UX | [ui-ux/](ui-ux/README.md) |
| 2 | Design guidelines | [design-guidelines/](design-guidelines/README.md) |
| 3 | Frontend | [frontend/](frontend/README.md) |
| 4 | Backend | [backend/](backend/README.md) |
| 5 | Stacks | [stacks/](stacks/README.md) |
| 6 | APIs | [apis/](apis/README.md) |
| 7 | External services | [external-services/](external-services/README.md) |
| 8 | GitHub | [github/](github/README.md) |
| 9 | Version control | [version-control/](version-control/README.md) |
| 10 | CI/CD | [ci-cd/](ci-cd/README.md) |
| 11 | Deployment | [deployment/](deployment/README.md) |
| 12 | Skills | [../skills/README.md](../skills/README.md) |
| — | Uncategorized (flagged) | [uncategorized/](uncategorized/README.md) |

## Entry format

Every entry follows [templates/GUIDELINE.md](../templates/GUIDELINE.md):

- **A short imperative title.**
- **A metadata line:** strength, date, and a generic project type.
  - `MUST` is a hard rule (stated as always/never, a firm correction, or
    repeated).
  - `SHOULD` is the default.
  - `CONSIDER` is situational.
  - The project type is generic ("dashboard app", "client site"), never a
    name; this repository is public.
- **The rule.** Then **Why**, an example where it helps, **Changed** when
  the preference moved over time (the newest wins), and **See also**.

## Folder conventions

- Category folders hold kebab-case topic files without a domain prefix.
  They are never symlinked flat like skills, so the prefix rule in
  [CONCEPT.md](../CONCEPT.md#naming) doesn't apply.
- When a skill covers a topic in depth, the guideline entry is a short rule
  that links to it rather than repeating it.
- Rules that fit no category go into `uncategorized/`, flagged, instead of
  being forced into one.
