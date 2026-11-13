# Open questions

No questions are open right now. New ones go at the top of this file, each
with its evidence and a leaning, and stay out of the guidelines and skills
as rules until they are decided.

## Decided 2026-11-13

From comparing website-motion with an outside motion and UX-laws skill
(charles-ux-animation). Each decision is written into the file named after
it.

| # | Question | Decision | Written into |
| --- | --- | --- | --- |
| 27 | Add established laws of UX to the guidelines? | Yes, marked "established UX law", at most SHOULD; the user's own rules win. | [CONCEPT](CONCEPT.md), [template](templates/GUIDELINE.md), [forms](guidelines/ui-ux/forms.md), [feedback-and-states](guidelines/ui-ux/feedback-and-states.md), [interaction](guidelines/ui-ux/interaction.md), [layout-and-typography](guidelines/design-guidelines/layout-and-typography.md) |
| 28 | When are form fields checked? | When a field is left, then live once it shows an error (`onTouched`), instead of on every keystroke from the start. | [forms](guidelines/ui-ux/forms.md), [dashboard-forms](skills/website/nextjs/website-nextjs-dashboard-forms/SKILL.md) |
| 29 | Should the selection mark jump instantly for keyboard moves? | No: it slides "a lot faster" for keyboard moves, with no overshoot; a held-down key places it at once. | [website-motion](skills/website/website-motion/SKILL.md) (P4) |
| 30 | Arcs for cards moving on both axes? | "Slightly": 8% of the distance, at most 32 px; single-axis moves stay straight. | [website-motion](skills/website/website-motion/patterns.md) (P5) |
| 31 | Shake the wrong field on a failed submit? | "Yes, shake it slightly": a few pixels, once, on submit only. | [forms](guidelines/ui-ux/forms.md), [website-motion](skills/website/website-motion/patterns.md) (P2) |

The values for 29–31 and the new toast pattern (P15) are starting points,
still to be tuned on a lab page.

## Decided 2026-11-03

All 26 questions from the 2026-11 consolidation, decided by the user. Each
decision is written into the file named after it.

### Workflow and git

| # | Question | Decision | Written into |
| --- | --- | --- | --- |
| 1 | Bring an open PR branch up to date: rebase or merge main? | Merge main in; never rebase and force-push a branch with an open PR. Rebase only branches nobody has seen. | [branches-and-history](guidelines/version-control/branches-and-history.md) |
| 2 | Commit a deploy-blocking fix without asking? | No: still ask, and say why it blocks. | [commits](guidelines/version-control/commits.md) |
| 3 | How long does a delegated release path ("commit, push and do the tag stuff") last? | Only that release; the next one needs a new go. | [git-pull-requests](skills/git/git-pull-requests/SKILL.md) |
| 4 | Straight to main on solo prototypes? | Follow each repo's established flow. | [branches-and-history](guidelines/version-control/branches-and-history.md) |
| 5 | Keep backups of work the user rejected? | No: a discard means gone. Back up only before risky changes. | [branches-and-history](guidelines/version-control/branches-and-history.md) |
| 6 | How are toned-down versions and design variants kept? | As local snapshot refs; pushed to a branch only when asked; no automatic commits. | [restraint-and-character](guidelines/design-guidelines/restraint-and-character.md) |

### Design and motion

| # | Question | Decision | Written into |
| --- | --- | --- | --- |
| 7 | CSS vs the motion library | CSS transitions with the shared springs for swaps, overlays and hovers; `motion` for layout, presence and physics. | [website-motion](skills/website/website-motion/SKILL.md) |
| 8 | Bounce on client sites | The site profile's springs, tuned per business; the template's no-bounce tweens are replaced. | [website-motion](skills/website/website-motion/SKILL.md) |
| 9 | Scroll reveals, parallax, magnetic buttons, count-ups | "They are fine when they fit the UI": no blanket bans, under the motion rules. | [website-motion](skills/website/website-motion/SKILL.md) |
| 10 | Where continuous motion may run | Only where asked, on chrome and AI surfaces, never on content objects. | [restraint-and-character](guidelines/design-guidelines/restraint-and-character.md) |
| 11 | Ambient effects: subtle or visible? | Clearly visible but few; interactive feedback starts subtle. | [website-motion](skills/website/website-motion/SKILL.md) |
| 12 | Sound effects in apps | Keep the concept written down and unbuilt until asked. | [feedback-and-states](guidelines/ui-ux/feedback-and-states.md) |
| 13 | Selection mark | The `layoutId` indicator by default; the liquid bead only where asked. | [website-motion](skills/website/website-motion/SKILL.md) |

### Websites, SEO and copy

| # | Question | Decision | Written into |
| --- | --- | --- | --- |
| 14 | Analytics on public sites | Not by default; only when the user asks for it on that site. | [monitoring-and-analytics](guidelines/external-services/monitoring-and-analytics.md), [websites](guidelines/frontend/websites.md) |
| 15 | Title order | Query-first everywhere; the home title may lead with the business name. | [marketing-seo-audit](skills/marketing/marketing-seo-audit/SKILL.md) |
| 16 | Service URL shape | Top-level `/<service>`. | [marketing-seo-audit](skills/marketing/marketing-seo-audit/SKILL.md), [site setup](skills/website/nextjs/website-nextjs-site-setup/SKILL.md) |
| 17 | Back-port the newest site's additions to the template? | Yes, and improvements flow back into the template as a rule. | [websites](guidelines/frontend/websites.md) |
| 18 | Template SEO standard | All four: typed JSON-LD with breadcrumbs and services, sitemap `lastModified` from content, a share image per page, `llms.txt` and `security.txt`. | [site setup](skills/website/nextjs/website-nextjs-site-setup/SKILL.md) |
| 19 | Production hosting for client sites | Decided per client, in the site's concept. | [site setup](skills/website/nextjs/website-nextjs-site-setup/SKILL.md), [deploy-docker-compose-vps](skills/deploy/deploy-docker-compose-vps/SKILL.md) |
| 20 | When a site gets a server-side form | Decided in the concept; attachments are the usual trigger. | [web-stack](guidelines/stacks/web-stack.md) |
| 21 | Showcase internal projects before client references? | No. | [client-work](guidelines/uncategorized/client-work.md) |

### Stack and structure

| # | Question | Decision | Written into |
| --- | --- | --- | --- |
| 22 | Two weeks for hand-picked security fixes | A standing rule. | [dependencies-and-lockfiles](guidelines/ci-cd/dependencies-and-lockfiles.md), [choosing-dependencies](guidelines/stacks/choosing-dependencies.md) |
| 23 | The September dashboard skills | `project-structure` revised for the `components/ui` placement rule; `dashboard-stack` kept as the thin-client variant. | [project-structure](skills/website/nextjs/website-nextjs-dashboard-project-structure/SKILL.md), [dashboard-stack](skills/website/nextjs/website-nextjs-dashboard-stack/SKILL.md) |
| 24 | New categories | "Working with agents" became category 13; "Client work" stays uncategorized for now. | [working-with-agents](guidelines/working-with-agents/README.md) |
| 25 | Install instructions | The skills CLI first, symlinks as an alternative. | [README](README.md) |
| 26 | Project name in the older SDK skills' examples | Leave it as it is. | — |

## Resolved earlier by recency (newest source wins)

- **UI text:** label modules, not inline.
- **Placeholders:** a bare example, no "e.g." prefix; selects show the
  action.
- **Input focus:** brand accent, unless the brand is red (then neutral).
- **Visual verification:** agents verify before reporting (since October),
  never on the user's dev server; this replaces August's "I'll verify
  myself".
- **Answer length:** short, plain, next step first (Oct 30), replacing
  "explain more" (Oct 6).
- **Stacked PRs:** serial by default; all at once against main on request.
- **Previews:** Deployer replaced the GitHub-Pages-based tool on 2026-10-12.
- **The liquid-glass design language** is outdated and not used.
- **Scope selectors vs permission pages:** within-page scope selectors fall
  back to "mine"; pages the viewer can't open show an explicit "no
  permission" page.
