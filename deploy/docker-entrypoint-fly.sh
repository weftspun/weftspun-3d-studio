#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# Start the colocated CockroachDB node and versitygw, wait for both,
# migrate, then exec the release. One container, three processes,
# the RFD 0062 colocation pattern, the same shape character_taxonomy
# already proves on Fly.io for CockroachDB.
#
# versitygw binds 127.0.0.1 only, per RFD 0058's own rule: no port
# goes past loopback unless a remote caller needs it. Only this
# container's own release process reads or writes through it.
set -eu

cockroach start-single-node --insecure \
  --store=path=/data/cockroach \
  --listen-addr=127.0.0.1:26257 \
  --http-addr=127.0.0.1:8081 &
CRDB_PID=$!

: "${VGW_ACCESS_KEY:?VGW_ACCESS_KEY must be set, a Fly secret, not a default}"
: "${VGW_SECRET_KEY:?VGW_SECRET_KEY must be set, a Fly secret, not a default}"
mkdir -p /data/vgw-store/gallery
ROOT_ACCESS_KEY="$VGW_ACCESS_KEY" ROOT_SECRET_KEY="$VGW_SECRET_KEY" \
  versitygw --port 127.0.0.1:10000 posix /data/vgw-store &
VGW_PID=$!

trap 'kill "$CRDB_PID" "$VGW_PID" 2>/dev/null || true' TERM INT

for _ in $(seq 1 60); do
  if cockroach sql --insecure --host=127.0.0.1:26257 -e "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

/app/bin/weftspun_container eval "WeftspunStudio.Release.create()"
/app/bin/weftspun_container eval "WeftspunStudio.Release.migrate()"
exec /app/bin/weftspun_container start
