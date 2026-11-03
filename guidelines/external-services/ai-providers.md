# AI providers

Using model APIs (Anthropic in practice) from inside an app. How AI features
behave toward users is in [../apis/ai-features.md](../apis/ai-features.md).

## Keys per environment, validated at startup, with budgets

**SHOULD** · 2026-10 · dashboard app

- **Keys.** Use a separate API key per environment. Staging's key gets a low
  spend limit, set in the provider console.
- **Startup check.** Validate the key format at startup, so a malformed key
  fails the deploy's health check and the previous version keeps running.
- **Budgets.** Offer per-user monthly budgets (warning) and a global one
  (hard stop) in the admin settings.

## Strict tools have limits beyond the published ones

**SHOULD** · 2026-10 · dashboard app

Strict tool mode has published per-request limits (for example 24 optional
parameters, 16 union-typed parameters, 20 strict tools). The tool schemas are
also compiled into one grammar with an **unpublished size limit**. Arrays of
objects and unions cost the most; plain strings are cheap.

- Mark strict only the tools whose output becomes a UI card or proposal. Read
  tools stay non-strict and return validation failures as tool errors, so the
  model retries.
- Prefer string inputs parsed on the server over discriminated unions.
- Add a unit test that sums the published limits for a user who gets every
  tool. Before shipping a new strict tool, replay the exact tool list against
  the real API.
- On a "compiled grammar is too large" 400, retry once without strict mode
  and report the error to monitoring once.
- Check that the SDK's schema helper keeps real enums: it may move enum
  values into descriptions.

**Why:** one new union-typed input made every assistant turn fail in
production while all tests passed, because the tests checked only the
published limits.
