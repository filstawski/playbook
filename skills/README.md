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
  framework and by site kind: currently `nextjs/`, covering a thin-client
  dashboard over an external SDK (`dashboard`), a full-stack app that owns
  its own backend via Prisma + Server Actions (`fullstack`), and static
  marketing sites (`site`). Also `website-motion`, which applies to all of
  them. 11 skills.
- **[design/](design/README.md)** — how interfaces should look and feel:
  the visual direction and how to find it, and the detail pass. 2 skills.
- **[marketing/](marketing/README.md)** — copy and search visibility for
  public sites. 2 skills.
- **[deploy/](deploy/README.md)** — previews on Deployer, and production on
  a VPS with Docker Compose. 2 skills.

The `git/` domain gained `git-pull-requests` (now 3 skills).

**Ungrouped** (one of a kind so far, not yet worth a domain folder):

- **[same-import-upgrade-path](same-import-upgrade-path/SKILL.md)** — shape
  a deliberately minimal implementation's public API like the known "real"
  backing you'll swap in later, so the upgrade is a same-import swap.
- **[extract-reusable-primitives](extract-reusable-primitives/SKILL.md)** —
  hunt for reusable practices — near-duplicate
  functions/methods/classes/hooks/components, repeated parameter
  bundles, general mechanics later work will need — and extract one
  properly designed primitive so future call sites and future fixes go
  through a single place. Write-time and polish.
- **[code-polish](code-polish/SKILL.md)** — pre-commit cleanup of the
  current diff: strip iteration debris, replace symptom patches with the
  root-cause fix, then clean, document, and verify — behavior-preserving,
  scoped to the change, never commits.

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
| [git-pull-requests](git/git-pull-requests/SKILL.md) | git | git |
| [website-nextjs-site-setup](website/nextjs/website-nextjs-site-setup/SKILL.md) | website / nextjs | architecture |
| [website-motion](website/website-motion/SKILL.md) | website | frontend |
| [design-taste](design/design-taste/SKILL.md) | design | design |
| [design-interface-polish](design/design-interface-polish/SKILL.md) | design | design |
| [marketing-copywriting](marketing/marketing-copywriting/SKILL.md) | marketing | marketing |
| [marketing-seo-audit](marketing/marketing-seo-audit/SKILL.md) | marketing | marketing |
| [deploy-preview-with-deployer](deploy/deploy-preview-with-deployer/SKILL.md) | deploy | deployment |
| [deploy-docker-compose-vps](deploy/deploy-docker-compose-vps/SKILL.md) | deploy | deployment |
| [same-import-upgrade-path](same-import-upgrade-path/SKILL.md) | (ungrouped) | architecture |
| [extract-reusable-primitives](extract-reusable-primitives/SKILL.md) | (ungrouped) | architecture |
| [code-polish](code-polish/SKILL.md) | (ungrouped) | ai-collaboration |

(This file is named `README.md`, not `SKILL.md`, on purpose — so it isn't
picked up as a skill itself if this whole directory gets symlinked in. Same
goes for every other `README.md` under `skills/`.)

---

## Section 12 of the playbook: skills

This file is section 12 of [INDEX.md](../INDEX.md). The sections below cover
how skills are used and written, and where the skills added in the 2026-11
consolidation came from.

### Installing skills in a project

**MUST** · 2026-09 → 2026-11 · every project type (6 sources)

Every project installs its skills with the `skills` CLI from this repository
(and from upstream sources where noted). They are vendored into the repo and
committed, so every clone and every agent shares the same conventions:

```sh
npx skills add filstawski/playbook --skill code-polish --skill git-commit-messages   # …and the rest
ln -s ../.agents/skills .claude/skills      # once; Claude Code discovers skills here
git add .agents/skills .claude/skills skills-lock.json
npx skills update                           # later: refresh from upstream, recorded in the lock
```

- Skills live in `.agents/skills/` (shared by several agent tools), and
  `.claude/skills` is a symlink to it. `skills-lock.json` records each
  skill's source and hash. Don't fabricate lock entries for locally written
  skills.
- `AGENTS.md` tells agents to read the matching `SKILL.md` before each kind
  of task (committing, polish, forms, file placement, design, motion, ORM).
  `CLAUDE.md` is a one-line `@AGENTS.md`.
- Before reporting "no such skill", look in `.agents/skills/` itself.
- Prettier, ESLint and Docker builds ignore the skills folder.
- A library newer than the model's training data often ships its own skill
  (an ORM's, Deployer's). Install it; it is the source of truth over
  memory.

**Changed:** the [root README](../README.md) originally described symlinking
skills from a local clone. Since September 2026 every project uses the CLI
with a lockfile, as above.

### Typical sets

| Project | Skills |
| --- | --- |
| Marketing / client site | code-polish, extract-reusable-primitives, git-commit-messages, git-commit-requires-approval, git-pull-requests, docs-feature-planning-spec, docs-roadmap-notes, same-import-upgrade-path, design-taste, design-interface-polish, website-motion, marketing-copywriting, marketing-seo-audit, website-nextjs-site-setup |
| Full-stack dashboard | the git, docs and polish skills above, plus website-nextjs-dashboard-project-structure, -route-organization, -forms, the website-nextjs-fullstack-* skills, design-taste, design-interface-polish, website-motion, and the ORM's own skill (`prisma/skills`) |
| Tool or CLI | code-polish, extract-reusable-primitives, the git and docs skills, same-import-upgrade-path; plus the tool's own agent skill if agents should use it |

### Writing skills for this playbook

**MUST** · 2026-09 → 2026-10 · this repository

- **Long and complete.** Playbook skills are long, code-heavy references,
  split into cross-linked files or skills when a topic has independent
  facets (see [CONCEPT.md](../CONCEPT.md#length)). This doesn't apply to an
  app's own short project skills.
- **State the scope.** A skill distilled from one project states what kind
  of project it applies to: in the `description` (which drives
  auto-invocation), as the first Exceptions bullet, and in the domain
  README. RBAC, auth and server-side mutation patterns are never defaults
  for simple sites.
- **Write for a cold agent.** Open with a checklist of physical actions,
  address the competing instinct explicitly ("avoid premature abstraction")
  with a test for which wins, and avoid terms the reader's codebase won't
  use.
- **Confirm before writing.** List the candidate skills and what each will
  and won't cover, and confirm with the user before writing them.
- **Ship a skill with every agent-facing tool,** installable with
  `npx skills add` and printable from the tool itself. A test checks that
  every command it names still exists.
- **Review third-party skills before relying on them.** Is it markdown
  only, or does it bring scripts, hooks or install steps? Does it fetch
  pages? Where does its generic advice clash with decisions already made,
  and which side wins?

### Where the 2026-11 skills came from

| Skill | Built from | Licence |
| --- | --- | --- |
| website-motion | the user's own projects (2 dashboard apps, the company website, the client-site template and sites) | own work |
| website-nextjs-site-setup | the website template, its build prompt, and the client sites built with it | own work |
| git-pull-requests | the user's PR workflow across the dashboard apps and sites | own work |
| deploy-preview-with-deployer | `filstawski/deployer` and the sessions building and using it | own work |
| deploy-docker-compose-vps | the production setup of a dashboard app, its copy, and a hand-run demo | own work |
| design-taste | `design-taste-frontend` + `redesign-existing-projects` (Leonxlnx/taste-skill) + the user's design feedback | MIT, notice in the skill's README |
| design-interface-polish | `make-interfaces-feel-better` (jakubkrehel) + the user's polish corrections | MIT, notice in the skill's README |
| marketing-copywriting | `copywriting` (coreyhaines31/marketingskills) + the user's copy rules | MIT, notice in the skill's README |
| marketing-seo-audit | `seo-audit` (coreyhaines31/marketingskills) + the sites' SEO baseline | MIT, notice in the skill's README |

### Third-party skills deliberately not rebuilt

| Skill | Why not |
| --- | --- |
| `prisma-8` and other `prisma/skills` | a library reference that tracks Prisma releases; keep installing it upstream. The user's Prisma lessons are in [guidelines/backend/](../guidelines/backend/README.md). |
| `impeccable` (pbakaus, Apache-2.0) | rejected by the user in October 2026 ("remove all impeccable references"); never reintroduce it or its artefacts (PRODUCT.md, `.impeccable/`, direction contracts, reviewer hooks) |
| `web-design-guidelines`, `vercel-react-best-practices` (vercel-labs) | no licence file that grants derivative use; barely used |
| minimalist, brutalist, high-end, gpt-taste, Stitch, brandkit, image-to-code, imagegen-*, full-output-enforcement (taste-skill collection) | installed but barely used; the conflicting aesthetic ones were removed with the user's approval |
| `frontend-design`, `webapp-testing` (anthropics/skills) | used once |
| the `liquid-glass-ui` project skill | outdated; the design language is no longer used. Its motion lessons are in `website-motion`. |
| `deployer` (filstawski/deployer) | stays in the Deployer repo, because it has to change with the CLI; `deploy-preview-with-deployer` defers to it |
