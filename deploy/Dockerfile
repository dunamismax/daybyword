# The daybyword.com web image (BUILD.md PM.18, docs/deploy.md): the SvelteKit
# production server (web/server.ts around adapter-node's build) and the
# one-shot migration and catalog-import jobs, on pinned Node, run as the
# image's unprivileged `node` user. Built from the repository root after
# `make catalog-export`:
#
#   docker build -f deploy/Dockerfile --build-arg DBW_COMMIT=<sha> -t daybyword-web:<sha> .
#
# Base images are pinned by multi-platform index digest (amd64 and arm64).
ARG NODE_IMAGE=node:26.13.0-trixie-slim@sha256:5adad64f9a1fca2d51972caa65983634c8a774eb300d72b20f7f2a0f60368072

FROM ${NODE_IMAGE} AS build
WORKDIR /app
COPY web/package.json web/package-lock.json web/.npmrc ./
# No install scripts: svelte-kit sync runs as part of the build below.
RUN npm ci --ignore-scripts --no-audit --loglevel=error
COPY web/ ./
RUN npx vite build --logLevel warn && npm prune --omit=dev --ignore-scripts --no-audit --loglevel=error

FROM ${NODE_IMAGE} AS runtime
ARG DBW_COMMIT=""
LABEL org.opencontainers.image.title="daybyword-web" \
      org.opencontainers.image.revision="${DBW_COMMIT}"
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000 \
    BODY_SIZE_LIMIT=64K \
    DBW_ENV=production \
    DBW_COMMIT=${DBW_COMMIT}
WORKDIR /app
# Owned by root and only readable by `node`: the running server cannot
# change its own code.
COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/build ./build
COPY --from=build /app/server.ts ./server.ts
COPY --from=build /app/scripts/db-migrate.ts /app/scripts/catalog-import.ts ./scripts/
COPY --from=build /app/src/lib/server ./src/lib/server
COPY --from=build /app/drizzle ./drizzle
COPY build/catalog/catalog-export.json /app/catalog/catalog-export.json
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/up').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))"]
CMD ["node", "server.ts"]
