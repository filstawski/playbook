# api / stack

The default technology choices for a new backend API — the framework
itself, and the auxiliary libraries almost every real project ends up
needing.

1. **[api-framework-stack](api-framework-stack/SKILL.md)** — start here.
   The core stack (typed file-routed framework, Zod, Prisma, Bun/tsx) and
   how the server is composed from plugins, with the full `server.ts`,
   auth plugin, and process-entrypoint code.
2. **[api-default-libraries](api-default-libraries/SKILL.md)** — the
   go-to library per concern once the core stack is in place: object
   storage, image processing, transactional email, payments, DNS/CDN,
   scheduling, archives, schema-derived validation.

See also [../routing](../routing/README.md) for how individual endpoints
are written on top of this stack, and [../managers](../managers/README.md)
for where these libraries (`StorageUpload`'s S3 client, in particular) get
used from business logic.
