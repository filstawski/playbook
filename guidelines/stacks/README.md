# 5. Stacks

Which frameworks, libraries and tools to use, who decides, and why the
alternatives were dropped.

| File | Covers |
| --- | --- |
| [choosing-dependencies.md](choosing-dependencies.md) | the user decides, prefer installed, versions a week old, LTS, exact RC pins, bundled docs, tooling in devDependencies, paired upgrades |
| [web-stack.md](web-stack.md) | the shared base, marketing sites, full-stack dashboards (with rejected alternatives), small libraries, the first background job |

## Know these first

- **Library, version, ORM and provider choices are the user's:** recommend,
  then wait for a yes.
- **Next.js 16, React 19, Tailwind 4, `motion`, lucide-react, npm on Node 24
  LTS** is the base everywhere.
- **Dashboards add** shadcn on Base UI, Postgres + Prisma 8, Better Auth,
  RHF + Zod, pg-boss, Vitest and Playwright.
- **Sites start from a maintained template:** static, with no form backend by
  default.
