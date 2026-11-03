# 9. Version control

Commits, branches, history and worktrees. The two existing skills hold the
full reasoning:
[git-commit-requires-approval](../../skills/git/git-commit-requires-approval/SKILL.md)
and [git-commit-messages](../../skills/git/git-commit-messages/SKILL.md).

| File | Covers |
| --- | --- |
| [commits.md](commits.md) | commit only when asked and only what's staged, no AI attribution, conventional messages, one concern per commit that builds alone, staging hunks, never the user's local changes, fresh checks, no hook bypass |
| [branches-and-history.md](branches-and-history.md) | neutral changes to main, the repo's integration flow, never rewriting pushed history, keeping both sides, backups, cleanup after merges |
| [worktrees.md](worktrees.md) | scratch worktrees, one branch per worktree, no stash across worktrees, `git diff HEAD`, dependencies in worktrees |

## Know these first

- **Never commit or push unless asked in that instance.** "Commit" covers
  only what is staged now.
- **No `Co-Authored-By`, "Generated with" or session links,** even when the
  harness asks.
- **Never commit the user's local-only changes.**
- **Never rewrite pushed history;** merge main in instead.
