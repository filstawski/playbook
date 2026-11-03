# playbook

My personal reference for how I like to build software — written as
[Claude Code Skills](https://docs.claude.com/en/docs/claude-code) so they're
reusable across projects and usable by an agent, not just readable by me.

This is not a style guide for a specific language or framework. It's the
layer above that: how I structure repos, how I want AI tools to collaborate
with me, what tradeoffs I default to, and what mistakes I don't want to
repeat.

## Why this exists

- I start new projects often enough that re-establishing the same defaults
  (commit hygiene, testing philosophy, how much abstraction is too much) is
  wasted effort.
- Claude Code Skills are discovered by their `description` and invoked
  automatically when relevant — so a practice written here can actually act,
  not just sit in a doc waiting to be read.
- Writing a practice down forces me to check whether it's actually true, or
  just a habit.

## Start here

[INDEX.md](INDEX.md) maps everything: the guidelines in thirteen categories,
the skills, what to read for which task, and the drop-in agent snippet.
[OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) logs the decisions taken and holds any
new open question.

## Structure

See [CONCEPT.md](CONCEPT.md) for the full rationale. Since the 2026-11
consolidation there are two layers:

- `guidelines/<category>/` holds short rules, grouped into the twelve
  categories.
- `skills/` holds deep, invocable practices, as before.

Short version of the skills layout:

```
skills/
  <domain>/                    # e.g. api/ — grouping for navigation only
    README.md                  # index + reading order for this domain
    <sub-theme>/                # e.g. api/managers/ — optional second level
      README.md
      <skill-name>/
        SKILL.md
templates/
  SKILL.md                     # copy this to start a new skill
```

Each skill is a single `SKILL.md`: frontmatter (`name`, `description`), then
the rule, why it exists, and when it doesn't apply — usually with real code.
`README.md` files at each folder level are navigation only (a domain
overview, a reading order, links to what's inside) — see
[skills/README.md](skills/README.md) for the full index and
[skills/api/README.md](skills/api/README.md) for a worked example of a
domain folder.

**How deep a skill lives in this repo doesn't matter for reuse.** Reuse
always symlinks one leaf `<skill-name>/` directory — see below — so
`skills/api/managers/api-manager-base/` and a hypothetical flat
`skills/api-manager-base/` behave identically once linked.

## Using this in another project

**What every project actually does (since September 2026):** install skills
with the `skills` CLI, vendored into the repo and committed, with a
lockfile:

```sh
npx skills add filstawski/playbook --skill code-polish --skill git-commit-messages
ln -s ../.agents/skills .claude/skills
git add .agents/skills .claude/skills skills-lock.json
```

Then paste [snippets/AGENTS.md](snippets/AGENTS.md) into the project's
`AGENTS.md`, so agents find the guidelines and the top rules too. Details,
and the typical skill set per kind of project, are in
[skills/README.md](skills/README.md#installing-skills-in-a-project).

The symlink options below still work for a local, always-live link to this
clone:

1. **Global, all projects:**
   ```sh
   ln -s ~/Development/playbook/skills/api/managers/api-manager-base ~/.claude/skills/api-manager-base
   ```
   Available and auto-discoverable in every Claude Code session from then on.
   The destination name (`~/.claude/skills/<skill-name>`) should match the
   skill's own `name:` — the source path leading up to it can be anything.

2. **One project only:**
   ```sh
   ln -s ~/Development/playbook/skills/api/managers/api-manager-base .claude/skills/api-manager-base
   ```

3. **Just borrowing one rule, no ongoing dependency:** copy the `SKILL.md`
   into the project instead of symlinking.

Symlinking is preferred over copying — it keeps the practice live, so an
edit here propagates everywhere it's linked instead of drifting into stale
copies.

## Adding a new skill

```sh
mkdir -p skills/<domain>/<skill-name>
cp templates/SKILL.md skills/<domain>/<skill-name>/SKILL.md
```

(Or nest one level deeper — `skills/<domain>/<sub-theme>/<skill-name>/` —
once a domain has enough skills that a flat list stops being navigable; see
`skills/api/` for an example.)

Fill in `name`, `description` (this is what triggers auto-invocation — be
specific about what and when), and the Rule / Why / Exceptions body, then
add it to that domain's `README.md` and to the full index in
`skills/README.md`. See [CONCEPT.md](CONCEPT.md) for the full format and
naming convention.

## Status

Early / actively being filled in. Expect gaps — skills get added when a
decision comes up worth keeping, not in one sitting.
