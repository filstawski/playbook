# Branches and history

Where work lives before it reaches main, how branches stay current, and what
never happens to history that's already pushed. Pull requests themselves are
in [../github/pull-requests.md](../github/pull-requests.md).

## Neutral changes go to main; feature branches hold only feature work

**MUST** · 2026-09 · dashboard app

Put feature work on `feat/<name>`, branched from main. Changes every branch
needs (fixes, shared primitives, global renames, translations, tooling and
skill setup) go to main first, so every branch inherits them instead of
each carrying its own copy. In a repo where everything goes through PRs,
that means their own small PR off main.

**Why:** the user had to ask twice for shared changes made on a feature
branch to be moved to main, which is where they expected them in the first
place.

## Follow the repo's own integration flow

**SHOULD** · 2026-10 · prototypes, bots

Look at how the last changes landed. If they came through PRs, commit on a
branch, push, and offer a PR; if the history goes straight to main (a solo
prototype), commit there. Say which one you did and why.

**Why:** on a solo prototype with a linear history, the agent pushed a
feature branch and the user didn't want the PR overhead: "just push it to
main, I don't care, and delete the created branch."

## Never rewrite pushed history; merge main in

**MUST** · 2026-10 · dashboard apps (3 sources)

Resolve conflicts by merging main into the branch, and add fix commits
instead of amending. Rewriting a pushed branch is only for removing a secret
or an unwanted attribution line, or when the user explicitly asks, and then
with `--force-with-lease`. Never rewrite history in a repo that an external
editor or tool syncs from.

```sh
# do
git fetch origin && git merge origin/main
# don't, on a branch with an open PR
git rebase origin/main && git push --force
```

**Changed:** in one late session (2026-11) open PR branches were rebased
during a large parallel batch and the user didn't object. That has not been
confirmed as a new rule; see [OPEN_QUESTIONS.md](../../OPEN_QUESTIONS.md).
Until it is, rebase only branches that nobody else has seen.

## Keep both sides of parallel additions

**SHOULD** · 2026-10 → 2026-11 · dashboard app

Most conflicts between parallel PRs are two rows added at the same spot (a
docs table, a "last updated" line, an index). Keep both entries. When two open
PRs will conflict, merge them together in a scratch worktree and run the full
checks on the combination before the first one merges. After resolving,
search the branch for leftover conflict markers before pushing.

**Why:** nearly every merge between parallel PRs conflicted only on a shared
"Last updated" line. Once a scripted check failed but the commit still ran,
and a merge commit with conflict markers was briefly pushed.

```sh
git grep -nE '^(<<<<<<<|=======|>>>>>>>)( |$)' && echo "markers left"
```

## Back up before a risky change

**SHOULD** · 2026-10 · dashboard app

Before a big refactor, tag the current state (`pre-<area>-refactor`). If the
work must stay uncommitted, store a snapshot of the working tree as a hidden
ref that's on no branch. Back up anything you are about to drop.

```sh
git tag pre-forms-refactor
# snapshot of uncommitted work without touching the index or branches
git update-ref refs/snapshots/forms-wip "$(git stash create)"
```

## After a merge on GitHub, clean up locally

**SHOULD** · 2026-10 · dashboard app

A merge on GitHub doesn't move the local checkout. Switch back to main, pull,
delete the merged branch locally and remotely, and leave the working tree
clean, so the next task doesn't start on a stale branch.
