# 7. External services

Third-party services the apps and sites use: email, integrations, AI
providers, error tracking and analytics.

| File | Covers |
| --- | --- |
| [email.md](email.md) | dev email to your own inbox, outbox with modes, provider setup, bounces, fixed-text confirmations, consent for marketing email |
| [integrations.md](integrations.md) | connect in the app (no keys in env), check the plan, one interface per provider kind, gentle and legal data sourcing, Web Push, Figma on a limited plan |
| [ai-providers.md](ai-providers.md) | keys per environment with budgets; strict-tool limits beyond the published ones |
| [monitoring-and-analytics.md](monitoring-and-analytics.md) | Sentry EU with collection off; consent-free measurement first on public sites |

## Know these first

- **No development email reaches a real person.**
- **Integrations connect with a button in the app,** never with keys in
  `.env`.
- **Never work around a captcha** or any other access control.
- **Public sites set no cookies and load nothing third-party** unless that
  is decided and documented.
