# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# usd_viewer_app, its own deployed app, apart from weftspun_studio's
# own images, the same separation character_taxonomy/ already has
# (its own Dockerfile, its own Fly app). RFD 0076.
#
# Two stages: build the Vite/usd-viewer bundle, then run it behind
# server.js, a small dependency-free static server. Neither stage
# needs Elixir; this app has none.

ARG NODE_TAG=22-bookworm-slim

FROM docker.io/library/node:${NODE_TAG} AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY patches patches
RUN npm ci
COPY index.html vite.config.js ./
COPY public public
RUN npm run build

FROM docker.io/library/node:${NODE_TAG} AS runtime
RUN useradd --system --no-create-home --shell /usr/sbin/nologin usdviewer
WORKDIR /app
COPY --from=build --chown=usdviewer:usdviewer /app/dist dist
COPY --chown=usdviewer:usdviewer server.js ./

ENV PORT=8090
USER usdviewer
EXPOSE 8090
HEALTHCHECK --interval=15s --timeout=5s CMD node -e "fetch('http://127.0.0.1:'+process.env.PORT+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "server.js"]
