# RFD 0020: CockroachDB persistence for catalog facts

**State:** discussion
**Scope:** `weftspun_studio/`

## Problem

RFD 0019 builds an API server. An API server must keep its data.

The fact store in `WeftspunStudio.FactStore` holds facts in memory.
An Agent rebuilds the store from the RFD 0016 inventory at every
boot. A trust change dies when the node stops. A retracted fact comes
back.

RFD 0016 records that catalog facts change fast. A licence gate
vetoes a model. A benchmark moves a recommendation. A backend drops a
model. The store must keep those changes.

## Decision

Use the V-Sekai CockroachDB build for storage. Use Ecto for the
mapping.

The V-Sekai build lives at `https://github.com/v-sekai/cockroach`. It
comes from the Oxide Computer build of CockroachDB 22.1. The project
already depends on that build elsewhere, so the same build keeps one
database version across the work.

CockroachDB speaks the PostgreSQL wire protocol. Ecto drives it
through `Ecto.Adapters.Postgres`. No separate adapter is necessary.

### Why CockroachDB

CockroachDB gives one API server or many. A single node runs on a
developer machine. The same binary joins a cluster later. The API
server therefore grows without a database migration.

The wire protocol is the PostgreSQL protocol. A developer who knows
`psql` needs no new tool.

### Two constraints

CockroachDB has no PostgreSQL advisory lock. The Ecto migrator takes
such a lock by default. Every repository configuration therefore sets
`migration_lock: false`.

CockroachDB gives no gap free integer sequence. A `SERIAL` column
returns large scattered numbers. The `facts` table therefore uses the
model id as the primary key. A catalog fact already has a natural
key, so this costs nothing.

## The facts table

| Column | Type | Holds |
| --- | --- | --- |
| `fact_id` | `string` | The model id. Primary key. |
| `content` | `text` | The label or the task text. |
| `category` | `string` | The client feature, such as `image_to_raw_mesh`. |
| `tags` | `string[]` | Type, host, and status. |
| `trust_score` | `float` | Zero to one. Feedback moves it. |
| `hrr_vector` | `bytea` | The packed float64 phase vector. |
| `inserted_at` | `timestamptz` | Row creation time. |
| `updated_at` | `timestamptz` | Last change time. |

The shape follows the hermes-agent holographic memory store, as RFD
0019 records.

`hrr_vector` holds the output of
`WeftspunStudio.FactVector.encode/2` as a packed binary. The width is
fixed at 1024 float64 phase angles, so a row takes 8 kilobytes. The
changeset derives the vector from the other columns. No caller
supplies it. A row therefore cannot hold a vector that disagrees with
its fields. RFD 0021 records the encoding.

Search reads the candidate rows and scores them in Nx. The database
applies the trust floor first. A phase similarity over a packed
tensor has no SQL form in CockroachDB 22.1, so the algebra stays in
Elixir.

## The seed database

The RFD 0016 inventory is the seed, not a fixed table.
`WeftspunStudio.Adapters.EctoFactStore.seed/0` writes it once. A
second run refreshes the same rows and adds no duplicate, because the
model id is the primary key.

After the seed the database is the record. Feedback moves a trust
score. A retraction deletes a row. The seed never overwrites those
later changes for a fact it does not name.

## Modules

| Module | Role |
| --- | --- |
| `WeftspunStudio.Repo` | The connection pool. |
| `WeftspunStudio.Facts.Fact` | The schema and the changeset. |
| `WeftspunStudio.Adapters.EctoFactStore` | A `Ports.FactSink` adapter. |
| `WeftspunStudio.Release` | Migration and seed for a packaged binary. |

`EctoFactStore` is the durable twin of `FactStore`. Both implement
`WeftspunStudio.Ports.FactSink`, so a caller can take either one. The
port keeps the choice out of the caller.

A Burrito binary carries no Mix, so `mix ecto.migrate` cannot run
against it. `WeftspunStudio.Release` does the same work. The command
line offers `weftspun db migrate`, `weftspun db seed`, and
`weftspun db status`.

## Local setup

The `cockroach_local` library owns the host lifecycle. It resolves
the binary from `COCKROACH_BIN`, then `priv/cockroach/`, then the
path. A Mix task wraps it:

```
mix weftspun.crdb install   # fetch the V-Sekai 22.1 build
mix weftspun.crdb path      # print the binary in use
mix weftspun.crdb           # run a node in the foreground
```

`CockroachLocal.Provision` downloads the same V-Sekai release this
RFD selects, so a second source of the binary does not arise.

Create the schema and load the seed:

```
mix ecto.setup
WEFTSPUN_SERVE=0 mix run -e 'WeftspunStudio.Adapters.EctoFactStore.seed()'
```

The node listens on 127.0.0.1:26257 and stores data under `.crdb`.
That directory stays out of version control.

The node runs insecure, so the `root` user needs no password. Use
that setting on a developer machine only. A shared host needs
certificates.

## Settings

| Variable | Default | Holds |
| --- | --- | --- |
| `WEFTSPUN_DB` | `1` | Set to `0` to start with no connection pool. |
| `WEFTSPUN_DB_HOST` | `127.0.0.1` | Host name. |
| `WEFTSPUN_DB_PORT` | `26257` | Port. |
| `WEFTSPUN_DB_NAME` | per environment | Database name. |
| `WEFTSPUN_DB_USER` | `root` | User name. |
| `WEFTSPUN_DB_PASSWORD` | empty | Password. |
| `WEFTSPUN_DB_POOL` | `10` | Pool size in a release. |

The inventory commands need no database. `WEFTSPUN_DB=0` therefore
lets `weftspun models list` run on a host with no cluster.

## Risks

A second store is a second source of truth. The HTTP surface still
reads the in memory store, so the two can drift. The next step points
the router at `EctoFactStore` and deletes the Agent.

CockroachDB 22.1 is old. The Oxide build tracks that version. A move
to a later version is a separate decision.

The suite needs a running cluster. A developer with no cluster sees
16 failures. The test helper names the start command.

## Status

Done:

- The V-Sekai build runs as one local node.
- The `facts` table exists, with the category and trust indexes.
- `EctoFactStore` implements every `FactSink` callback.
- The seed writes 29 facts and repeats without a duplicate.
- 16 tests cover the seed, the search, the trust moves, and the
  retraction. The whole suite passes with 78 tests.
- `cockroach_local` provisions and runs the host, through
  `mix weftspun.crdb`.

### The provisioner never reached the binary

`mix weftspun.crdb install` answered `:unsupported_target` on every
platform, and not only on Windows. Two faults stood in the way, and
`cockroach_local` had neither of them.

The task passed `:os.type()` to `Provision.install/2`. That returns an
`{os_family, os_name}` pair such as `{:win32, :nt}` or
`{:unix, :linux}`. The asset map is keyed `{:windows, :x86_64}`, thus
the two shapes never matched. `target/0` derives the pair now.

The task then passed `priv/cockroach` as the destination.
`install/2` appends `cockroach` itself, thus the binary landed in
`priv/cockroach/cockroach/` while `bin/1` read `priv/cockroach/`. It
installed, and then nothing could find it. The task passes `priv` now.

The V-Sekai release carries a Windows zip, a Linux tarball, and two
macOS tarballs. None of them was reachable before this.

### Where the suite runs

RFD 0056 moves development into a dev container. That container runs
Linux, thus it takes the Linux tarball.

`scripts/studio-test.sh` skips the suite when no node answers on
127.0.0.1:26257, and it names the start command. A hook that failed
instead would block a commit that touched no code.

Open:

- The router still reads the in memory store.
- A secure cluster needs certificates and a real user.
