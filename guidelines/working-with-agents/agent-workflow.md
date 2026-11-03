# Working with agents

> **Category 13, added 2026-11-03.** These rules about how agents should
> work with the user are the most repeated rules of all, so they got a
> category of their own. The playbook's existing
> `ai-collaboration` skills ([git-commit-requires-approval](../../skills/git/git-commit-requires-approval/SKILL.md),
> [code-polish](../../skills/code-polish/SKILL.md)) belong to the same theme.

## Never touch the user's own environment

**MUST** · 2026-09 → 2026-11 · dashboard apps, websites (10+ sources)

Never reset or write to the user's development database, never restart or
kill their running dev server, never run builds or e2e suites in their
checkout, and never stage, touch or delete their uncommitted changes or
untracked files. Build and test in your own worktrees, against scratch
database containers and on your own ports. Read-only queries against the
user's database are fine for diagnosing a bug they reported. The one
write to their checkout that is wanted is the handover below.

**Why:** the user keeps a dev server and database running while agents work,
and tries each branch there themselves. A reset or a build in their checkout
breaks what they are looking at.

## Put finished work where the user can try it, unasked

**MUST** · 2026-10 → 2026-11 · dashboard apps (4 sources)

As soon as a feature or fix is built and checked:

- **Hand the branch over.** Detach your scratch worktree, switch the user's
  checkout to the branch with `git switch -m` so their local tweaks come
  along, and install new packages without wiping `node_modules` under the
  running server (then `git checkout -- package-lock.json`, so the
  Linux-resolved lockfile stays as committed).
- **Say what to run.** Tell them in one line what they need to run (migrate,
  restart). Never run their migrations or restart their server yourself.
- **Nothing only local.** Before a break, every branch is pushed and every
  finished piece is in a PR with CI running.

**Why:** "Move it onto my local dev server, I don't know how often I have to
tell you that, but I want to test the feature."

**Changed:** in the first app (Oct 3) work was staged in batches directly in
the user's checkout. From Oct 15, agents built in scratch worktrees and
handed the branch to the user's checkout. The constant: the user's checkout
always shows the work.

## Polish before every "ready to commit", unasked

**MUST** · 2026-10 → 2026-11 · client dashboard app, dashboard app

Before offering a commit, run the whole
[code-polish](../../skills/code-polish/SKILL.md) pass over the final staged
diff, then rebuild and retest that exact tree. Repeat after every feedback
round, and say what the pass changed. "Always apply the polish before
committing. I don't want to ask for that." (The user asked "is it polished?"
about six times in one project.)

## Ask vs act

**MUST** · 2026-08 → 2026-11 · every project type (8 sources)

| Request | Do |
| --- | --- |
| Small, reversible polish | decide the details yourself; when the user has asked for PRs, ship them without questions ("I trust you on those small things") |
| Bigger features | check what's planned, discuss the user's ideas, then build |
| Subjective visuals (new effects, new looks) | show screenshots or recordings of several options and wait for a pick |
| Library, version, provider, product trade-offs | always the user's decision |
| "Plan only", "concept", "ideas" | deliver only that, and wait for approval |
| "Write it down", "for later" | document it (roadmap, open questions); don't build it |
| A question | answer it; don't change code |
| A message that mixes requests and questions | build the requested items, discuss the rest |
| "Don't ask me, I'll be away" | make the calls, list them in the PR description, push for phone review |

Every question carries a recommended option the user can accept as is. Ask
few questions, batched, as multiple choice. For a big ask given in one line
("restructure everything"), build a result and list the decisions you took,
rather than interviewing first. Don't suggest again an idea the user dropped.

**Why:** the user finds questions about small calls to be friction and
decides best by reacting to something concrete. Libraries and versions stay
theirs: an agent once installed an older ORM major over the one they had
chosen, and everything had to be rebuilt.

## Say what you left out

**MUST** · 2026-10 · client dashboard app

If part of what the user asked for, now or earlier in a concept, isn't built
in this step, say so and put it on the roadmap. Never drop it silently. ("I
explicitly told you earlier that I want emails about such stuff. Why haven't
I gotten them?")

## A rule for one page applies to every page of its kind

**MUST** · 2026-10 → 2026-11 · dashboard apps, company website (5 sources)

When the user corrects something on one page, apply it everywhere it occurs
and write the rule down. For a reported bug, find the root cause in the
shared primitive, search the whole app for the same pattern, and add a
permanent test that fails if it comes back. Fix the element the user named,
not its surroundings.

**Why:** a breadcrumb fix applied to one page only made the user repeat
themselves ("I told you multiple times that I don't want it that way").
Dimming the hero's light to make the header readable drew "don't move the
light".

## Reproduce before fixing; stop guessing

**MUST** · 2026-09 → 2026-10 · dashboard apps (3 sources)

Don't change shared code on a hypothesis. Reproduce the bug or measure it,
then make the one root-cause fix. If attempts fail, stop and say so rather
than piling on code ("stop adding dumb code that doesn't fix the issue").
Remove workarounds for problems that were never reproduced.

## Verify yourself, and say what wasn't verified

**MUST** · 2026-10 → 2026-11 · every project type (6 sources)

- **UI work.** Screenshot the affected pages, read the dev console, and film
  every transition (see
  [website-motion](../../skills/website/website-motion/SKILL.md)).
- **Code the user won't read** (a language they don't know): verification
  is entirely yours. Run the full checks, a real end-to-end run, mutation
  checks of new tests, and an independent review agent whose confirmed
  findings get fixed.
- **Reports** say plainly what was and wasn't verified.

**Why:** a view switch once jumped in width and its highlight slid into the
search field, because each view had been checked alone ("How could you have
made this mistake without noticing"). The user doesn't review code in a
language they don't know.

**Changed:** in August the rule was "don't start a dev server or preview;
I'll verify myself". Since October, agents verify visually before reporting,
on their own production build, never on the user's server.

## Short answers that lead with the next step

**SHOULD** · 2026-10 → 2026-11 · every project type (5 sources)

- **Status and "what next".** Give the next one to three steps in plain
  words, and offer the full list instead of printing it.
- **Finished batches.** Orient briefly in sentences, not terse fragments:
  where we are, what changed, how to try it, decisions taken for the user,
  what's next.
- **Long overviews** go into the repo's docs.
- **Tunable effects.** Add a small table of the numbers to turn.

**Changed:** on Oct 6 the user said terse bullets lost them ("explain
more"). On Oct 30 long overviews lost them ("short answers"). Both meant the
same thing: plain, short, next step first.

## Write corrections into the repo, not only into memory

**SHOULD** · 2026-10 → 2026-11 · dashboard apps (4 sources)

A new rule from the user goes into the project's convention doc (and into
AGENTS.md's short list when it matters), with the reason and the user's
words. Write each lesson into the doc that owns the topic, as it happens.
Keep a roadmap doc as the user's menu of what to build next, update it in
every PR, and record open questions and "for later" ideas there instead of
deciding them silently.

**Why:** the user asked for a style doc "so you don't forget the practices
I'm giving you", and for a roadmap to see what's next "instead of having to
ask in chat all the time".

## Concept before code; nothing invented

**MUST** · 2026-09 → 2026-11 · every project type (6 sources)

For anything non-trivial, write the concept first (see
[docs-feature-planning-spec](../../skills/docs/docs-feature-planning-spec/SKILL.md)).
Build from real source material: the client's documents, the old site, the
user's notes. Name every assumption, and never invent features, facts or
environment values. Treat the docs as the source of truth.

**Why:** a first client workflow was built on guesses and had to be reworked
once the client's real documents arrived ("We really can't afford to falsely
implement something").

## Rethink legacy features instead of porting them

**SHOULD** · 2026-10 · dashboard apps

When rebuilding an older system, present the need each old feature served
and a modern take that fits the new app ("I don't want you to copy-paste
features and UI one by one, I want you to rethink and modernize it"). When
re-coding someone else's component, first list its visible behaviours and
tick each one off in the new version; a missing one reads as a regression.

## Re-implement untrusted code; don't merge it

**MUST** · 2026-10 · client dashboard app

Code from an old branch or from a weaker or untrusted agent is a reference,
not a source. Re-code each feature on main following the current
guidelines, review it for security, and polish it even if it is already
committed ("assume it's wrong").

**Why:** re-coding a weaker agent's branch turned up real flaws: a phantom
storage bucket, wrong checksum handling and insecure file serving.

## Parallel work: forks with a coordinator

**SHOULD** · 2026-11 · dashboard app

For several features at once, run up to 3–4 forks (same model and context),
one feature each, in its own worktree, branch and test databases.

- **Forks don't commit.** The coordinator reads every fork's whole diff,
  fixes what's off, writes the shared docs, commits, and opens PRs one at a
  time.
- **Briefs** have fixed sections: scope with what to leave out, where to
  work, a never-touch list, how heavy checks run, a turn budget with a
  progress file, and the report format.
- **Heavy checks** (full type check, production build, Playwright) go
  through one lock-based queue, one at a time.
- **Fresh agents** are only for narrow, read-only research, with a fixed
  output format.

**Why:** on a 16 GB machine a type check or build takes 6–8 GB, so
concurrent heavy runs give flaky results, and shared roadmap lines collide
when branches land in parallel. Forks inherit the conversation and its
rules; fresh agents only know their brief.

## Secrets never pass through the chat

**MUST** · 2026-10 · dashboard apps

The user may paste non-secret identifiers (DSNs, public keys, slugs). For
secrets, have them run an interactive prompt themselves (for example
`gh secret set NAME`), so the value never appears in the conversation. Never
read or print `.env` values. If the user pastes a secret anyway, advise
rotating it.

## Push notifications only for decisions and finished long runs

**CONSIDER** · 2026-10 · dashboard app

Use a push-notification channel when the user's action is needed or a long
run has finished, never for routine progress.

**Why:** the user wants an instant ping whenever they're needed: "If you
need anything from me, I don't care about quiet hours."
