# Websites

Rules for marketing and small-business sites. Building one from scratch is
the skill
[website-nextjs-site-setup](../../skills/website/nextjs/website-nextjs-site-setup/SKILL.md);
SEO is [marketing-seo-audit](../../skills/marketing/marketing-seo-audit/SKILL.md);
copy is [marketing-copywriting](../../skills/marketing/marketing-copywriting/SKILL.md).

## Start every site from a maintained template and its prompt

**MUST** · 2026-11 · client sites

New client sites start from a maintained template repository that already
holds the baseline in this file (the user keeps one, private), and from its
reusable prompt, which takes only the old site's address, the trade and
notes. The goal is to produce good sites quickly and consistently. Never
start from a bare `create-next-app`.

## Small-business sites are fully static and private

**MUST** · 2026-10 → 2026-11 · client sites (3 sources)

- **Static.** Every route prerenders, and the build fails if one stops
  being static (`export const ensureStatic = "navigation"` in the root
  layout). Nothing reads cookies, headers or search params.
- **Private.** No cookies, analytics, embeds or third-party requests (for
  analytics, see [OPEN_QUESTIONS.md](../../OPEN_QUESTIONS.md) #14). A map
  is a plain link, not an iframe. Fonts are self-hosted through `next/font`.
  Anything third-party needs a decision in the concept and its own section
  in the privacy policy before it ships.
- **Forms.** Without a backend, the inquiry form validates and then
  composes a `mailto:` (CRLF line breaks, RFC 6068), and says so beside the
  button.

**Why:** no consent banner and a short privacy policy, which is also a
selling point in client outreach.

## Complete HTML; nothing waits at opacity 0 for JavaScript

**MUST** · 2026-10 → 2026-11 · company website, client sites

Text, headings, links, images and metadata are in the server response. What
arrives with the page animates in CSS from the server HTML. What arrives on
scroll is hidden only after hydration, and only if it is still below the
fold, so nothing already on screen disappears. No-JS, reduced-motion and
print visitors get the finished page. Check each page with JavaScript off.

**Why:** a hero that waited for scripts appeared about a second late over a
bare background, and a fading heading held LCP for 670–750 ms instead of
50–140 ms.

**Changed:** sites built in late October hid reveals from the start and
patched no-JS visitors with a `<noscript>` style override. The November
template hides only what is still below the fold, after hydration.

## One typed source for the business's facts and content

**MUST** · 2026-11 · client sites

One typed facts module (e.g. `src/lib/site.ts`) exports a `SITE` object (name, URL, tagline, owner,
address, phone in display and international form, email, region, legal
identifiers) plus `PAGES` (which feeds the sitemap), `NAV`, `CTA` and
`LEGAL_NAV`. Header, footer, contact page, legal pages and JSON-LD read it;
nothing else holds an address or a number. Each content list (services,
projects, process steps) is one typed module in `src/lib/<topic>.ts`. Copy
never lives inside reusable components; client islands get their strings
as props.

**Why:** on a hand-coded site the same facts were repeated across pages, so
each change from the customer meant edits in several files and left
contradictions behind.

## Nothing untrue on a site

**MUST** · 2026-09 → 2026-11 · client sites, company website

Every fact on a site needs a source recorded in the concept doc (the old
site, the legal notice, the owner). Gaps become open questions, never
invented details:

- no made-up numbers, reviews, ratings or opening hours;
- no testimonials or logos that weren't supplied;
- no stock-photo "team".

The page check fails the build if placeholder text is left on a page.

## Images, fonts, headers

**SHOULD** · 2026-11 · client sites

- **Photos** are static imports from `src/assets/<topic>/` with
  `placeholder="blur"` and `sizes` matching the layout. Sources are resized
  to at most 2000 px on the long side at about 82% JPEG quality, with
  descriptive kebab-case names. Originals stay in `docs/` and out of the
  Docker context.
- **The logo** is SVG; a raster-only logo is redrawn, and the owner confirms
  the result.
- **Fonts** come through `next/font` and are mapped to role variables. Load
  `latin-ext` only when the language needs it, and only the weights in use.
- **Headers:** `next.config` adds HSTS, `nosniff`, Referrer-Policy and a
  restrictive Permissions-Policy everywhere, plus a static CSP in production
  only. No nonces: a nonce forces every page to render per request.
- **Source asset packages** never go into `public/`: everything there is
  served publicly.

**Why:** one client's own logo file was "quite bad quality", so redrawing
raster logos as SVG became a standard step.

## Bilingual only when the audience needs it

**SHOULD** · 2026-10 → 2026-11 · company website

Single-language sites have no i18n library. A bilingual site:

- uses `next-intl`, with the default locale at the root and the other
  under a prefix, plus localized slugs;
- turns off locale detection and the locale cookie, so static pages never
  depend on the request;
- sets hreflang through `alternates.languages` with `x-default`;
- has every language written by a person, never machine-translated or
  silently falling back.

The language switch computes its target from the same page registry as the
sitemap. While the user is rewording copy in one language, edit only that
language, and carry the changes across in one pass when asked.

**Why:** an earlier site served one language to everyone and swapped to the
other only after hydration, so search engines never saw it.

## Third-party visual effects are vendored and adapted

**SHOULD** · 2026-10 · company website

When adopting an effect component from an open-source registry, copy its
technique into your own module with its licence file. Then adapt it:

- never hide wrapped content until WebGL paints;
- give it reduced-motion still frames and a CSS fallback;
- pause it off screen;
- check the licence terms, e.g. MIT plus Commons Clause allows site use but
  not resale.

Create a WebGL context only when the effect is on screen, give it back when
it leaves, and survive React StrictMode's double mount: an effect painted
solid white only in development.

**Why:** running a registry's init overwrote a site's button, font variable
and lockfile when the user only wanted to add the registry.

**See also:** [../stacks/web-stack.md](../stacks/web-stack.md) for the
rejected effect approaches.
