# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# weftspun_studio, containerized. RFD 0055 Phase 2 step 1.
#
# This is a plain `mix release`, not the Burrito single binary. A
# container image is already the distribution unit Podman quadlets
# want, so Burrito's job — carrying Elixir/Erlang to a host that has
# neither — is redundant here. The bare-metal Burrito path documented
# in RFD 0019 and RFD 0058 still exists for a host with no Podman.
#
# `application.ex` only reaches WeftspunStudio.CLI when argv is
# non-empty, so `bin/weftspun start` (argv == []) boots the
# supervisor and blocks, and `bin/weftspun eval` / `bin/weftspun db
# migrate`-style invocations still route through the CLI. RFD 0058
# records the fix and why the halt-after-boot bug existed.

# Elixir 1.20 / Erlang OTP 29, matching the versions this repo
# already develops against (mix.exs requires "~> 1.17" as a floor,
# not a ceiling).
ARG BASE_TAG=1.20.3-erlang-29.0.5-debian-bookworm-20260803-slim

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

# The `weftspun_container` release (mix.exs) skips the Burrito step —
# inside a container the image itself is the distribution unit, so
# wrapping the release again would just add a Zig dependency for
# nothing.
RUN mix release weftspun_container --path /build/_release

FROM docker.io/library/debian:bookworm-slim AS runtime

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libstdc++6 openssl libncurses6 locales ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV WEFTSPUN_SERVE=1
ENV WEFTSPUN_PORT=4000

RUN useradd --system --no-create-home --shell /usr/sbin/nologin weftspun
WORKDIR /app
COPY --from=build --chown=weftspun:weftspun /build/_release ./
COPY --chown=weftspun:weftspun deploy/docker-entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
USER weftspun

EXPOSE 4000
ENTRYPOINT ["/app/entrypoint.sh"]
