# RFD 0067 details: the sibling repositories, and what each found

## The rerank table

| Rank | Store | Ecto path | What the sibling work found |
| --- | --- | --- | --- |
| 1 (kept) | CockroachDB | `Ecto.Adapters.Postgres`, unmodified | Boring. PostgreSQL wire protocol, plain Postgrex socket. Already running under RFD 0020, RFD 0058, and RFD 0065. |
| 2 | FoundationDB Relational Layer (FRL) | `ecto-fdb-relational`, a Rustler NIF embedding a JVM | Works, at a real permanent cost. See below. |
| 3 | mvsqlite (SQLite on FDB) | none | A ~3s p90/p95/p99 latency ceiling under concurrency, and no Ecto adapter exists. |
| 4 | Raw FoundationDB | none | Highest measured write throughput, and no SQL layer at all. |

## `weftspun/h2o-bench-tpcc`: FoundationDB over CockroachDB, for a different case

Its `rfd/0006-fdb-selection.md` picks raw FoundationDB over
CockroachDB, for a TPC-C-style MMO backend written in C against
`libh2o`. It gives three reasons. TPC-C is 88% writes, and FDB's
log-structured MVCC gives lower write latency than CockroachDB's Raft
path at that scale. FDB 7.3.79 is under active Apple development. By contrast,
"CockroachDB's v-sekai fork is a dead engine with no upstream
activity." The C API needs no JVM, no JNI, and no gRPC bridge.

None of these reasons name a workload `weftspun_studio` or
`character_taxonomy` actually carries. Both write catalog facts, job
records, and RFD 0065's trait ids, not an MMO's tick-rate traffic.

## `weftspun/ecto-fdb-relational`: the Ecto-compatible path, and its real cost

Three ADRs, in its `rfd/0001.md`, trace the same path this project
would need to keep Ecto and gain FoundationDB. ADR 0001 talks gRPC to
a separate `fdb-relational-server` process. ADR 0002 proposes an
embedded JVM through a Rustler NIF as an opt-in second transport. ADR
0003 replaces gRPC outright with that embedded transport, because
running two transports correctly cost more than the team could keep
funded.

ADR 0003's own "Consequences" section names what that final shape
costs, permanently. A JVM segfault, a native OOM, or a panic crossing
the Rust/JNI boundary takes down the whole BEAM node, with no crash
isolation. A JDK and a Rust toolchain become hard prerequisites to
`mix compile`, not only to run tests. Every call blocks a Rustler
`DirtyIo` scheduler thread, with no per-call timeout wired up.

Postgrex, by contrast, is a plain socket protocol library with none
of those costs. RFD 0058 grounds its whole zero-trust design in
predictable, boring processes. RFD 0059 asks for a build that runs
in one command on a laptop. A JDK-and-Rust compile prerequisite, and
a store that can crash the whole node, work against both.

## `weftspun/mvsqlite-tpcc-bench`: a measured ceiling, not a FoundationDB property

Its README records a known finding. Both fresh- and
contended-cluster sweeps clamp p90/p95/p99 latency to a
near-identical ~3.0 second value. This holds at every terminal count
of 4 or more. Root cause:
`sqlite-jdbc`'s fixed 3000ms `busy_timeout`, not FoundationDB itself,
tracked upstream at `weftspun/mvsqlite#11`. No Ecto adapter to
mvsqlite exists in any `weftspun` repository, so this path is not
available to `weftspun_studio` regardless of that finding.

## The one point that survives scrutiny

`h2o-bench-tpcc` RFD 0006's claim that the V-Sekai CockroachDB fork
this project pins is unmaintained upstream is a genuine risk. It is a
security-patch and long-term-support risk, not a throughput argument.
RFD 0020 already accepts pinning one tag deliberately. Track this in
RFD 0057's open work. Revisit it if the fork stays dark long enough
to matter, and not as a reason to adopt FoundationDB today.

## Sources

- `weftspun/h2o-bench-tpcc`, `rfd/0006-fdb-selection.md`
- `weftspun/ecto-fdb-relational`, `rfd/0001.md` (ADR 0001-0003)
- `weftspun/ecto-bench-tpcc`, README "Status / honest gaps"
- `weftspun/mvsqlite-tpcc-bench`, README "Known finding"
- `weftspun/scenario-tpcc-bench`, README (CockroachDB dropped as a
  comparison target there, for reasons specific to that repo's scope)
