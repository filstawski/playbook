# docs

How to write the documents *around* code — plans before building, handoffs
between agents/teams, and honest records of what's deliberately
unfinished — as opposed to the `api`/`sdk` domains, which are about the
code itself.

- **[docs-feature-planning-spec](docs-feature-planning-spec/SKILL.md)** —
  a structured template for planning a feature before writing code: goal,
  scope (in/deferred/out), locked decisions, phased rollout,
  resolved-vs-open questions.
- **[docs-agent-handoff-spec](docs-agent-handoff-spec/SKILL.md)** — a
  self-contained spec for handing a partially-built system to another
  agent/team/future-you to build the other half.
- **[docs-roadmap-notes](docs-roadmap-notes/SKILL.md)** — writing down one
  deferred improvement inline: what it'd look like, why it's deferred, what
  would trigger doing it.
- **[docs-migration-status-tracking](docs-migration-status-tracking/SKILL.md)**
  — a checklist/status table for tracking many deferred items at once
  (an incremental migration, a guideline-compliance backlog).
- **[docs-informal-to-formal-guidelines](docs-informal-to-formal-guidelines/SKILL.md)**
  — write conventions as rough notes first, formalize once they stabilize,
  keep the rough version around as project voice.

## How these relate

`docs-roadmap-notes` and `docs-migration-status-tracking` are the same
underlying idea — write down what's deliberately unfinished instead of
leaving it silent — at two different scales: one inline note for a single
decision, one running table for many. `docs-feature-planning-spec` and
`docs-agent-handoff-spec` are sequential: a plan gets written before
building, a handoff describes what got built (or how far it got) for
whoever picks up the other half. `docs-informal-to-formal-guidelines` is
about a different kind of document entirely — not a feature, a *standing
convention* — but follows the same instinct: write the cheap version
first, don't let "not polished yet" be a reason not to write it down at
all.
