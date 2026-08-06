# RFD 0020: CockroachDB persistence for catalog facts

**State:** discussion
**Scope:** `weftspun_studio/`

## Problem

RFD 0019 builds an API server. An API server must keep its data.

The fact store in `WeftspunStudio.FactStore` holds facts in memory.
An Agent rebuilds the store from the RFD 0016 inventory at every
boot. A trust change dies when the node stops, and a retracted fact
comes back.

RFD 0016 records that catalog facts change fast. A license gate
vetoes a model, a benchmark moves a recommendation, and a backend
drops a model. The store must keep those changes.

## Decision

Use the V-Sekai CockroachDB build for storage, and Ecto for the
mapping. The V-Sekai build lives at
`https://github.com/v-sekai/cockroach`, from the Oxide Computer
build of CockroachDB 22.1. The project already depends on that build
elsewhere, so the same build keeps one database version across the
work.

CockroachDB speaks the PostgreSQL wire protocol. Ecto drives it
through `Ecto.Adapters.Postgres`, and no separate adapter is
necessary.

See `DETAILS.md` for why CockroachDB, the schema, local setup, the
settings, the risks, and the verified status.
