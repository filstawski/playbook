# Email

Transactional email in apps and sites. Provider in use: Resend, EU region,
with React Email templates.

## Development email goes to your own inbox, never to real people

**MUST** · 2026-10 · client dashboard app, company website

During development, route every email (customer and staff) to the developer's
plus-addressed inbox (`<you>+<topic>@<your-domain>`) through a redirect mode
that keeps the intended recipient in an `X-Original-To` header. Mock
recipients are plus-addresses or the provider's test inboxes. Automated
tests run in preview mode with no API key. Never send real email unasked.

**Why:** the user wanted every email, to customers and staff alike, in their
own inbox during development ("I want to receive all emails for now").

## Send through an outbox with explicit modes

**SHOULD** · 2026-10 · client dashboard app

Write each email to an outbox table with a unique idempotency key, in the
same transaction as the change that caused it, and send from there. Store the
resolved reply-to and the triggering user with the row, so retries route the
same way. One setting picks the mode:

| Mode | Behaviour |
| --- | --- |
| `preview` | sends nothing; for tests |
| `redirect` | everything goes to one team inbox, plus-addressed |
| `demo` | staff get their own mail; mail meant for outsiders goes to whoever triggered it |
| `live` | real recipients; refuses to start outside production |

**Why:** on a shared test server, a coworker clicking through a demo must
receive their own test emails, and no real customer may get anything.
Development-only mail preview routes return 404 everywhere else.

## Provider setup

**SHOULD** · 2026-10 · dashboard apps

- **Domain.** Verify the sending domain on a `send.` subdomain (DKIM, SPF,
  MX) so the domain's existing mail is unaffected, in the provider's EU
  region.
- **Keys.** One API key per environment, restricted to sending for that
  domain. Read keys lazily so the app runs without email configured. The
  user adds the real key to `.env` themselves; `.env.example` is committed.
- **Errors.** The SDK returns failures instead of throwing: check the result
  and throw. Treat rate-limit, quota and 5xx errors as transient.
- **Idempotency.** Pass an `idempotencyKey` with every send.
- **Webhooks.** Verify delivery webhooks with their signature headers.

```ts
const { data, error } = await resend.emails.send(message, { idempotencyKey: outboxRow.key });
if (error) throw new EmailSendError(error.name, error.message);
```

## Bounces and complaints are visible and correctable

**CONSIDER** · 2026-10 · client dashboard app

Record delivery events per email (delivered, delayed, bounced, complained);
the status only moves forward. A permanent bounce or a complaint suppresses
the address. The affected record shows a warning with "correct address",
which re-sends the failed email only if it's still relevant.

## Confirmation emails to visitors use fixed text

**MUST** · 2026-11 · company website

A form's confirmation email to the visitor never echoes their name or
message. Otherwise the form can be abused to send arbitrary text to arbitrary
addresses. The team notification is the record of the inquiry. Hand the
inquiry to other systems in the background, with retries, and still show the
thank-you page if that hand-off fails.

## Marketing email needs provable consent (EU)

**CONSIDER** · 2026-10 · client dashboard app

Record how a contact agreed. Send a confirmation email, not a request,
because in Germany asking can itself count as advertising. Consent counts
only after a button press on the confirmation page, and the same link
unsubscribes for good. Every recipient gets their own email, sent in the
background. Business emails from German companies carry the legally required
company details in the footer.
