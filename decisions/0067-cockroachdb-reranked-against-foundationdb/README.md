# RFD 0067: CockroachDB, reranked against FoundationDB

**State:** published
**Scope:** `weftspun_studio/`, `character_taxonomy/`

## Problem

RFD 0020 picked CockroachDB before sibling `weftspun` repositories
built and benchmarked FoundationDB, its Relational Layer, and
mvsqlite. One of them, `h2o-bench-tpcc`, picked FoundationDB over
CockroachDB, and called the CockroachDB fork this project pins "a
dead engine." Does that verdict carry over here.

## Decision

Keep CockroachDB. RFD 0020 stands. See `DETAILS.md` for the
repository-by-repository evidence this reranking draws on.

The case against CockroachDB does not transfer, for three reasons.

1. `h2o-bench-tpcc`'s case for FoundationDB is TPC-C write throughput
   at MMO scale. `weftspun_studio` and RFD 0065's taxonomy write
   catalog facts, job records, and trait ids, nowhere near that load.
2. The one Ecto-compatible path, `ecto-fdb-relational`, embeds a JVM
   through a Rustler NIF. Its own ADR history permanently accepts no
   crash isolation, a JDK and Rust build step, and no per-call
   timeout. That trades Postgrex's plain socket for a real regression.
3. Raw FoundationDB, `h2o-bench-tpcc`'s own pick, drops SQL and Ecto
   entirely, so adopting it means rewriting every `Ecto.Schema` this
   project holds by hand, for throughput this load does not need.

The dead-fork risk is real, and not a throughput question. It is open
work, not a reason to move today.

## Related

RFD 0020 picks CockroachDB. RFD 0058 and RFD 0059 state the
zero-trust, one-command build. RFD 0065's taxonomy runs on
CockroachDB in `character_taxonomy/`. RFD 0057 gets the dead-fork
risk as a new open-work item.
