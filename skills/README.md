# skills/

Every leaf directory here is one skill: `<skill-name>/SKILL.md`. They're
grouped into domain folders (currently [`api/`](api/README.md) and
[`git/`](git/README.md)) purely for navigation inside this repo — grouping
has no effect on how a skill gets reused elsewhere, since reuse always
symlinks one leaf skill directory by name (see
[Using this in another project](../README.md#using-this-in-another-project)
in the root README), regardless of how deep it lives in this source tree.

Start a new skill from [`../templates/SKILL.md`](../templates/SKILL.md) —
see the root [README.md](../README.md) and [CONCEPT.md](../CONCEPT.md) for
the format, the length/verbosity expectations, and how a skill links into
another project.

## Domains

- **[api/](api/README.md)** — backend API style: framework/library choices,
  file-based routing, and the declarative manager pattern for business
  logic. 7 skills across `stack/`, `routing/`, and `managers/`.
- **[git/](git/README.md)** — when a commit should happen and how it's
  worded. 2 skills.

(More domains land here as they come up — likely candidates: `testing/`,
`ai-collaboration/`. Each gets its own folder and `README.md` following
the same shape as `api/`.)

## Full index

| Skill | Domain | Category |
| --- | --- | --- |
| [api-framework-stack](api/stack/api-framework-stack/SKILL.md) | api / stack | tooling |
| [api-default-libraries](api/stack/api-default-libraries/SKILL.md) | api / stack | tooling |
| [api-route-structure](api/routing/api-route-structure/SKILL.md) | api / routing | architecture |
| [api-route-procedures](api/routing/api-route-procedures/SKILL.md) | api / routing | architecture |
| [api-manager-base](api/managers/api-manager-base/SKILL.md) | api / managers | architecture |
| [api-manager-declarative-config](api/managers/api-manager-declarative-config/SKILL.md) | api / managers | architecture |
| [api-manager-effects-and-populators](api/managers/api-manager-effects-and-populators/SKILL.md) | api / managers | architecture |
| [git-commit-requires-approval](git/git-commit-requires-approval/SKILL.md) | git | ai-collaboration |
| [git-commit-messages](git/git-commit-messages/SKILL.md) | git | git |

(This file is named `README.md`, not `SKILL.md`, on purpose — so it isn't
picked up as a skill itself if this whole directory gets symlinked in. Same
goes for every other `README.md` under `skills/`.)
