# deploy

How the user's projects get onto servers. There are two paths, and they
never mix:

| Skill | For |
| --- | --- |
| [deploy-preview-with-deployer](deploy-preview-with-deployer/SKILL.md) | temporary preview URLs for branches and client drafts, on the user's self-hosted Deployer |
| [deploy-docker-compose-vps](deploy-docker-compose-vps/SKILL.md) | production (and staging) for apps with a database: Docker Compose per environment on a VPS, behind nginx, images from CI |

How Deployer works, and the rules around both paths, are in
[guidelines/deployment/](../../guidelines/deployment/README.md).

## Reading order

**Showing a client or the user a branch:** `deploy-preview-with-deployer`.
For Deployer's exact commands and error codes, also install its own skill
(`npx skills add filstawski/deployer`, or `deployer skill`); it always
matches the installed CLI.

**Setting up or changing production:** `deploy-docker-compose-vps`, then
[guidelines/ci-cd/](../../guidelines/ci-cd/README.md) for the pipeline
conventions its workflows follow.
