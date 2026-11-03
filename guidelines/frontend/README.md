# 3. Frontend

Frontend code in React / Next.js: components, code style, framework traps,
and the rules specific to websites.

| File | Covers |
| --- | --- |
| [components.md](components.md) | kit first, `components/ui` only for kit components, primitives on first use, hooks per concern, lean pages, Base UI specifics |
| [code-style.md](code-style.md) | English code with UI text in label modules, placeholders, comments and types, formatting, one source per value, Tailwind discipline |
| [nextjs-and-react.md](nextjs-and-react.md) | server first and hydration, server–client boundary, Next 16 behaviours, stale CSS, forms, mobile web apps, small traps, performance, accessibility |
| [websites.md](websites.md) | template first, static and private, complete HTML, the `SITE` facts module, nothing untrue, images/fonts/headers, bilingual, vendored effects |

## Know these first

- **Use the installed component kit first,** always, and put generic
  mechanics in primitives on first use.
- **Code is English; everything users read is in their language,** from
  label modules.
- **The server HTML is complete,** and the first client render matches it.
- **Every form uses react-hook-form + Zod,** with errors placed correctly.
- **Read the bundled Next.js docs** before using an API.

Related skills: [website-nextjs-dashboard-*](../../skills/website/nextjs/README.md),
[website-nextjs-site-setup](../../skills/website/nextjs/website-nextjs-site-setup/SKILL.md),
[website-motion](../../skills/website/website-motion/SKILL.md),
[extract-reusable-primitives](../../skills/extract-reusable-primitives/SKILL.md),
[code-polish](../../skills/code-polish/SKILL.md).
