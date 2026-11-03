# AI features inside apps

How an embedded assistant, or an external agent, is allowed to act in an app
the user builds. Model and provider limits are in
[../external-services/ai-providers.md](../external-services/ai-providers.md).

## The model proposes; the server executes as the user; the user approves writes

**MUST** · 2026-10 · dashboard app

The model never touches the database or the UI directly:

- **What the model sees.** The server sends the rules, the tool list for the
  asking user's role, and the conversation. Tools the user may not use are
  never offered to the model.
- **How tools run.** Each tool calls the normal service layer as the asking
  user, with the same permission checks. Reads cite the records they used.
- **Writes are proposals.** Every write comes back as a proposal card.
  Approving it calls the real server action as the approver, so validation,
  permissions and the audit log apply, after a check that the data hasn't
  changed since. "Edit" opens the real form, prefilled.
- **Scope.** The assistant can have broad write abilities (events, tasks,
  notes), since nothing lands without a person's click.

**Why:** "Of course I want to have to accept all of the things first."
Capability is fine; unreviewed writes aren't.

## Memory lives in the app's own records

**SHOULD** · 2026-10 · dashboard app

When users want the assistant to "remember", it proposes a note on the right
record (which the user approves), plus a small visible, editable list of
per-user habits. No hidden memory store: it would bypass permissions and
nobody could see or correct it.

## External agents go through the app, not around it

**CONSIDER** · 2026-10 · dashboard app

To let local agents use an app's data, serve MCP from the app itself
(Streamable HTTP, stateless), not as a local server talking to the database
past the permission checks:

- **Tokens.** Personal per-device tokens with a prefix, stored as SHA-256,
  shown once together with a ready-to-paste client config line, with expiry,
  revoke and "revoke all".
- **Tools.** The same tool catalogue filtered by the person's role, minus
  interactive tools.
- **Writes.** Every write becomes a proposal that a human accepts in the
  app; no tool can accept one.
- **Limits.** Rate limits per token (for example 60 per minute, 2,000 per
  day), and the endpoint is off by default.

**Why:** the user wanted a locally run model with file access for cases
"where the assistant is not enough", without it getting past the app's
permission checks.

## Data processing agreements are a tracked to-do

**CONSIDER** · 2026-10 · dashboard app

When an AI feature or agent will read production personal data, record the
missing data-processing agreement and processing-register entry as an open
item in the docs. The user decides the timing ("we will take care of it
later, so write that down").
