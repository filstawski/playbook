---
name: api-default-libraries
description: >-
  The specific libraries reached for by default to cover common backend
  needs — S3-compatible object storage, image processing, transactional
  email, payments, DNS/CDN management, in-process scheduling, streaming
  archives, human-readable random strings, and schema-derived validation —
  each with a short real usage snippet. Use when starting a backend feature
  that needs file uploads, email sending, billing, cron jobs, or zip/archive
  generation, to skip re-researching which package to pick.
metadata:
  type: practice
  category: tooling
---

## Rule

One default library per concern, chosen once under real constraints, so
picking a package isn't a fresh research task at the start of every
project.

### Object storage — `@aws-sdk/client-s3` (+ `lib-storage`, `s3-request-presigner`)

S3-compatible object storage — works against AWS S3, Cloudflare R2, MinIO,
or anything else speaking the S3 API — via the official AWS SDK v3 directly,
not a wrapper library. `@aws-sdk/lib-storage`'s `Upload` handles multipart
upload for large files without hand-rolling chunking logic.
`@aws-sdk/s3-request-presigner` generates signed URLs for direct
client-to-storage upload/download so large file bytes never have to be
proxied through the API process.

```ts
import { S3Client, PutObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";

export const s3 = new S3Client({
  region: "auto",
  endpoint: process.env.S3_ENDPOINT,
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY_ID!,
    secretAccessKey: process.env.S3_SECRET_ACCESS_KEY!,
  },
});

await s3.send(
  new PutObjectCommand({
    Bucket: "uploads",
    Key: key,
    Body: buffer,
    ContentType: mime,
  }),
);
```

For large uploads, swap the plain `PutObjectCommand` for `lib-storage`:

```ts
import { Upload } from "@aws-sdk/lib-storage";

const upload = new Upload({
  client: s3,
  params: { Bucket: "uploads", Key: key, Body: fileStream, ContentType: mime },
});
await upload.done();
```

Signed URL for a client to upload/download directly:

```ts
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const url = await getSignedUrl(
  s3,
  new PutObjectCommand({ Bucket: "uploads", Key: key }),
  { expiresIn: 900 },
);
```

### Image processing — `sharp` + `image-size` + `blurhash`

`sharp` for resize/recompress on upload — native bindings, fast, handles
format conversion. `image-size` reads width/height straight from a buffer's
header without a full decode when only dimensions are needed. `blurhash`
computes a tiny placeholder string for progressive image loading on the
client (show the blurhash immediately, swap in the real image once loaded).

```ts
import sharp from "sharp";
import imageSize from "image-size";
import { encode } from "blurhash";

const compressed = await sharp(originalBuffer)
  .rotate() // respect EXIF orientation before it gets stripped
  .jpeg({ quality: 80 })
  .toBuffer();

const { width, height } = imageSize(compressed);

const { data, info } = await sharp(compressed)
  .raw()
  .ensureAlpha()
  .resize(32, 32, { fit: "inside" })
  .toBuffer({ resolveWithObject: true });
const hash = encode(new Uint8ClampedArray(data), info.width, info.height, 4, 4);
```

### Transactional email — `resend` + `mjml` + `handlebars`

`resend` as the sending API — a simple REST client with good deliverability
defaults out of the box, no SMTP config to manage. `mjml` to author
responsive email markup that compiles down to the table-based HTML old
email clients actually need, instead of hand-writing that HTML directly.
`handlebars` for the variable-interpolation layer on top of the compiled
MJML output (names, links, subject lines) so templates stay editable by
someone who isn't touching application code and contain no branching logic
of their own.

```ts
import mjml2html from "mjml";
import Handlebars from "handlebars";
import { resend } from "@/lib/resend";

const { html: compiled, errors } = mjml2html(mjmlSource);
if (errors.length) throw new Error(`MJML compile failed: ${errors[0].message}`);

const html = Handlebars.compile(compiled)({ userName, actionUrl });

await resend.emails.send({
  from: "notifications@example.com",
  to: user.email,
  subject: "Your export is ready",
  html,
});
```

### Payments — `stripe`

The official SDK, used directly rather than through a "provider-agnostic"
billing abstraction — payment providers differ enough in webhook shape and
edge cases (proration, disputes, delayed payment methods) that abstracting
over them usually just hides Stripe-specific behavior badly, without
actually making a provider swap easier in practice. Webhook routes verify
the signature before touching the payload, using the **raw** request body
(not the framework's parsed JSON — signature verification needs the exact
bytes Stripe signed):

```ts
const event = stripe.webhooks.constructEvent(
  rawBody,
  request.headers.get("stripe-signature")!,
  process.env.STRIPE_WEBHOOK_SECRET!,
);

switch (event.type) {
  case "checkout.session.completed":
    // ...
    break;
}
```

### DNS / CDN management — `cloudflare`

The official Cloudflare SDK. Used for zone/DNS record management in a
multi-tenant "bring your own custom domain" feature (create a zone per
customer domain, poll for nameserver verification) and for purging a
specific URL from cache right after a mutation makes a CDN-cached response
stale.

```ts
const zone = await cloudflare.zones.create({
  name: "customer-domain.com",
  account: { id: process.env.CLOUDFLARE_ACCOUNT_ID },
});

await cloudflare.cache.purge({
  zone_id: process.env.CLOUDFLARE_ZONE_ID!,
  files: [purgedUrl],
});
```

### Scheduling — `croner`

In-process cron for periodic jobs — daily resets, expiring stale rows,
sweep-and-delete tasks. Lighter than standing up an external scheduler when
jobs are simple, don't need distributed locking, and the API process is
already always-on.

```ts
import { Cron } from "croner";

new Cron("0 3 * * *", async () => {
  await expireStaleSessions();
});
```

### Streaming archives — `archiver`

Streaming zip creation for bulk-download endpoints — pipe files into the
archive and stream the archive straight to the HTTP response instead of
buffering the whole zip in memory (which falls over the moment a "bulk
download" request covers more than a handful of files).

```ts
import archiver from "archiver";

const archive = archiver("zip");
archive.pipe(responseStream);
for (const file of files) {
  archive.append(await downloadFile(file.key), { name: file.filename });
}
await archive.finalize();
```

### Human-readable random strings — `eff-diceware-passphrase`

For anywhere a random identifier is user-facing — share codes, invite
codes, auto-generated display names — and "readable and memorable" beats
"opaque hex string." Uses the EFF's diceware wordlist to produce multi-word
passphrases (`correct-horse-battery-staple`-style) instead of a random
token nobody can read over the phone.

### Schema-derived validation — `prisma-zodify`

Generates Zod schemas straight from the Prisma schema at build time,
instead of hand-writing a parallel Zod shape for every model's raw DB row.
Hand-written Zod schemas still get layered on top for actual input
validation (a `create` payload is narrower than the full DB row, and often
has refinements the DB schema can't express) — this only removes the
busywork of re-typing the *raw row* shape by hand and keeping it in sync
with migrations.

### Runtime path aliases — `tsconfig-paths`

Makes `@/lib/...`-style path aliases declared in `tsconfig.json` resolve at
runtime under `tsx`/`ts-node`, without needing a bundler step in dev to
rewrite import paths.

## Why

Re-deciding "which S3 client" or "which email library" from scratch every
new project is wasted effort on an already-solved problem, and it produces
inconsistent choices across projects for zero benefit. Each pick above was
made once under a real constraint (multipart upload support, old-email-client
HTML compatibility, multi-tenant DNS provisioning) — the reasoning is worth
keeping attached to the choice so it doesn't get silently re-litigated (or
worse, re-decided worse) on the next project.

## Exceptions

- A different S3-compatible provider's own SDK can still make sense if it
  has meaningfully better ergonomics for a specific feature it's uniquely
  good at (provider-native lifecycle rules, say). The AWS SDK is the
  default because it's provider-agnostic, not because it's always the best
  fit.
- Below a couple of scheduled jobs, in-process `croner` is fine. Past that
  — many jobs, a need for retries/backoff, or more than one API instance
  running the same schedule — move to a real job queue/external scheduler
  instead of scaling `croner` usage past what it's meant for.
- Stripe specifically assumes one payment provider. If a product genuinely
  needs multiple providers from day one, that's a materially different (and
  harder) problem than "which SDK," and this default doesn't apply.

## See also

- [api-framework-stack](../api-framework-stack/SKILL.md) — the core routing/validation/ORM stack these libraries plug into.
- [api-manager-base](../../managers/api-manager-base/SKILL.md) — `StorageUpload` (built on the S3 client here) is used from a manager's `create` method.
