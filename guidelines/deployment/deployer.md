# Previews with Deployer

[Deployer](https://github.com/filstawski/deployer) is the self-hosted tool
that turns a pushed branch into a temporary preview URL. It is the default
for every branch and client preview. The step-by-step procedure is the skill
[deploy-preview-with-deployer](../../skills/deploy/deploy-preview-with-deployer/SKILL.md);
Deployer's own agent skill (`npx skills add filstawski/deployer`, or
`deployer skill`) is the reference for every command and flag, and always
matches the installed CLI.

## How it works

- **Two binaries.** `deployer` is the CLI for macOS, Linux and Windows, a
  thin HTTP client. `deployerd` runs on one Linux server as a systemd
  service: an API, a durable operation queue, a reconciler, a BuildKit
  builder, and a gateway container that routes `<name>.<PREVIEW_DOMAIN>` to
  the right preview. State is one SQLite file.
- **One preview is one container.** Each is built from the repo's
  `Dockerfile` at a pushed commit, on its own internal network, with no
  published ports, 1 CPU / 512 MiB, and no outbound internet unless the
  server enables it. The host's nginx terminates TLS with a wildcard
  certificate.
- **A recipe file.** Each project describes itself in a root
  `deployer.yaml`: the Dockerfile, the HTTP port and a health check. Plain,
  non-secret environment values only, because the file is committed.
- **Lifecycle.** queued → building → starting → running ⇄ stopped, then
  expired, failed, or destroyed. Visitors see a progress page while it
  builds, 410 once it has expired, and 502 if the app doesn't answer.
  `update` builds the new commit while the old one keeps serving, swaps, and
  rolls back on failure.
- **Lifetimes.** A preview's lifetime starts when it first becomes healthy;
  visits don't extend it and stopping doesn't pause it. Server defaults are
  1 day by default and 7 days at most; an admin raises
  `deployments.max_ttl` in the server config for 14–30 day client previews.
  Expired and failed previews are purged after a retention period.
- **Access.** Bearer tokens with roles (`deployer`, `viewer`, `admin`) and
  optional per-project scope. Permissions can't be edited: create a new
  token, switch to it, revoke the old one. Phones pair by QR code with the
  Android app.
- **Private repos.** Private GitHub repos are read through a GitHub App with
  read-only contents access, installed per account. Public HTTPS repos need
  nothing.
- **Not yet.** Compose, secrets, volumes, databases and PR-triggered
  previews are on the roadmap. An app must start and pass its health check
  with no external calls and no real credentials.
- **History.** Deployer replaced an earlier tool that published static
  exports to GitHub Pages in throwaway repositories (Sep–Oct 2026). Don't use
  that tool, or Vercel/Netlify/GitHub Pages, for previews.

## Previews run on Deployer, built from what is pushed

**MUST** · 2026-10 → 2026-11 · client sites, websites, dashboard apps

The server only sees pushed commits, never local files. Commit and push
first, then deploy. Every previewable repo has a `Dockerfile` and a root
`deployer.yaml`, validated before pushing (`deployer validate`).

**Why:** the server fetches the commit from the Git host, so a preview of
unpushed work shows the old commit, and the CLI only warns about unpushed
changes on stderr.

## Deploy once, then update in place

**SHOULD** · 2026-10 → 2026-11 · client sites

Create a preview once with a short name and a deliberate lifetime (14 days
for a client preview), then run `deployer update <name>` after each push, so
the URL a client already has keeps working. Extending keeps the same URL
too. Every deploy report states the URL, the expiry date and the extend
command. Before a client meeting, check the preview's expiry and pinned
commit. "Is the latest version deployed?" is answered by
`deployer inspect`, not by looking at GitHub.

## Deploy only when asked

**MUST** · 2026-11 · company website

Don't run Deployer, touch DNS or touch a server unless the user asked for it
in that task. When you were asked to deploy and keep a preview current,
updating it after each push is part of that job. Otherwise, after a push,
offer to refresh the preview instead of doing it.

## Agents drive Deployer non-interactively

**MUST** · 2026-10 · deployer

- Run `deployer status --json` first. Exit code 3 means you aren't logged
  in: ask the user for a URL and token, never guess.
- Deploy with `--json` and an idempotency key, and read the exit code
  before `error.code` and `error.hint`.
- Don't retry `BUILD_FAILED` or `HEALTHCHECK_FAILED` unchanged; read
  `deployer logs <name> --build` first.
- Manage only previews you created. Destroy your failed ones, because they
  count toward the server's limit.
- Never run `token`, `server` or `github` admin commands.

**Why:** without a terminal the CLI never prompts, and with `--json` it
prints exactly one JSON value on stdout. These are the rules the tool's own
agent skill encodes.

```sh
deployer status --json
deployer validate --json
deployer deploy --ref feat/contact-form --name contact-form --ttl 14d \
  --idempotency-key task-123-contact-form --json
```

## Keep previews out of search engines

**SHOULD** · 2026-10 → 2026-11 · client sites, company website

A preview answers `X-Robots-Tag: noindex, nofollow`, and its canonical URLs
point at the real domain. Deployer's gateway adds the header when the app
doesn't. Sites also set it themselves when `DEPLOYER_URL` is present, which
Deployer injects only at preview runtime, so the same build stays indexable
in production. Production must never set `DEPLOYER_URL`.

**Why:** an early preview was indexable while its canonicals named the
client's real domain, risking duplicate content with the old site.

```ts
// src/proxy.ts (Next.js 16; `middleware.ts` exporting `middleware` before 16)
import { NextResponse } from "next/server";

/** Previews answer noindex; the same build on the real host stays indexable. */
export function proxy() {
  const response = NextResponse.next();
  if (process.env.DEPLOYER_URL) response.headers.set("X-Robots-Tag", "noindex, nofollow");
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image).*)"],
};
```

## Give each person, machine and agent its own token

**SHOULD** · 2026-10 · deployer

CI jobs and agents get project-scoped tokens, read-only observers get
`viewer`, phones pair with `deployer pair`. Send a token over a private
channel (a password manager share), never in a commit, a chat log or a URL.
