# website

My default approach to building websites: stack, folder structure, and
conventions — split by framework, since the answer differs a lot between a
Next.js app and a future Astro site, and even within one framework the
answer differs between a logged-in dashboard and a public marketing/content
site.

One subfolder so far, grouped by framework:

| Folder | Covers |
| --- | --- |
| [nextjs](nextjs/README.md) | Next.js dashboard-style apps (product UI behind auth) |

A future `astro/` folder (or a `nextjs/` marketing-site sub-theme) is where
normal, mostly-static web pages will get their own skills — **deliberately
not covered here**. Don't reuse a dashboard skill's patterns (client-heavy
rendering, TanStack Query for every read, auth-gated layouts) for a content
page; that's a different set of tradeoffs this domain hasn't written down
yet.

## Why this is organized as a domain, not flat

Everything under `skills/website/` will eventually span multiple frameworks
and multiple site *kinds* (dashboard vs. marketing) — nesting by framework
first, then by kind, keeps a future `skills/website/astro/` from colliding
with `skills/website/nextjs/` even though both answer "how do I structure a
website." See the root [CONCEPT.md](../../CONCEPT.md) for the general
domain-nesting rationale.
