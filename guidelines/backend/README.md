# 4. Backend

Server-side code for apps with their own backend: architecture, auth and
permissions, data and migrations, security and testing. None of this is a
default for a static site or a single-user tool.

| File | Covers |
| --- | --- |
| [architecture.md](architecture.md) | feature modules, repository-only DB access, import cycles, catalogues of definitions, abstraction budget, v2 rewrites, error mapping, mock-first, reuse models |
| [auth-and-permissions.md](auth-and-permissions.md) | every entry point declares access, roles as data, re-asking passwords, security emails, sign-in hardening, auditing the auth library, scope selectors |
| [data-and-migrations.md](data-and-migrations.md) | never edit applied migrations, expand/contract, hand-written migrations and Prisma 8 notes, side effects in one transaction, revisions, modelling, history, block/trash/purge, numbers, time zones, audit, demo data |
| [security-and-testing.md](security-and-testing.md) | secrets out of logs and URLs, render without side effects, SSRF, uploads, share links, crash-safe operations, real dependencies in tests, local infrastructure |

## Know these first

- **Only a feature's repository touches the database;** this is enforced by
  lint.
- **Every page, query, action and route declares who may call it.** Server
  Actions are public endpoints.
- **Roles are data and permissions are code.** Never check a role name or a
  person.
- **Never edit a migration that may have run anywhere;** write migrations
  expand/contract.
- **Side effects are written in the same transaction** as the change.

Related skills: [website-nextjs-fullstack-*](../../skills/website/nextjs/README.md),
the [api skills](../../skills/api/README.md),
[same-import-upgrade-path](../../skills/same-import-upgrade-path/SKILL.md).
