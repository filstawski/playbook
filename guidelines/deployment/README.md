# 11. Deployment (with Deployer)

How the user's projects get onto servers. There are two paths:

1. **Previews.** Every branch and client draft goes to
   [Deployer](https://github.com/filstawski/deployer), the user's
   self-hosted preview tool: a pushed commit becomes
   `https://<name>.<PREVIEW_DOMAIN>` for a chosen lifetime.
2. **Production** for apps with a database: one Docker Compose project per
   environment on a VPS, behind the host's nginx, with images built in
   GitHub Actions. Staging is deployed on every merge; production is
   started by a person, and rollbacks go by commit.

| File | Covers |
| --- | --- |
| [deployer.md](deployer.md) | how Deployer works (binaries, recipe, lifecycle, lifetimes, tokens, GitHub App, limits), plus the rules: previews built from pushes, deploy once and update, deploy only when asked, agents non-interactive, noindex, tokens |
| [production-vps.md](production-vps.md) | Compose behind nginx, files from the image, the previous script runs first, migrations first and expand/contract, health with commit, staging vs production, shared-host hygiene, never touching servers unasked, manual deploys, config naming, walkthroughs, ops commands, backups, domains |

Skills with the full procedures:
[deploy-preview-with-deployer](../../skills/deploy/deploy-preview-with-deployer/SKILL.md)
and [deploy-docker-compose-vps](../../skills/deploy/deploy-docker-compose-vps/SKILL.md).

## Know these first

- **Previews run on Deployer,** never on Vercel, Netlify or GitHub Pages.
- **Deploy only when asked,** and never touch a server unasked.
- **The image carries its own server files;** nothing is copied by hand.
- **Never prune globally** on a shared Docker host.
