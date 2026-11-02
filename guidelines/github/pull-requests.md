# Pull requests

How changes reach main on GitHub. The step-by-step procedure (opening,
stacking, watching CI, retargeting, cleaning up) is the skill
[git-pull-requests](../../skills/git/git-pull-requests/SKILL.md); these are
the rules behind it.

## Everything reaches main through a PR, and the user merges

**MUST** · 2026-10 → 2026-11 · dashboard apps, client apps

The agent pushes the branch and opens the PR; the user reads it and merges.
Merge only with every check green and the PR read. On a free plan nothing
enforces this, so it's an agreement, not a branch rule. The agent merges only
trivial PRs the user has explicitly cleared. If the permission system blocks
a merge, keep the PR open and hand over the link and the exact command;
never merge locally and push to main to get around it.

**Why:** the user sometimes merges with failing load-related e2e jobs ("do
not wait for tests"). That's their call to make, and never a license for the
agent to merge red.

## One PR per concern

**SHOULD** · 2026-10 · dashboard apps

One branch and one PR per feature, step by step. Split design changes from
feature work. An unrelated fix found along the way goes into its own PR off
main, not into the current one. A "write it down for later" request becomes
a docs-only PR.

**Why:** when a session mixed design and feature work, the user asked for it
apart: "commit it and PR it, but separately, since we also had design things
in here."

## Fill the PR template; tick "CI is green" only when it is

**SHOULD** · 2026-10 → 2026-11 · dashboard app

Use a short template with five parts, and keep it in
`.github/pull_request_template.md`:

```md
## Where this fits
<!-- The roadmap item or doc this belongs to, and why it comes now. -->

## What changed
<!-- In plain words: what a user of the app gets, then how it works underneath. -->

## How to try it
<!-- Steps, a route to open, or the test that shows it. -->

## Decisions made
<!-- Anything decided along the way, with the reason. Invites the reviewer to change it. -->

## Checklist
- [ ] CI is green
- [ ] The docs say what the code now does
- [ ] No secrets, customer data or customer pricing in the diff
```

Tick the CI box by editing the body only after every check passed, and
untick it after any new push until the new run is green.

## No screenshots, no attribution, no other clients in PRs

**MUST** · 2026-10 · dashboard apps (5 sources)

Send UI screenshots to the user in chat, never embed them in the PR. No AI
attribution or session links (see [../version-control/commits.md](../version-control/commits.md)).
Branch names, commits, PR titles and bodies never mention other clients or
their projects, even when a design was inspired by one; describe the change
itself. Keep another client's confidential data out of the repo before the
first commit, because history is permanent.

**Why:** `gh` can't upload attachments to a PR, and the workarounds (image
branches, gists) were turned down: "Then screw the screenshot idea. Commit
and PR everything without SS."

## Check the PR's real state before every status report

**MUST** · 2026-10 · dashboard apps, websites (4 sources)

The user merges as soon as they've read a PR, sometimes mid-CI. Before saying
where PRs stand or what's next, look it up:

```sh
git fetch --prune
gh pr view 42 --json state,mergedAt,mergeStateStatus
gh pr list --state all --limit 10
```

**Why:** "is already merged dude, update your memory" — status reports built
on what the agent remembered were wrong more than once.

## Stacked PRs always target main

**MUST** · 2026-10 · dashboard apps (4 sources)

Never leave a PR targeting a parent branch: when the user merges it, the
work lands on the parent and never reaches main ("where is the functionality
we added? I can't see it on main"). By default, open a child PR only after
its parent has merged, against main. When the user asks for everything at
once ("PR all"), open them all against main and state the merge order at the
top of each body; each diff shows its parent's commits until the parent
merges. Merge stacked PRs with merge commits, not squash, so later ones don't
conflict.

**Changed:** the default was strictly one at a time until 2026-10-25, when
the user asked for a whole stack at once. Both now apply: serial by default,
all at once on request.

## Watch CI and report waits concretely

**SHOULD** · 2026-10 · dashboard app

Watch PR checks in the background and report the result. Retry on GitHub 5xx
errors: a 504 once ended a watch early and looked like "done". When the user
asks what you are waiting for, name the job, the runner state and an ETA.
Rerun jobs that failed on infrastructure, and say that's what you did.

**Why:** an unexplained wait left the user asking "Why we still have 2 open
PRs. What are you waiting for?"
