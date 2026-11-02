# 10. CI/CD

Pipelines, dependency hygiene, tests in CI, and releases. Complete workflow
files are in the
[deploy-docker-compose-vps](../../skills/deploy/deploy-docker-compose-vps/SKILL.md)
skill.

| File | Covers |
| --- | --- |
| [pipelines.md](pipelines.md) | full CI from day one, steps as project scripts, concurrency/permissions/timeouts, running only what's needed, manual triggers, the image check, action versions, platform jobs, no bypassing red |
| [dependencies-and-lockfiles.md](dependencies-and-lockfiles.md) | Linux lockfiles, no node_modules cache, two-week-old security fixes, separate advisory PRs, minimal additions, asking before bumps |
| [testing-in-ci.md](testing-in-ci.md) | isolated e2e, deterministic tests, reduced motion in e2e, classifying red jobs, shared runners and heavy-step slots, credential-free URLs, seed scripts, the site page check |
| [releases.md](releases.md) | tag after green and verify, blocked tag pushes, version bumps, container images per commit |

## Know these first

- **Resolve the lockfile on Linux after every dependency change.**
- **Never cache `node_modules` between CI runs.**
- **Never write a credential-shaped URL,** not even in a test.
- **Classify a red job before re-running it,** and debug a test that fails
  twice.
