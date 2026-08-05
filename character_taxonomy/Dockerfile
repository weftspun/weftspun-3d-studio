# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# character_taxonomy, containerized, with its own colocated
# CockroachDB — the RFD 0062 pattern, on a Fly Volume, for a second,
# separate deploy target from weftspun_studio's.
#
# One image runs two processes: `cockroach start-single-node` against
# the mounted volume, and the character_taxonomy release. The
# entrypoint starts cockroach, waits for it, migrates (which includes
# the RFD 0065 seed migration), then execs the release in the
# foreground.

ARG BASE_TAG=1.20.3-erlang-29.0.5-debian-bookworm-20260803-slim
ARG COCKROACH_TAG=v22.1.64b21683521d9a8735ad

FROM docker.io/hexpm/elixir:${BASE_TAG} AS build

ENV MIX_ENV=prod
WORKDIR /build

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY lib lib
COPY priv priv
COPY config config
RUN mix deps.compile && mix compile
RUN mix release character_taxonomy --path /build/_release

FROM docker.io/library/debian:bookworm-slim AS runtime

ARG COCKROACH_TAG
ARG TARGETARCH=amd64

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libstdc++6 openssl libncurses6 locales ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

# Same V-Sekai CockroachDB build weftspun_studio's own
# deploy/Dockerfile.crdb pins. RFD 0020 selects it.
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) asset="cockroach-${COCKROACH_TAG}.linux-amd64.tgz" ;; \
      *) echo "unsupported arch: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 -o /tmp/crdb.tgz \
      "https://github.com/V-Sekai/cockroach/releases/download/${COCKROACH_TAG}/${asset}"; \
    mkdir -p /tmp/crdb; \
    tar -xzf /tmp/crdb.tgz -C /tmp/crdb; \
    bin="$(find /tmp/crdb -maxdepth 2 -type f -name cockroach | head -n1)"; \
    install -m 0755 "$bin" /usr/local/bin/cockroach; \
    rm -rf /tmp/crdb /tmp/crdb.tgz

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV TAXONOMY_DB_HOST=127.0.0.1
ENV PORT=8080
ENV MCP_PORT=4001

WORKDIR /app
COPY --from=build /build/_release ./
COPY deploy/docker-entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh \
    && mkdir -p /data/cockroach

EXPOSE 8080 4001
ENTRYPOINT ["/app/entrypoint.sh"]
