#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# Start the colocated CockroachDB node, wait for it, migrate, then
# exec the release. One container, two processes, the RFD 0062
# colocation pattern, the same shape character_taxonomy already
# proves on Fly.io for CockroachDB.
#
# versitygw ran here too, RFD 0073's original S3 target. RFD 0073
# and RFD 0077 both name Tigris as its replacement instead; there is
# no self-hosted gateway to start in this container anymore.
set -eu

cockroach start-single-node --insecure \
  --store=path=/data/cockroach \
  --listen-addr=127.0.0.1:26257 \
  --http-addr=127.0.0.1:8081 &
CRDB_PID=$!

trap 'kill "$CRDB_PID" 2>/dev/null || true' TERM INT

for _ in $(seq 1 60); do
  if cockroach sql --insecure --host=127.0.0.1:26257 -e "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

/app/bin/weftspun_container eval "WeftspunStudio.Release.create()"
/app/bin/weftspun_container eval "WeftspunStudio.Release.migrate()"
exec /app/bin/weftspun_container start
