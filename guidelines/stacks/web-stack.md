# Web stack

The default stacks as of November 2026, with the reasoning and the
alternatives that were tried and dropped. Install whatever versions are
current when scaffolding (see [choosing-dependencies.md](choosing-dependencies.md));
the majors named here are a snapshot.

## Shared base for every web project

**SHOULD** · 2026-09 → 2026-11 · websites, dashboard apps (6 sources)

| Layer | Choice |
| --- | --- |
| Framework | Next.js 16, App Router, Cache Components, typed routes |
| UI runtime | React 19, TypeScript |
| Styling | Tailwind CSS 4 (CSS-first `@theme`) |
| Motion | `motion` (`motion/react`), see [website-motion](../../skills/website/website-motion/SKILL.md) |
| Icons | `lucide-react` |
| Package manager | npm, Node 24 LTS (`.nvmrc`, `engines`) |
| Formatting | Prettier with `prettier-plugin-tailwindcss` |

**Why:** this set held up across three consecutive projects, so it was
frozen into the website template. Node went back to 24 because 25 had
reached end of life.

**Changed:** until early October some sites used pnpm, plain CSS, Phosphor
icons, PostCSS Tailwind and static export to GitHub Pages. Those were
dropped once the set above had survived three consecutive projects.

## Marketing and brochure sites

**SHOULD** · 2026-10 → 2026-11 · client sites, company website

Start from a maintained website template, never from a bare `create-next-app` (see
[website-nextjs-site-setup](../../skills/website/nextjs/website-nextjs-site-setup/SKILL.md)).
On top of the shared base:

- Tailwind through `@tailwindcss/turbopack`. No `tailwind-merge`: a ten-line
  `cn()` that joins class names is enough on a site.
- `motion` loaded lazily (`LazyMotion` + `m.*`) to keep the bundle small.
- `schema-dts` for typed JSON-LD, and `playwright-core` for the page check
  script.
- No i18n library on single-language sites. `next-intl` only when the
  audience really needs two languages (see
  [../frontend/websites.md](../frontend/websites.md)).
- No form backend by default: a validated `mailto:` inquiry form keeps the
  site static and cookie-free. A server action with a mail provider is a
  written roadmap step, built when a real need (attachments, CRM hand-off)
  appears.

**Why:** the user wants to turn out good-quality sites quickly, and every
earlier site re-derived the same stack and rules by hand from the previous
one.

**Rejected:** CSS conic-gradient "metal" effects, effect packages that hide
content until JavaScript paints, smooth-scroll libraries, GSAP.

## Full-stack dashboard apps

**SHOULD** · 2026-10 → 2026-11 · dashboard apps (3 apps)

On top of the shared base:

| Concern | Choice | Rejected / why |
| --- | --- | --- |
| UI kit | shadcn on **Base UI** (base flavour), wrappers you own | Radix flavour in older projects; cmdk (the kit's Command is enough) |
| Database | Postgres 18 in Docker, UUIDv7 ids, `timestamptz` | SQLite (fine for a first prototype only) |
| ORM | Prisma 8 (the user's pick, pinned exactly while RC) | Prisma 7: don't downgrade without asking |
| Auth | Better Auth: sign-up off, admins create accounts, TOTP 2FA, passkeys, rate limiting | NextAuth / Auth.js |
| Forms | react-hook-form + Zod 4 | — |
| Jobs | pg-boss in its own worker container | timers inside the web process |
| Realtime | refresh on focus or interval first; Postgres LISTEN/NOTIFY → SSE when live updates matter | WebSockets (need a custom server, skip session checks) |
| Files | self-hosted S3-compatible store via AWS SDK v3 + presigner | MinIO (archived) |
| Email | Resend + React Email | — |
| Errors | Sentry, EU region, data collection off by default, pinned exactly | — |
| Tests | Vitest (unit, and integration against real Postgres) + Playwright | — |
| Charts | small hand-built SVG components | chart libraries, for a first reports section |
| PDFs | Typst CLI, pinned with checksums; layouts in code, branding editable | react-pdf and HTML+Chromium for a document system |

The existing playbook skills for this kind of app
([website-nextjs-fullstack-*](../../skills/website/nextjs/README.md)) still
describe the architecture.

**Changed:** the dashboard skills written in September use Radix-based
shadcn and TanStack Query for a thin client over an external API. Apps built
since October own their backend and use Base UI-based shadcn.

## Small libraries that earned their place

**CONSIDER** · 2026-10 · dashboard apps

| Job | Library |
| --- | --- |
| One-time-code input | `input-otp` |
| QR codes | `uqr` |
| Phone normalisation for duplicate checks | `libphonenumber-js/min` |
| Date picking | `react-day-picker` via the kit's Calendar |
| Natural-language dates | `chrono-node` |
| Streamed server-side ZIPs | `client-zip`, no compression, since PDFs and scans don't shrink |
| Bundling a worker | `esbuild` |
| Encrypting backups | `age` |

## First background job: in-process, shaped like the real queue

**CONSIDER** · 2026-08 · API project

For the first job in a backend that has no queue yet, build a small
in-process runner with a typed job registry and a concurrency cap, and give
it the API of the queue you expect to move to. The later move then changes
no call sites. See
[same-import-upgrade-path](../../skills/same-import-upgrade-path/SKILL.md).
