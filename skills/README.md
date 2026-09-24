# skills/

Every leaf directory here is one skill: `<skill-name>/SKILL.md`. Most are
grouped into domain folders ([`api/`](api/README.md),
[`sdk/`](sdk/README.md), [`git/`](git/README.md), [`docs/`](docs/README.md))
purely for navigation inside this repo — grouping has no effect on how a
skill gets reused elsewhere, since reuse always symlinks one leaf skill
directory by name (see
[Using this in another project](../README.md#using-this-in-another-project)
in the root README), regardless of how deep it lives in this source tree.
A skill with no obvious domain yet (only one of its kind so far) sits
directly under `skills/` — see [Growth](../CONCEPT.md#growth) in CONCEPT.md.

Start a new skill from [`../templates/SKILL.md`](../templates/SKILL.md) —
see the root [README.md](../README.md) and [CONCEPT.md](../CONCEPT.md) for
the format, the length/verbosity expectations, and how a skill links into
another project.

## Domains

- **[api/](api/README.md)** — backend API style: framework/library choices,
  file-based routing, and the declarative manager pattern for business
  logic. 7 skills across `stack/`, `routing/`, and `managers/`.
- **[sdk/](sdk/README.md)** — client SDK style: generated-client stack, the
  structure/manager/sub-manager layering, naming and file-layout
  conventions. 6 skills across `stack/`, `managers/`, and `conventions/`.
- **[git/](git/README.md)** — when a commit should happen and how it's
  worded. 2 skills.
- **[docs/](docs/README.md)** — how to write the documents around code:
  planning specs, agent/team handoffs, roadmap notes, migration-status
  tracking, informal-to-formal guideline writeups. 5 skills.
- **[website/](website/README.md)** — how websites get built, split by
  framework and by site kind: currently `nextjs/`, covering both a
  thin-client dashboard over an external SDK (`dashboard`) and a full-stack
  app that owns its own backend via Prisma + Server Actions (`fullstack`).
  9 skills.

**Ungrouped** (one of a kind so far, not yet worth a domain folder):

- **[same-import-upgrade-path](same-import-upgrade-path/SKILL.md)** — shape
  a deliberately minimal implementation's public API like the known "real"
  backing you'll swap in later, so the upgrade is a same-import swap.

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
| [sdk-client-stack](sdk/stack/sdk-client-stack/SKILL.md) | sdk / stack | tooling |
| [sdk-manager-layers](sdk/managers/sdk-manager-layers/SKILL.md) | sdk / managers | architecture |
| [sdk-resolvable-ids](sdk/managers/sdk-resolvable-ids/SKILL.md) | sdk / managers | architecture |
| [sdk-cache-update-placement](sdk/managers/sdk-cache-update-placement/SKILL.md) | sdk / managers | architecture |
| [sdk-naming-conventions](sdk/conventions/sdk-naming-conventions/SKILL.md) | sdk / conventions | architecture |
| [sdk-file-section-order](sdk/conventions/sdk-file-section-order/SKILL.md) | sdk / conventions | architecture |
| [git-commit-requires-approval](git/git-commit-requires-approval/SKILL.md) | git | ai-collaboration |
| [git-commit-messages](git/git-commit-messages/SKILL.md) | git | git |
| [docs-feature-planning-spec](docs/docs-feature-planning-spec/SKILL.md) | docs | documentation |
| [docs-agent-handoff-spec](docs/docs-agent-handoff-spec/SKILL.md) | docs | documentation |
| [docs-roadmap-notes](docs/docs-roadmap-notes/SKILL.md) | docs | documentation |
| [docs-migration-status-tracking](docs/docs-migration-status-tracking/SKILL.md) | docs | documentation |
| [docs-informal-to-formal-guidelines](docs/docs-informal-to-formal-guidelines/SKILL.md) | docs | documentation |
| [website-nextjs-dashboard-stack](website/nextjs/website-nextjs-dashboard-stack/SKILL.md) | website / nextjs | tooling |
| [website-nextjs-dashboard-project-structure](website/nextjs/website-nextjs-dashboard-project-structure/SKILL.md) | website / nextjs | architecture |
| [website-nextjs-dashboard-route-organization](website/nextjs/website-nextjs-dashboard-route-organization/SKILL.md) | website / nextjs | architecture |
| [website-nextjs-dashboard-forms](website/nextjs/website-nextjs-dashboard-forms/SKILL.md) | website / nextjs | architecture |
| [website-nextjs-fullstack-layered-architecture](website/nextjs/website-nextjs-fullstack-layered-architecture/SKILL.md) | website / nextjs | architecture |
| [website-nextjs-fullstack-server-actions](website/nextjs/website-nextjs-fullstack-server-actions/SKILL.md) | website / nextjs | architecture |
| [website-nextjs-fullstack-rbac](website/nextjs/website-nextjs-fullstack-rbac/SKILL.md) | website / nextjs | architecture |
| [website-nextjs-fullstack-list-page-pattern](website/nextjs/website-nextjs-fullstack-list-page-pattern/SKILL.md) | website / nextjs | architecture |
| [website-nextjs-fullstack-soft-delete-lifecycle](website/nextjs/website-nextjs-fullstack-soft-delete-lifecycle/SKILL.md) | website / nextjs | architecture |
| [same-import-upgrade-path](same-import-upgrade-path/SKILL.md) | (ungrouped) | architecture |

(This file is named `README.md`, not `SKILL.md`, on purpose — so it isn't
picked up as a skill itself if this whole directory gets symlinked in. Same
goes for every other `README.md` under `skills/`.)
