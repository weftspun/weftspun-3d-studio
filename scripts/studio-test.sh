#!/usr/bin/env bash
# Runs the weftspun_studio suite, or says why it cannot.
#
# RFD 0019 selects EXLA, and RFD 0056 moves development into a dev
# container because XLA publishes no Windows archive. A Windows host
# therefore cannot build the application at all.
#
# This script skips there, and it names the reason. A hook that failed
# instead would block every commit from that host, including a commit
# that only touches an RFD.
#
# It does not skip a real failure. Only the two conditions below skip,
# and each one is a fact about the host and not about the code.
set -uo pipefail

cd "$(dirname "$0")/../weftspun_studio" || exit 1

skip() {
  echo "skipped: $1"
  echo "         RFD 0056 records the dev container, which runs this suite."
  exit 0
}

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    skip "XLA publishes no Windows archive, thus EXLA cannot build here"
    ;;
esac

command -v mix >/dev/null 2>&1 || skip "mix is absent from this host"

# CockroachDB backs the database tests, and the mix test alias creates
# a database before it runs one test. A host with no node reports a
# connection refusal that says nothing about the code.
if ! timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/26257' 2>/dev/null; then
  skip "no CockroachDB on 127.0.0.1:26257, which mix weftspun.crdb starts"
fi

exec mix test
