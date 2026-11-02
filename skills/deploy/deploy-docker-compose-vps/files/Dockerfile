# syntax=docker/dockerfile:1

# The production image: Next.js's standalone server on Node 24 (an LTS: .nvmrc, this base image and
# @types/node move to the next LTS together, as one step). Debian slim rather than Alpine, so native
# binaries are the same glibc builds CI tests with.
FROM node:24-slim AS base
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

FROM base AS deps
COPY package.json package-lock.json ./
# npm's downloads stay with the builder between builds, out of the image: a changed lockfile
# downloads only what it changed.
RUN --mount=type=cache,target=/root/.npm npm ci

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Public build-time settings (NEXT_PUBLIC_*) are build args: Next writes them into the bundles.
#   ARG NEXT_PUBLIC_SOMETHING
# A token the build needs but the image must never keep (an error tracker's source-map upload, say)
# comes as a BuildKit secret: there for this one RUN, in no layer and no image history. Without it,
# as in CI's pull-request build, the build runs as usual.
#
# `npm run build` must leave a complete server in .next/standalone (next.config: output
# "standalone"): Next's server.js and, from the app's postbuild script, migrate.mjs (applies pending
# migrations, then exits), worker.mjs if the app has a worker, and whatever they read at runtime
# (the migrations' folder). Each is bundled into one file, so the image needs neither the whole
# node_modules nor the ORM's CLI. The static files and public/ are copied in here, so the image
# also works where postbuild doesn't copy them itself.
RUN --mount=type=secret,id=sentry_auth_token,env=SENTRY_AUTH_TOKEN \
    npm run build \
 && cp -R .next/static .next/standalone/.next/ \
 && if [ -d public ]; then cp -R public .next/standalone/; fi \
 && { test -f .next/standalone/server.js && test -f .next/standalone/migrate.mjs \
      || { echo "The build left no server.js or migrate.mjs in .next/standalone (see the comment above)." >&2; exit 1; }; }

FROM base AS runner
# Links the image GHCR publishes to the repository, whose access it then shares.
LABEL org.opencontainers.image.source="https://github.com/<ORG>/<APP>"
# HOSTNAME: Docker sets it to the container's id, and server.js listens on HOSTNAME, so without this
# it wouldn't answer on 127.0.0.1 inside the container, where the healthcheck asks.
ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0
RUN groupadd --system --gid 1001 nodejs && useradd --system --uid 1001 --gid nodejs nextjs
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# What runs the image on a server: deploy.sh takes compose.yaml, the nginx site and itself from the
# image it deploys, so they change with the release and a rollback brings the older ones back.
COPY deploy ./deploy
# The commit the image was built from, for /api/health and the worker, read at runtime: a
# NEXT_PUBLIC_ variable would reach only what `next build` bundles, never a separately bundled
# worker. Last, so a new commit rebuilds only this layer.
ARG BUILD_COMMIT
ENV BUILD_COMMIT=${BUILD_COMMIT}
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
