# Repositories, issues and dependency updates

Creating repositories, tracking follow-ups, and keeping dependencies current
on GitHub.

## Create repositories only when asked, private by default

**MUST** · 2026-10 → 2026-11 · websites, client sites (3 sources)

Create a GitHub repository only on an explicit request. When visibility isn't
stated, make it private and say so: internal docs live in the repo, and
making something public can't be undone. Client work goes in the
organization the user keeps for client projects, not in a personal account.

Before the first push:

- `.gitignore` covers `node_modules`, build output and `.env*` (except
  `.env.example`).
- Scan for secrets and for files over ~1 MB.
- Fix docs that still say "no git repository yet".

**Why:** creating a remote repository publishes the code outside the
machine, so the organization, name and visibility are the user's call.

```sh
gh repo create <org>/<name> --private --source=. --remote=origin --push
git ls-remote origin HEAD   # must equal: git rev-parse HEAD
```

## Push through gh's credential helper when git has no login

**CONSIDER** · 2026-10 · several projects

If `git push` fails for lack of credentials but `gh auth status` is fine, use
gh's helper for that one command instead of changing global git config:

```sh
git -c credential.helper='!gh auth git-credential' push origin HEAD
```

## Park follow-ups as GitHub issues with labels

**SHOULD** · 2026-09 → 2026-10 · dashboard apps

When the user says "write that down as an issue" or "later", file it with
`gh`. Use type labels (`bug`, `idea`) and a severity scale
(`severity: critical|high|medium|low`), and create the labels if they're
missing. Check the real scope before filing: what is actually still broken,
the current behavior, and which parts need a decision.

## Dependabot: grouped, with a cooldown and reasoned ignores

**SHOULD** · 2026-10 · dashboard app

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule: { interval: weekly }
    cooldown: { default-days: 7 }        # security updates skip the cooldown
    groups:
      minor-and-patch: { update-types: [minor, patch] }
    ignore:
      # Node: stay on LTS majors only
      - dependency-name: "@types/node"
        update-types: [version-update:semver-major]
  - package-ecosystem: github-actions
    directory: /
    schedule: { interval: weekly }
  - package-ecosystem: docker
    directory: /
    schedule: { interval: weekly }
```

Put the reason next to every ignore rule. Turn on alerts and security-fix
PRs.

**Why:** the cooldown keeps freshly published versions out, and that is
where npm supply-chain attacks land. Grouping turns a normal week into one
or two PRs instead of a dozen. Runtime majors (Node, its types, the Docker
base image) move together as one deliberate step to the next LTS.

## Triage Dependabot PRs by testing, not by trusting the bump

**SHOULD** · 2026-10 · dashboard app

When asked to handle Dependabot PRs:

- Run the full unit, integration and e2e suites per PR, and fix real breakage
  inside the PR. For a parser library, compare its output on saved fixtures
  between versions.
- Close bumps that split packages which must move together, and open one
  paired upgrade instead.
- Merge safe ones with `gh` only when CI is green, and hand PRs that add
  migrations or config to the user.

Outside such an explicit request, version bumps wait for the user's yes.

**Why:** the user wants proof that a bump doesn't break anything: "Test
properly and make sure we don't break our code when changing a version."
