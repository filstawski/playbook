---
name: website-nextjs-site-setup
description: >-
  Build a new marketing or small-business website from an empty folder to a
  first preview: start from the website template, research the old site,
  write the concept, wire facts, brand, SEO baseline and legal pages, build
  the pages, run the checks, and deploy a preview. Use when starting a new
  client or company site, or rebuilding an existing one. For static,
  content-first sites only, not for dashboards or apps with a backend.
metadata:
  type: practice
  category: architecture
---

## Rule

Every new site starts from a website template: a repository that already
holds the baseline below (stack, configs, folders, check script, legal page
generators, vendored skills), plus a reusable build prompt. That way good
sites can be produced quickly and consistently. If there is no template yet,
build the baseline once with the steps below and freeze it into one. The
order below is the
order that worked across three consecutive client sites and the company
site. Each step exists because skipping it cost a round of rework. The
guideline files hold the rules in short form:
[websites](../../../../guidelines/frontend/websites.md),
[web stack](../../../../guidelines/stacks/web-stack.md),
[restraint and character](../../../../guidelines/design-guidelines/restraint-and-character.md).

### 0. Inputs

- the old site's address
- the trade or business type
- notes: the owner's wishes, pages to add or drop

A build prompt kept in the template (e.g. `PROMPT.md`) takes exactly these
three inputs and runs the steps below: set up → research → concept → build →
verify → ship → report. It grants commit and push for that task only, and is
deleted at handover.

### 1. Create the repository

From your template repository:

```sh
cd ~/Development
gh repo create <org>/<slug>-website --template <org>/<template-repo> --private --clone
cd <slug>-website && npm install
```

Without a template, start from the newest `create-next-app` (TypeScript, App
Router, Tailwind, ESLint, `src/`, `@/*` alias), remove its public SVGs and
favicon, and add the pieces from steps 2–4 and 7–8 below.

`<slug>` comes from the business name. Client repositories are private and
live in the organization used for client work. Read the repo's `AGENTS.md`
and its coding-style doc, then the matching skill before each kind of task.
Before using any Next.js API, read `node_modules/next/dist/docs/`.

### 2. Stack and versions

```json
{
  "engines": { "node": ">=24" },
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "typecheck": "next typegen && tsc --noEmit",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "check": "node scripts/check-site.mjs"
  },
  "dependencies": {
    "next": "<exact, as create-next-app wrote it>",
    "react": "<exact>",
    "react-dom": "<exact>",
    "motion": "^14",
    "lucide-react": "^1"
  },
  "devDependencies": {
    "@tailwindcss/turbopack": "^4",
    "tailwindcss": "^4",
    "typescript": "^5",
    "@types/node": "^24",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "eslint-config-next": "<same version as next>",
    "prettier": "^3",
    "prettier-plugin-tailwindcss": "^0.8",
    "schema-dts": "^2",
    "playwright-core": "^1"
  }
}
```

`.nvmrc` contains `24`. Add `next-intl` only for a bilingual site, and a
mail provider, `zod` and `server-only` only once a server-side form has been
decided in the concept.

### 3. Configuration

```ts
// next.config.ts
import type { NextConfig } from "next";

const CONTENT_SECURITY_POLICY = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob:",
  "font-src 'self'",
  "connect-src 'self'",
  "frame-ancestors 'none'",
  "form-action 'self' mailto:",
  "base-uri 'self'",
  "object-src 'none'",
  "upgrade-insecure-requests",
].join("; ");

const SECURITY_HEADERS = [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), payment=(), usb=(), bluetooth=(), browsing-topics=()",
  },
  // Dev needs eval; a nonce would render every page per request, so the CSP is static.
  ...(process.env.NODE_ENV === "production"
    ? [{ key: "Content-Security-Policy", value: CONTENT_SECURITY_POLICY }]
    : []),
];

const nextConfig: NextConfig = {
  cacheComponents: true,
  poweredByHeader: false,
  async headers() {
    return [{ source: "/:path*", headers: SECURITY_HEADERS }];
  },
  async redirects() {
    return [
      // every old address → its closest new page, permanently (step 11)
      { source: "/leistungen.html", destination: "/leistungen", permanent: true },
    ];
  },
};

export default nextConfig;
```

- **Prettier:** `.prettierrc.json` is
  `{ "printWidth": 100, "plugins": ["prettier-plugin-tailwindcss"], "tailwindStylesheet": "./src/app/globals.css" }`.
  `.prettierignore` lists lockfiles, `next-env.d.ts`, agent folders and
  `*.md`, so docs stay hand-formatted.
- **ESLint:** `eslint-config-next` core-web-vitals and TypeScript configs,
  ignoring `.next/`, `out/`, `.agents/`, `.claude/` and `.checks/`.
- **.gitignore:** add `/.checks/` and `.claude/settings.local.json`.

### 4. Folder structure

```
src/app/            layout.tsx, page.tsx, not-found.tsx, sitemap.ts, robots.ts,
                    opengraph-image.tsx, icon.svg, globals.css,
                    kontakt/, impressum/, datenschutz/, <service>/ …
src/lib/            site.ts (SITE, PAGES, NAV, CTA, LEGAL_NAV), <topic>.ts content,
                    json-ld.ts, motion.ts, cn.ts
src/assets/<topic>/ resized photos
src/components/     motion/ ui/ layout/ brand/ contact/ <page>/
src/proxy.ts        noindex on previews
scripts/check-site.mjs
docs/               concept.md, legacy-site/{content.md, assets/}, launch-checklist.md, coding-style.md
.agents/skills/     vendored skills (+ .claude/skills symlink, skills-lock.json)
```

### 5. Research: nothing invented

- **Crawl the old site.** Copy every old page, including the legal notice
  and privacy policy, into `docs/legacy-site/content.md` verbatim, page by
  page under its old URL, typos and all.
- **Collect assets.** Save the logo and every usable photo in the largest
  size to `docs/legacy-site/assets/`, with descriptive names and a table of
  what each shows.
- **Note doubts.** Note everything broken or doubtful (a truncated number,
  conflicting owner names) and carry it into the concept's open questions.
- **Check outside sources.** Search for the business in directories and on
  maps to confirm the facts.

### 6. Concept before any page (`docs/concept.md`)

1. Goal, and 4–6 design principles
2. Scope: in, deferred (with its trigger), out
3. The previous site
4. Locked decisions: stack, rendering, privacy, inquiry handling
5. Brand: colour tokens with roles and contrast, logo, typography
6. Motion: tokens, 3–5 signature moments drawn from the trade, reduced motion
7. Architecture: route table with the content source of each page, content
   modules, inquiry handling, deployment
8. Phased rollout
9. Resolved decisions
10. Open questions, each with a leaning
11. Further considerations: business profile, photography, directories
12. Facts used, and their sources

See [docs-feature-planning-spec](../../../docs/docs-feature-planning-spec/SKILL.md).

### 7. Facts, brand, chrome

```ts
// src/lib/site.ts — the only place an address, a phone number or a legal fact lives
export const SITE = {
  name: "<Business name>",
  url: "https://www.<domain>",
  tagline: "<Trade> in <City>",
  description: "<One true sentence about what they do and where.>",
  schemaType: "HomeAndConstructionBusiness", // schema-dts type matching the trade
  owner: "<Owner name>",
  street: "<Street 1>",
  postalCode: "<12345>",
  city: "<City>",
  country: "DE",
  phone: { display: "<0123 456789>", international: "+49 123 456789", href: "tel:+49123456789" },
  email: "<info@domain>",
  region: ["<City>", "<Neighbouring town>"],
  vatId: undefined as string | undefined, // optional legal blocks render only when present
} as const;

export const PAGES = [
  { path: "/", priority: 1 },
  { path: "/leistungen", priority: 0.8 },
  { path: "/kontakt", priority: 0.6 },
  { path: "/impressum", priority: 0.1 },
  { path: "/datenschutz", priority: 0.1 },
] as const;
```

- **Brand.** Colour tokens with roles and contrast go in `globals.css`, with
  Tailwind's palette switched off. Fonts come through `next/font`. The logo
  is SVG, redrawn if the business only has a raster version, and the owner
  confirms it. The colour comes from the logo and from how the owner
  presents the business.
- **Chrome.** A header that hides while reading down, with an accessible
  phone menu; a footer; a page hero. The root layout starts with a skip link
  and a `main#inhalt`.

### 8. SEO baseline

```tsx
// src/app/layout.tsx (excerpt)
export const ensureStatic = "navigation"; // the build fails if a route stops being static

export const metadata: Metadata = {
  metadataBase: new URL(SITE.url),
  title: { default: `${SITE.name} – ${SITE.tagline}`, template: `%s · ${SITE.name}` },
  description: SITE.description,
  openGraph: { type: "website", locale: "de_DE", siteName: SITE.name },
};
// <html lang="de"> … <JsonLd data={businessJsonLd} /> inside <body>
```

```ts
// src/app/sitemap.ts
export default function sitemap(): MetadataRoute.Sitemap {
  return PAGES.map((page) => ({ url: `${SITE.url}${page.path}`, priority: page.priority }));
}

// src/app/robots.ts
export default function robots(): MetadataRoute.Robots {
  return { rules: { userAgent: "*", allow: "/" }, sitemap: `${SITE.url}/sitemap.xml` };
}

// src/lib/json-ld.ts — only what is true and visible on the site
export const businessJsonLd = {
  "@context": "https://schema.org",
  "@type": SITE.schemaType,
  "@id": `${SITE.url}/#business`,
  name: SITE.name,
  url: SITE.url,
  telephone: SITE.phone.international,
  email: SITE.email,
  ...(SITE.vatId ? { vatID: SITE.vatId } : {}),
  address: {
    "@type": "PostalAddress",
    streetAddress: SITE.street,
    postalCode: SITE.postalCode,
    addressLocality: SITE.city,
    addressCountry: SITE.country,
  },
  areaServed: SITE.region.map((name) => ({ "@type": "City", name })),
};
```

Add the preview-only `noindex` in `src/proxy.ts` (see
[deployer guidelines](../../../../guidelines/deployment/deployer.md)), and a
generated share image in `opengraph-image.tsx`. Never claim ratings,
reviews or opening hours nobody confirmed. Titles and descriptions follow
[marketing-seo-audit](../../../marketing/marketing-seo-audit/SKILL.md).

### 9. Pages, one at a time

The order: home → services (one page each where there is enough to say,
named the way customers search) → work and references (only with real
photos) → about → contact → legal notice → privacy policy → 404.

Each page gets a title, a unique description and a self-canonical, and is
added to `PAGES`. Copy comes from the content modules; photos go through
`next/image` with alt text in the site language. Look at each page in the
browser before starting the next. Copy follows
[marketing-copywriting](../../../marketing/marketing-copywriting/SKILL.md).

The contact page uses the template's `InquiryForm`. It validates name, phone
or email, and a message of at least 10 characters, then composes a
`mailto:` with CRLF line breaks, and says beside the button that it opens
the visitor's mail program. It stores nothing, so the site needs no backend
and only a short privacy section.

### 10. Legal pages

The legal notice and privacy policy render from `SITE` and describe what the
site actually does. Update the privacy policy for every feature the site
adds (a map link, a server form), and set its "as of" date to the current
month. The owner reviews both; the launch checklist asks for it. Details:
[client work](../../../../guidelines/uncategorized/client-work.md).

### 11. Redirects

Every old URL permanently redirects to its closest new page, CMS leftovers
included. A slug change ships with its redirect.

### 12. Checks

```sh
npm run typecheck && npm run lint && npm run format:check
npm run build                       # every route must print ○ (static)
npm start -- -p 3999 &              # never the user's dev server
npm run check -- http://localhost:3999
```

`scripts/check-site.mjs` uses `playwright-core` to open every `PAGES` entry
at desktop and phone widths, saving screenshots to `.checks/`. It fails on
any of these:

- console errors or broken internal links
- a missing title, description or canonical
- a missing `h1`, more than one, or headings out of order
- images without alt text
- horizontal overflow
- placeholder text left on a page

Look at every screenshot. Try the menu, form, filters and lightbox by hand,
and check the motion on the production build
([website-motion](../../website-motion/SKILL.md)).

### 13. Skills

The template already vendors the site's skill set into `.agents/skills/`,
with `.claude/skills` as a symlink to it and `skills-lock.json` recording
sources and hashes. When setting up by hand:

```sh
npx skills add filstawski/playbook --skill code-polish --skill extract-reusable-primitives \
  --skill git-commit-messages --skill git-commit-requires-approval --skill git-pull-requests \
  --skill docs-feature-planning-spec --skill docs-roadmap-notes --skill same-import-upgrade-path \
  --skill design-taste --skill design-interface-polish --skill website-motion \
  --skill marketing-copywriting --skill marketing-seo-audit --skill website-nextjs-site-setup
ln -s ../.agents/skills .claude/skills
```

`AGENTS.md` maps each task type to the skill to read first.

### 14. Hand-over, commit, first preview

- **Hand-over files.** Rewrite `README.md` for the client, replace the
  intro of `AGENTS.md`, and delete `PROMPT.md`.
- **Commit.** Run [code-polish](../../../code-polish/SKILL.md), then make
  small conventional commits without AI attribution, only when asked or
  granted by the prompt. Push `main`.
- **Lockfile.** Re-resolve the lockfile on Linux after any dependency
  change.
- **Preview.** Deploy with
  [deploy-preview-with-deployer](../../../deploy/deploy-preview-with-deployer/SKILL.md),
  and run `npm run check` against the live preview. Expect the noindex note.
- **Report.** The preview URL, the repo, what the site has, and the open
  questions for the owner.

### 15. Launch (later)

`docs/launch-checklist.md`:

- the owner has reviewed copy, facts and logo
- open questions are answered, and the check passes with no TODO left
- a production host is chosen, without the preview environment variable
- `SITE.url` is the one canonical origin, and the other host redirects
- old addresses redirect, verified with `curl -I`
- DNS and TLS work on the bare domain and on `www`
- the old platform is cancelled after the switch
- Search Console is verified and the sitemap submitted
- the business profile matches the legal notice
- a shared link shows the right title, description and image

## Why

The template and this order were frozen after three client sites in a row
used the same stack and steps, and the newest one built from the template
worked the same day. The research-and-concept steps exist because nothing
untrue may appear on a client site. Every fact needs a source, so gaps
become questions instead of invented copy. The static, cookie-free shape
lets the sites ship without a consent banner, which is also part of what is
sold to clients. The check script exists because "it builds" missed broken
pages, placeholder text and phone overflow more than once.

## Exceptions

- **Not for apps.** A site with accounts, a database or a real backend is a
  dashboard or full-stack app; see the
  [nextjs README](../README.md) and the
  [web stack guideline](../../../../guidelines/stacks/web-stack.md).
- **Bilingual sites** add `next-intl`, localized slugs and hreflang (see
  the [websites guideline](../../../../guidelines/frontend/websites.md)).
  Single-language sites never get an i18n library.
- **German legal pages** are written for German businesses. Other
  jurisdictions need their own legal pages.
- **Production hosting** for client sites isn't settled; previews are
  Deployer. See [OPEN_QUESTIONS.md](../../../../OPEN_QUESTIONS.md).

## See also

- [website-motion](../../website-motion/SKILL.md) — the site motion profile and its patterns.
- [design-taste](../../../design/design-taste/SKILL.md) — making the site look like that business, not like the template.
- [marketing-seo-audit](../../../marketing/marketing-seo-audit/SKILL.md) and [marketing-copywriting](../../../marketing/marketing-copywriting/SKILL.md).
