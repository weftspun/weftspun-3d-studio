# RFD 0058: Zero trust networking

**State:** published
**Scope:** `weftspun_studio/`, `scripts/deploy-weftspun-quadlet.sh`

## Problem

RFD 0055 selects plain Docker images, on this box first. The router
and the CockroachDB host need a deploy shape on this box too, the
single 4090 RTX box this project develops on.

A perimeter firewall is not a boundary here. The router and the
database run on the same host as every other process the operator
runs. Trust must come from isolation, not from network position.

## Decision

Run weftspun_studio and its CockroachDB host as Podman Quadlets. A
Quadlet is a `.container`, `.volume`, `.network`, or `.build` file.
`podman-system-generator` reads it and writes a systemd service.

Write no hand-written `.service` file. Each unit here is a Quadlet
file under `weftspun_studio/deploy/quadlet/`.

See `DETAILS.md` for the two zero-trust mechanisms, and why
CockroachDB replaces the ZooKeeper Manta's metadata tier needed. It
also covers the two images, the migrate-before-serve entrypoint, two
boot bugs this RFD found and fixed, the deploy command, and the
verified status.

## Related

RFD 0019 gives the API server. RFD 0020 pins the CockroachDB build.
RFD 0037 gives the taskweft job/task split. RFD 0055 selects Docker
images, on this box first. RFD 0057 tracks what is still open.
