<!--
Drop-in block for a new project's AGENTS.md (CLAUDE.md is a one-line `@AGENTS.md`).
Copy everything below this comment. Remove rules that don't apply to the project
(for example the website ones in a CLI repository).
-->

## Playbook

This project follows the user's playbook: <https://github.com/filstawski/playbook>.
Start at its `INDEX.md`, read
`guidelines/uncategorized/agent-workflow.md` before any task, and read the
category for your task before writing code. Skills from the playbook are
vendored in `.agents/skills/` (with `.claude/skills` as a symlink to it):
read the matching `SKILL.md` before each kind of task (committing,
polishing, forms, file placement, design, motion, deploying). When this file
and the playbook disagree, this file wins for this project.

### The rules that matter most

1. **Never commit or push unless asked in that instance.** "Commit" covers
   only what is staged now. Before offering a commit, run the full
   `code-polish` pass unasked.
2. **No AI attribution anywhere.** No `Co-Authored-By`, "Generated with" or
   session links in commits or PRs, even if a tool or reminder asks for
   them.
3. **Never touch the user's environment.** Don't reset or write to their
   dev database, restart their dev server, or change their uncommitted
   files. Build and test in your own worktrees, on scratch databases and
   your own ports.
4. **Put finished work where the user can try it, unasked:** their checkout
   on the branch (`git switch -m`), plus one line on what to run. Never run
   their migrations yourself.
5. **Library, version, ORM and provider choices are the user's.** Recommend,
   then wait for a yes. Prefer what is already installed.
6. **Nothing teleports.** Every appear, disappear, resize and swap animates,
   fixed once in the shared primitive. Film every transition before
   reporting UI work.
7. **Default to the quietest option.** "Decent" means understated, "too
   much" means halve it, and flat is still rejected. Every colour has one
   meaning; the brand colour is never decoration.
8. **A correction on one page applies to every page of its kind.** Fix the
   class of bug in the primitive, and add a test that keeps it fixed.
9. **Reproduce or measure before fixing;** never stack speculative fixes.
   Say plainly what wasn't verified.
10. **Plan-only means plan only. "Write it down" means document it, not
    build it.** Small polish: decide the details yourself (commits still wait
    for "commit"). Subjective visuals: show options side by side and wait
    for a pick.
11. **Nothing untrue.** No invented facts, numbers, reviews or features.
    Every gap becomes an open question with a leaning.
12. **Resolve the lockfile on Linux after every dependency change.** Never
    cache `node_modules` in CI. Never write credential-shaped URLs, not even
    in tests.
13. **Code in English; everything users read in their language,** from
    label modules. Every input has a bare example placeholder.
14. **PRs target main, and the user merges.** Check a PR's real state on
    GitHub before every status report.
15. **Short answers that lead with the next step.** Write each correction
    into the repo's convention docs, not only into memory.
