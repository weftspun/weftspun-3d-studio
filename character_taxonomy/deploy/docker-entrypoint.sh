#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# Start the colocated CockroachDB node, wait for it, migrate (which
# runs the RFD 0065 seed migration on a fresh volume), then exec the
# release. One container, two processes, the RFD 0062 colocation
# pattern for this second, separate deploy target.
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

/app/bin/character_taxonomy eval "CharacterTaxonomy.Release.create()"
/app/bin/character_taxonomy eval "CharacterTaxonomy.Release.migrate()"
exec /app/bin/character_taxonomy start
