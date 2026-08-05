#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
#
# Migrate, then serve. One container, no separate oneshot unit — the
# quadlet path (RFD 0058) keeps that logic here instead of a second
# systemd unit, since the instruction was quadlets only, and a
# migrate-then-exec entrypoint is the ordinary container idiom for it
# anyway.
set -eu

/app/bin/weftspun_container eval "WeftspunStudio.Release.create()"
/app/bin/weftspun_container eval "WeftspunStudio.Release.migrate()"
exec /app/bin/weftspun_container start
