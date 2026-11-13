# Concept

## Problem

Preferences and conventions I've settled on tend to live in one of three bad
places: my head (forgotten or reinvented per project), a specific project's
`CLAUDE.md` (not portable), or a chat history (gone after the conversation
ends). None of those scale across projects, and none of them are anything an
agent can act on directly — at best they're prose someone (human or model)
has to re-read and re-interpret every time.

## Approach

One repo, `playbook`, holding practices as **Claude Code Skills** — the same
`SKILL.md` format Claude Code itself uses for `/code-review`, `/simplify`,
etc. A practice here isn't just documentation; it's a unit an agent can
discover and invoke, and a human can read top to bottom in under a minute.

### Why skills instead of plain docs

- **Discoverable by agents.** A `SKILL.md`'s frontmatter `description` is
  exactly the trigger condition an agent needs — "use when X" — so a Claude
  Code session can pick up the right practice automatically instead of me
  having to remember to mention it.
- **Actually reusable, not just readable.** Symlinking a skill directory into
  `~/.claude/skills/` or a project's `.claude/skills/` makes it live and
  invocable there. A plain markdown doc in a reference repo never gets that
  — someone has to remember it exists and go read it.
- **Forces the same discipline either way.** A skill still has to be
  specific and honest about when it doesn't apply — that constraint is what
  made the plain-docs version worth doing in the first place. It does *not*
  have to be short (see Length, below).

### Length

The generic advice for Claude Code skills ("keep it under 500 lines,
context is shared with everything else") is written for skills a
general-purpose agent auto-loads mid-task, where every token competes with
the actual work. This repo is different: it's a personal reference I want
to be *complete* — real, runnable code examples, not just the shape of the
idea described in prose. A vague one-paragraph "use a base class for
managers" is useless six months later when I actually need the base class;
a skill with the base class's full source, two worked subclass examples,
and the reasoning behind each design choice is something I can build from
directly. So: **write the whole thing down.** Include real code, not
pseudocode. If a topic has multiple independently-useful facets (e.g. "the
base class" vs. "the declarative config it reads" vs. "the effects/populator
layer underneath it"), split it into multiple skills rather than cramming
everything into one enormous file — each one should still be readable
start to finish on its own, just not artificially trimmed to hit a line
count.

### Structure

```
skills/
  <domain>/                     # e.g. api/ — grouping for navigation only
    README.md                   # domain overview + reading order
    <sub-theme>/                 # optional second level, e.g. api/managers/
      README.md
      <skill-name>/
        SKILL.md
        (optional: reference.md, scripts/, examples.md — only if SKILL.md
         alone gets unwieldy; most practices won't need these)
```

Nested by domain, one or two levels deep, once a domain has enough skills
that a flat list of them stops being scannable (three-plus skills that
share heavy cross-references, the way `api/managers/`'s three skills do).
A domain with one or two skills doesn't need its own folder yet — it lives
directly under `skills/` until a second related skill shows up.

**This nesting is purely an authoring-side convenience and has no effect on
reuse or on how Claude Code discovers a skill.** Claude Code's
directory-scoped path-prefix resolution (`apps/web:deploy`) is about
*where a project's `.claude/skills/` directory itself lives* relative to
other `.claude/skills/` directories in a monorepo — it has nothing to do
with how this source repo happens to organize files before they're
symlinked out. Reuse (see below) always symlinks one *leaf*
`<skill-name>/` directory to `~/.claude/skills/<skill-name>` or a project's
`.claude/skills/<skill-name>` — the destination is flat regardless of how
deep the source lives in this tree. A `README.md` at each folder level is
navigation, not a skill (Claude Code looks for `SKILL.md`, not
`README.md`, so these are invisible to skill discovery either way).

### SKILL.md format

```markdown
---
name: skill-name
description: >-
  What this covers and when to use it — third person, specific trigger
  terms, not "I can help you with X."
metadata:
  type: practice
  category: git | architecture | testing | ai-collaboration | tooling | ...
---

## Rule

The practice, stated as an instruction an agent can follow directly.

## Why

The reasoning, tradeoff, or incident behind it. Without this, the rule
calcifies and gets applied to cases it was never meant for.

## Exceptions

When this doesn't apply, or hasn't been tested. A rule with no stated
exceptions is usually applied too broadly.
```

- `name` / `description` are the two fields every skill-aware tool actually
  reads — keep them accurate, since they're what triggers auto-invocation.
- `metadata` is ours: not read by Claude Code, just how I keep a lightweight
  category index across skills without relying on folder nesting.
- A template lives at [`templates/SKILL.md`](templates/SKILL.md) — copy it
  to start a new skill rather than writing frontmatter from memory.

Keep each `SKILL.md` focused on one practice — but "one practice" can still
run long with full code examples (see Length, above). If it needs sections
for genuinely unrelated ideas, it's two skills, cross-linked via a relative
markdown link in each one's Rule section.

### Naming

`kebab-case`, verb-or-topic first, specific enough to disambiguate at a
glance: `git-commit-hygiene`, not `git`; `abstraction-thresholds`, not
`architecture`. Matches the pattern Claude Code's own built-in skills use
(`code-review`, `update-config`) rather than the loose category names from
an earlier draft of this repo.

A skill's `name:` should carry its domain as a prefix (`api-manager-base`,
not just `manager-base`) **regardless of how deeply it's nested in this
source tree** — every skill lands flat in some `.claude/skills/` once
symlinked, so the prefix is what keeps it unique and identifiable there,
not the folder it happened to live in inside this repo. The directory name
should match `name:` exactly for the same reason.

### Growth

No fixed taxonomy up front — skills get added when a decision comes up worth
keeping, tagged with whatever `metadata.category` fits. Likely categories
over time: `git`, `architecture`, `testing`, `ai-collaboration`, `tooling`.
`ai-collaboration` in particular is where "how I want Claude Code to work
with me" belongs — autonomy level, verbosity, when to ask vs. act.

### Reuse across projects

- **Global, all projects:** symlink the individual skill directory into
  `~/.claude/skills/<skill-name>`. Auto-discovered in every session from
  then on.
- **One project only:** symlink into that project's `.claude/skills/`.
- **Just borrowing one rule:** copy the file instead of symlinking, when I
  don't want the project depending on this repo.

Symlinking (not copying) is the default because it keeps the practice live —
an edit here propagates everywhere it's linked, instead of drifting into N
stale copies.

### Self-containment

A skill here should work standalone: no references to a specific project's
file structure, tickets, or people. If a rule only makes sense in the
context of one codebase, it belongs in that codebase's own `.claude/skills/`
or `CLAUDE.md`, not here.

### Lifecycle

A practice can be wrong or outdated. When that happens, edit or delete the
skill — don't leave stale guidance around because it was once true. Git
history is the changelog; no need for a "deprecated" graveyard inside the
repo.

### Guidelines (added 2026-11)

Skills turned out to be the wrong shape for the many short rules that came
out of daily work, such as "every input has a placeholder", "no AI
attribution", or "resolve the lockfile on Linux". Each is one or two
sentences with a reason, and forcing each into its own `SKILL.md` would
have buried them. They now live in `guidelines/`:

```
guidelines/
  README.md                  # the thirteen categories, entry format
  <category>/                # ui-ux, design-guidelines, frontend, backend, stacks,
    README.md                # apis, external-services, github, version-control,
    <topic>.md               # ci-cd, deployment, working-with-agents;
                             # uncategorized/ for misfits (flagged)
```

- **What an entry is.** A short imperative title; a strength (`MUST`,
  `SHOULD`, `CONSIDER`), date and generic project type; the rule; why;
  optionally an example and a "changed" note. See
  [templates/GUIDELINE.md](templates/GUIDELINE.md).
- **Where an entry comes from.** Nearly every entry comes from the user's own
  projects. Established laws of UX (Fitts, Hick, Miller, Postel and so on)
  may be added as well (since 2026-11-13). Their source line says
  "established UX law", they are at most `SHOULD`, and the user's own rules
  win wherever the two disagree.
- **Guidelines link to skills instead of duplicating them.** When a topic
  needs pages of code or a procedure, that's a skill, and the guideline
  entry points to it.
- **Guidelines aren't symlinked.** Agents reach them through
  [INDEX.md](INDEX.md) and the drop-in [snippets/AGENTS.md](snippets/AGENTS.md),
  which carries the top rules inline. Topic files therefore need no domain
  prefix.
- **This is still not a knowledge base.** Every entry is a rule an agent can
  follow, not an explainer.
- **Self-containment and privacy.** This repository is public, so source
  lines name a generic project type ("dashboard app", "client site"), never
  a project, client or company, and never a domain or a secret.

Skills added in the same pass follow the existing conventions (domain
prefix, Rule/Why/Exceptions, full code). Skills rebuilt from third-party
sources carry a `README.md` beside the `SKILL.md`, naming what they were
based on and including the upstream licence notice.

## Non-goals

- Not a general knowledge base (no "how X works" explainers).
- Not per-project state (no TODOs, no project status, no ticket references).
- Not exhaustive on day one. A thin, honest set of skills beats a padded one
  written to look complete.
- Not every skill needs to be agent-auto-invoked — some practices are purely
  for me to read before starting a project. Those still use the same format;
  they just won't get triggered ambiently as often.
