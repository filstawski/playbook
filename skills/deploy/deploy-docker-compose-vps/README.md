# deploy-docker-compose-vps — sources

Written from the user's own work, October 2026: the production and staging
setup of a multi-role dashboard app (its deploy folder, Dockerfile,
workflows, health route, runbooks and the fix commits behind each guard),
the copy of that setup for a second app, and a hand-run demo deployment for
a client.

The files in [files/](files/) are generalized versions of the real ones:
organization, repository, host and domain names are placeholders,
app-specific services are removed, and the build-commit check was extended
from CI to the deploy script. They pass shell, YAML, nginx and type checks,
but have not been deployed as a set; run them on a scratch server first.
No third-party skill was used.
