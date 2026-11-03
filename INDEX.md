# Index

The map of this playbook for agents and for the user. The playbook holds
project-agnostic rules (`guidelines/`) and invocable skills (`skills/`)
distilled from real projects. Nothing in it is specific to one project.

## Read first, whatever the task

1. [guidelines/working-with-agents/agent-workflow.md](guidelines/working-with-agents/agent-workflow.md)
   — how to work with the user. Never touch their dev environment, put
   finished work where they can try it, ask vs act, short answers, verify
   yourself.
2. [guidelines/version-control/commits.md](guidelines/version-control/commits.md)
   — commit only when asked, never with AI attribution.
3. The category for your task (below), then the skill it points to.

If you only have a minute, the top rules are in
[snippets/AGENTS.md](snippets/AGENTS.md); that file is also the block to
drop into a new project's `AGENTS.md`.

## By category

| # | Category | Start with | Main skills |
| --- | --- | --- | --- |
| 1 | [UI/UX](guidelines/ui-ux/README.md) | [feedback-and-states](guidelines/ui-ux/feedback-and-states.md), [forms](guidelines/ui-ux/forms.md) | [website-motion](skills/website/website-motion/SKILL.md) |
| 2 | [Design guidelines](guidelines/design-guidelines/README.md) | [restraint-and-character](guidelines/design-guidelines/restraint-and-character.md), [color](guidelines/design-guidelines/color.md) | [design-taste](skills/design/design-taste/SKILL.md), [design-interface-polish](skills/design/design-interface-polish/SKILL.md) |
| 3 | [Frontend](guidelines/frontend/README.md) | [components](guidelines/frontend/components.md), [nextjs-and-react](guidelines/frontend/nextjs-and-react.md) | [website-nextjs-*](skills/website/nextjs/README.md), [extract-reusable-primitives](skills/extract-reusable-primitives/SKILL.md) |
| 4 | [Backend](guidelines/backend/README.md) | [architecture](guidelines/backend/architecture.md), [auth-and-permissions](guidelines/backend/auth-and-permissions.md) | [website-nextjs-fullstack-*](skills/website/nextjs/README.md), [api/*](skills/api/README.md) |
| 5 | [Stacks](guidelines/stacks/README.md) | [choosing-dependencies](guidelines/stacks/choosing-dependencies.md), [web-stack](guidelines/stacks/web-stack.md) | [website-nextjs-dashboard-stack](skills/website/nextjs/website-nextjs-dashboard-stack/SKILL.md), [api-framework-stack](skills/api/stack/api-framework-stack/SKILL.md) |
| 6 | [APIs](guidelines/apis/README.md) | [design](guidelines/apis/design.md) | [api/*](skills/api/README.md), [sdk/*](skills/sdk/README.md) |
| 7 | [External services](guidelines/external-services/README.md) | [email](guidelines/external-services/email.md), [integrations](guidelines/external-services/integrations.md) | — |
| 8 | [GitHub](guidelines/github/README.md) | [pull-requests](guidelines/github/pull-requests.md) | [git-pull-requests](skills/git/git-pull-requests/SKILL.md) |
| 9 | [Version control](guidelines/version-control/README.md) | [commits](guidelines/version-control/commits.md) | [git-commit-requires-approval](skills/git/git-commit-requires-approval/SKILL.md), [git-commit-messages](skills/git/git-commit-messages/SKILL.md) |
| 10 | [CI/CD](guidelines/ci-cd/README.md) | [dependencies-and-lockfiles](guidelines/ci-cd/dependencies-and-lockfiles.md), [pipelines](guidelines/ci-cd/pipelines.md) | [deploy-docker-compose-vps](skills/deploy/deploy-docker-compose-vps/SKILL.md) |
| 11 | [Deployment](guidelines/deployment/README.md) | [deployer](guidelines/deployment/deployer.md), [production-vps](guidelines/deployment/production-vps.md) | [deploy-preview-with-deployer](skills/deploy/deploy-preview-with-deployer/SKILL.md), [deploy-docker-compose-vps](skills/deploy/deploy-docker-compose-vps/SKILL.md) |
| 12 | [Skills](skills/README.md) | how skills are installed and written; where each came from | all of `skills/` |
| 13 | [Working with agents](guidelines/working-with-agents/README.md) | [agent-workflow](guidelines/working-with-agents/agent-workflow.md) | [code-polish](skills/code-polish/SKILL.md), [docs/*](skills/docs/README.md), [git-commit-requires-approval](skills/git/git-commit-requires-approval/SKILL.md) |
| — | [Uncategorized (flagged)](guidelines/uncategorized/README.md) | [client-work](guidelines/uncategorized/client-work.md) | [marketing-copywriting](skills/marketing/marketing-copywriting/SKILL.md) |

## By task

| Task | Read |
| --- | --- |
| Start a new marketing or client site | [website-nextjs-site-setup](skills/website/nextjs/website-nextjs-site-setup/SKILL.md) → [design-taste](skills/design/design-taste/SKILL.md) → [marketing-copywriting](skills/marketing/marketing-copywriting/SKILL.md) → [marketing-seo-audit](skills/marketing/marketing-seo-audit/SKILL.md) |
| Start a full-stack dashboard app | [web-stack](guidelines/stacks/web-stack.md) → [website-nextjs-fullstack-layered-architecture](skills/website/nextjs/website-nextjs-fullstack-layered-architecture/SKILL.md) → [backend/](guidelines/backend/README.md) |
| Build or change UI | [frontend/components](guidelines/frontend/components.md) → [ui-ux/](guidelines/ui-ux/README.md) → [website-motion](skills/website/website-motion/SKILL.md) → [design-interface-polish](skills/design/design-interface-polish/SKILL.md) |
| Plan a feature | [docs-feature-planning-spec](skills/docs/docs-feature-planning-spec/SKILL.md), [agent-workflow § Concept before code](guidelines/working-with-agents/agent-workflow.md) |
| Get a change ready to commit | [code-polish](skills/code-polish/SKILL.md) → [commits](guidelines/version-control/commits.md) → [git-pull-requests](skills/git/git-pull-requests/SKILL.md) |
| Show a branch to the user or a client | [deploy-preview-with-deployer](skills/deploy/deploy-preview-with-deployer/SKILL.md) |
| Set up production | [deploy-docker-compose-vps](skills/deploy/deploy-docker-compose-vps/SKILL.md) |
| Add a dependency | [choosing-dependencies](guidelines/stacks/choosing-dependencies.md) → [dependencies-and-lockfiles](guidelines/ci-cd/dependencies-and-lockfiles.md) |
| Hand work to another agent | [docs-agent-handoff-spec](skills/docs/docs-agent-handoff-spec/SKILL.md) |

## Also here

- [README.md](README.md) and [CONCEPT.md](CONCEPT.md): what this repository
  is and why it's shaped this way.
- [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md): the decision log of the 2026-11
  consolidation, and where new open questions go.
- [templates/](templates/): `SKILL.md` and `GUIDELINE.md`, for new entries.
