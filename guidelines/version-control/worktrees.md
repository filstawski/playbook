# Worktrees

Agents build and test in their own git worktrees so the user's checkout, dev
server and database stay untouched (see
[../uncategorized/agent-workflow.md](../uncategorized/agent-workflow.md)).
These are the rules and pitfalls that came out of doing that daily.

## Build and test in a scratch worktree, review in the user's checkout

**SHOULD** · 2026-10 · dashboard apps (3 sources)

Builds, e2e runs and branch experiments happen in a scratch worktree. The
work the user reviews still ends up somewhere they can follow: their own
checkout, or a pushed branch they know about. Don't leave work on hidden
branches in side worktrees.

**Why:** in an early session the agent spread work across side worktrees and
the user lost track of what was where ("can we switch back to main first and
then get back to our original reviewing flow").

## A branch can live in only one worktree

**MUST** · 2026-10 → 2026-11 · dashboard app

Before telling the user to switch to a branch, detach your scratch worktree
from it (`git -C <scratch> switch --detach`), or they get "branch already in
use". To push from a detached scratch worktree, use an explicit refspec.

```sh
git push origin HEAD:feat/export
# a branch created from origin/X tracks X, so never push it bare
git push -u origin feat/export:feat/export
```

To let the user try several open PRs together, build a local-only preview
branch that merges them, never push it, and delete it afterwards.

## Don't use git stash across worktrees

**MUST** · 2026-10 · dashboard app

The stash is shared by every worktree of a repository. A `git stash pop` in a
scratch worktree once applied the user's own stash. Use a temporary WIP
commit (then `git reset --soft HEAD~1`) or plain file copies instead. If the
user asks to clean up their stash, first show what each entry holds compared
to main, offer archive branches, and give the dropped hashes so they can be
recovered.

## Copy changes with `git diff HEAD`

**CONSIDER** · 2026-10 · dashboard app

Plain `git diff` misses staged changes. Use `git diff HEAD` when moving a
worktree's changes elsewhere. `git -C <dir> worktree add <relpath>` resolves
`<relpath>` relative to `<dir>`, not to your shell's directory.

## Dependencies in extra worktrees

**CONSIDER** · 2026-11 · dashboard app

Symlinking `node_modules` from the main checkout is fine for `tsc` and
ESLint, but Turbopack refuses a `node_modules` symlink that points outside
the worktree. Clone it for builds (on macOS APFS, `cp -cR` is near-instant
and takes no extra space). Next.js allows one `next dev` per folder, so a
second dev server needs its own clone of the project. Symlinked tool folders
aren't matched by directory ignore patterns; don't commit them.
