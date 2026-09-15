# git

How commits get made: what triggers one, and how it's worded.

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
