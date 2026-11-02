# Monitoring and analytics

Error tracking in apps, and measurement on public sites, both privacy-first.

## Sentry in the EU region, with collection turned off by default

**SHOULD** · 2026-10 · dashboard apps

- **Region.** Use Sentry's EU region. It's fixed per organization, so check
  it before creating the project.
- **Collection.** Turn off default collection of user details, cookies,
  headers, bodies, query strings, database values, job data and local
  variables. Scrub search terms from every URL, including the framework's
  request-path context. No console breadcrumbs, sessions or tracing.
- **Browser events.** Tunnel them through an app route so the Content
  Security Policy stays strict.
- **Handled errors.** Report errors the app catches and handles itself.
- **Build values.** The DSN is a build argument, not a secret. The
  source-map upload token is a BuildKit secret.
- **Version.** Pin the SDK exactly.

## Public sites: consent-free measurement first

**SHOULD** · 2026-08 → 2026-11 · company website, client sites

Before adding Google Analytics or tracking pixels, offer consent-free
options:

- Search Console (queries, clicks, landing pages)
- server logs
- a cookieless, self-hosted analytics tool

On a German site, GA needs a consent banner, counts only people who accept,
and would contradict a "no cookies, no tracking" statement in the privacy
policy.

If a banner is needed after all:

- Nothing loads before consent.
- "Reject" is as prominent as "accept" on the first layer, and nothing is
  pre-ticked.
- The site works fully without consent, and the choice can be withdrawn
  from the footer.

```tsx
// Mount GA only after stored consent; never hand-inject gtag.
import { GoogleAnalytics } from "@next/third-parties/google";

export function Analytics({ consent }: { consent: "accepted" | "rejected" | null }) {
  return consent === "accepted" ? <GoogleAnalytics gaId={process.env.NEXT_PUBLIC_GA_ID!} /> : null;
}
```

`NEXT_PUBLIC_*` IDs come from repository variables, not secrets, and a new
value needs a rebuild. If no collect requests appear, test without an ad
blocker before changing code.

**Changed:** in August a site got GA behind a consent banner. In November
the agent advised launching a site without GA, and the user's decision isn't
recorded; see [OPEN_QUESTIONS.md](../../OPEN_QUESTIONS.md).
