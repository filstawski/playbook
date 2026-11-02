# Integrations

Connecting apps to third-party services and collecting data from outside.

## Integrations connect with a button in the app, never keys in .env

**MUST** · 2026-10 · dashboard apps (2 sources)

Design every third-party integration around an in-app connect flow (OAuth,
a GitHub App manifest flow, and so on):

- **Flow.** A "Connect" button, a return route, "Check connection" and
  "Disconnect". Reconnecting replaces the stored credentials.
- **Storage.** Store the received credentials encrypted in the database,
  using the app's existing secret.
- **What stays in env files.** Only the app's own base secrets.
- **Environments.** Each environment connects its own account or app.

**Why:** "I expect the GitHub connection to be properly with some UI and a
connect button … I don't want to manage any keys in my env file."

## Check the plan includes the API before designing around it

**SHOULD** · 2026-10 · dashboard app

Before planning an integration, confirm that the user's subscription tier
exposes the API and the specific features you rely on. Vendor blog posts cite
plan names that no longer exist. If the API isn't available, build the
capability in-house and keep the integration as a later step.

**Why:** a planned integration had to be dropped because the user's plan
didn't include API access.

## One interface per kind of provider

**CONSIDER** · 2026-10 · dashboard app

Build sync (calendars, repositories, storage) against a common interface, so
a second provider is a second connection rather than a second sync system.
Prefer a thin client over a large SDK: for Microsoft 365, the official
auth library plus plain `fetch` to the Graph API was chosen over the Graph
SDK. Repo integrations use a read-only GitHub App with only the permissions
they need, plus a webhook.

## Free and gentle data sourcing; never bypass access controls

**MUST** · 2026-10 → 2026-11 · dashboard app

When collecting public data:

- **Sources.** Start with free options: open-data APIs, free public APIs
  (treat an unofficial one failing as "source unavailable"), and a browser
  extension that reads only the page the user has open, on their click.
  Avoid scraping against a site's terms, and avoid paid scraping APIs ("I'd
  prefer free approaches, I don't mind doing parts manually").
- **Access.** Never work around a captcha or any other access control.
- **Requests.** Find out what an API really returns (docs plus a few live
  requests) before designing around it. Fetch details only for items that
  passed your filters, once per item (cache), at a gentle pace.
- **Tests.** Use recorded responses, never the live API.
- **What to keep.** Only a business's general contact data; skip mobile
  numbers and named people's personal details.

## Web Push

**SHOULD** · 2026-10 · dashboard app

- **Keys.** One VAPID key pair per environment, never shared, since renewing
  a pair invalidates that environment's subscriptions. The deploy can
  generate a missing pair and must keep an existing one.
- **iOS.** Push works only for HTTPS sites opened as an installed home-screen
  app.
- **Android.** The status-bar badge is drawn as a silhouette. Ship a separate
  white-on-transparent monochrome badge (about 96 px), or users see a plain
  square.
- **Service worker.** Serve it uncached.

## Figma on a limited plan: build locally, upload finished boards

**SHOULD** · 2026-10 · brand assets

Check the Figma plan and seat first. On a starter plan with a view seat,
connector calls are scarce and most write tools are blocked:

- Generate designs locally (SVG via scripts).
- Upload each finished board as one editable frame, placed to the right of
  the previous round with a descriptive name.
- Verify by opening the file in a browser.
- The connector can add but not delete, so tell the user which outdated
  boards to remove.

Brand asset versions are additive: never replace or overwrite an earlier
version's files.
