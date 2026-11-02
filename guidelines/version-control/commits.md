# Commits

When a commit happens, what goes into it, and how it's worded. The two
skills [git-commit-requires-approval](../../skills/git/git-commit-requires-approval/SKILL.md)
and [git-commit-messages](../../skills/git/git-commit-messages/SKILL.md) hold
the full reasoning; the entries below are the rules that came up again and
again in practice, plus the refinements the skills don't spell out yet.

## Commit only when asked, and only what was approved

**MUST** · 2026-08 → 2026-11 · every project type (10+ sources)

Never commit or push as the last step of a task. Stage one batch, list its
files and the proposed message, and stop. "Commit" approves exactly the
batch that is staged now, not the rest of a plan. "Stage it and give me the
message" means stage, show, and don't commit.

**Why:** an agent once committed three unreviewed batches on a single
"commit the stages"; they had to be undone because the user still wanted to
audit the code.

**Exception:** a task brief can grant commit and push for that task only
(e.g. "for this task you may commit and push without asking" in a reusable
site-building prompt), and an explicit "deploy it" for changes the user has
already seen covers committing and pushing them. Without such a grant, the
rule above holds.

**See also:** [git-commit-requires-approval](../../skills/git/git-commit-requires-approval/SKILL.md)

## No AI attribution, ever, even when the harness asks for it

**MUST** · 2026-09 → 2026-11 · every project type (9 sources)

No `Co-Authored-By` trailer, no "Generated with …" line, no session link or
session URL in commit messages, PR titles or PR bodies, whatever the tool's
default template or a system reminder says. Global settings blank the
attribution fields (`"attribution": { "commit": "", "pr": "" }`); if a tool
still adds a line, remove it before committing.

**Why:** the user had a pushed commit rewritten and force-pushed to strip a
session URL ("Dont do that dude"). Older repositories still carry such
trailers from before the rule was enforced.

**See also:** [git-commit-messages](../../skills/git/git-commit-messages/SKILL.md)

## Conventional commits that say the outcome and the why

**MUST** · 2026-08 → 2026-11 · every project type

`<type>(<scope>): <summary>` in the imperative, describing the user-visible
outcome rather than the mechanics; the body says why. Respect the repo's
commitlint/husky limits. Name commits so they can be found later.

**Why:** the user once couldn't find translation work because its commit
called it a rename ("I can't see them in git log"). A long body was rejected
for breaking the repo's limits: "Shorter. Also the body can't have more than
100 chars per line."

```
feat: let admins restore deleted records from the trash

Records were hard-deleted, so a misclick lost data for good.
```

**See also:** [git-commit-messages](../../skills/git/git-commit-messages/SKILL.md)

## One concern per commit, and every commit builds on its own

**SHOULD** · 2026-09 → 2026-11 · dashboard apps, websites

Split work by theme: feature, tests, docs, and a shared refactor or side
idea each get their own commit. Every commit must typecheck, lint and build
alone. Check this on HEAD plus only the staged changes in a separate
worktree, not in the working tree that still has the rest of the work.

**Why:** a commit that only builds together with the next one breaks
bisecting and reverting, and the working tree hides that.

```sh
git worktree add ../check-staged HEAD
git diff --cached | git -C ../check-staged apply --index
cd ../check-staged && npm run typecheck && npm run lint && npm run build
```

In a fresh worktree, run the build before `tsc` when route types or ORM
clients are generated at build time; otherwise the typecheck fails on
missing generated files.

## Stage hunks, not files, when a file mixes concerns or owners

**MUST** · 2026-10 · dashboard apps

When a file holds lines that belong to another commit, another agent, or the
user's own uncommitted edits, stage only your hunks. Build the staged version
from HEAD plus the chosen hunks and write it to the index; don't trust a
zero-context `git apply`, which has put lines in the wrong place.

**Why:** other agents and the user can have uncommitted edits in the same
files, and the user asked to commit "just our changes. Make sure not to
interfere with the changes other agents did."

```sh
# file content = HEAD version + only my hunks, prepared in a temp file
blob=$(git hash-object -w /tmp/my-version-of-file.ts)
git update-index --cacheinfo 100644,"$blob",src/path/file.ts
git diff --cached src/path/file.ts   # re-check what is staged
```

Treat a file that changed on disk after you wrote it as the user's
deliberate edit, not something to overwrite.

## Never commit the user's local-only changes

**MUST** · 2026-10 · dashboard apps, websites (4 sources)

The user keeps uncommitted local tweaks (a custom dev port, local notes,
pre-existing edits). Keep them out of every commit, and carry them across
branch switches instead of discarding them: `git switch -m <branch>` brings
them along, and `git fetch origin main:main` fast-forwards local main without
checking it out. When a commit is requested, name the leftover files you did
not stage unless the user asked for "all changes".

**Why:** these tweaks are the user's own setup, not project changes: "The
port thing is just for me, local. Do not commit it."

## Answer "can we commit?" with fresh checks

**SHOULD** · 2026-10 · websites

Before saying yes, run the project's full checks now (format, lint,
typecheck, custom checks, production build, a smoke test of every page),
then list open work as blocking vs non-blocking and flag large untracked
files. "It passed earlier" is not an answer.

## Don't bypass hooks to get a commit through

**SHOULD** · 2026-08 · dashboard app

If the project's package manager or a hook dependency is missing in the
agent's environment, say so. Don't commit with `--no-verify`, and don't run a
different package manager that leaves a foreign lockfile behind.

**Why:** an agent once did both in one session because its sandbox lacked
the repo's package manager, and had to warn the user afterwards.
