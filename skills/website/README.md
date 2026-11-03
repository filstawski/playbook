# website

My default approach to building websites: stack, folder structure, and
conventions — split by framework, since the answer differs a lot between a
Next.js app and a future Astro site, and even within one framework the
answer differs between a logged-in dashboard and a public marketing/content
site.

One subfolder so far, grouped by framework, plus one skill that applies
across frameworks and site kinds:

| Folder / skill | Covers |
| --- | --- |
| [nextjs](nextjs/README.md) | Next.js product apps behind auth, both a thin client over an external SDK (`dashboard`) and a full-stack app that owns its own backend (`fullstack`). Also, since the 2026-11 consolidation, static marketing sites (`site`). |
| [website-motion](website-motion/SKILL.md) | Transitions, animations, morphs and scroll effects for React/Next.js apps and sites: rules, shared spring tokens, a pattern catalogue with code, and how motion is verified. Lives at this level because apps and sites share one motion vocabulary in two intensity profiles. |

Marketing and content sites now have their own skill,
[website-nextjs-site-setup](nextjs/website-nextjs-site-setup/SKILL.md). Don't
reuse a dashboard skill's patterns (client-heavy rendering, TanStack Query
for every read, auth-gated layouts) for a content page, or the other way
round. A future `astro/` folder would sit next to `nextjs/`.

## Why this is organized as a domain, not flat

Everything under `skills/website/` will eventually span multiple frameworks
and multiple site *kinds* (dashboard vs. marketing) — nesting by framework
first, then by kind, keeps a future `skills/website/astro/` from colliding
with `skills/website/nextjs/` even though both answer "how do I structure a
website." See the root [CONCEPT.md](../../CONCEPT.md) for the general
domain-nesting rationale.
