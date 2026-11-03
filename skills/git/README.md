# git

How commits get made: what triggers one and how it's worded. Then how a
change travels to main through a pull request.

- **[git-commit-requires-approval](git-commit-requires-approval/SKILL.md)**
  — start here. Whether a commit should happen at all: never automatically,
  only on explicit request, human review comes first.
- **[git-commit-messages](git-commit-messages/SKILL.md)** — once a commit
  is actually happening, the format: conventional-commit type prefix,
  imperative summary, why-not-what body, no AI attribution/watermark
  lines.

These two are deliberately separate: one is a permission gate (should this
commit happen), the other is a formatting convention (given that it's
happening, how is it worded). Conflating them tends to produce either an
agent that argues about wording when it should be asking permission, or
one that asks permission for wording it should just get right by default.

- **[git-pull-requests](git-pull-requests/SKILL.md)** — once commits exist
  and a PR is wanted: one concern per PR, the five-part template, stacked
  PRs always against main, CI watched and the "green" box ticked honestly,
  the PR's real state checked before every report, and cleanup after the
  user merges. Added in the 2026-11 consolidation.

The short-form rules for commits, branches, worktrees and PRs are in
[guidelines/version-control/](../../guidelines/version-control/README.md)
and [guidelines/github/](../../guidelines/github/README.md).
