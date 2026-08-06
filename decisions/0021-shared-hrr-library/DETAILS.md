# RFD 0021 details: reasoning, dimension, proofs, status

### Why the phase representation wins

| Point | Phase representation | The earlier local module |
| --- | --- | --- |
| Bind | Adds phases. Cost is linear. | Multiplies spectra. Cost is `n log n`. |
| Unbind | Subtracts phases. Exact for every vector. | Exact only after a unitary correction. |
| Atoms | SHA-256 counter blocks. | A seeded normal draw. |
| Parity | Matches a Python reference bit for bit. | None. |
| Reuse | Two repositories share it. | One module in one repository. |

The phase form is cheaper, it is exact without a correction step, and
a second language can produce the same vectors.

### What the library holds

`HRR` holds `encode_atom/2`, `bind/2`, `unbind/2`, `bundle/1`,
`similarity/2`, `encode_text/2`, `to_binary/1`, `from_binary/1`, and
`snr_estimate/2`.

`HRR.Cleanup` is new. It holds the codebook and the nearest-symbol
lookup. Every caller of `unbind/2` needs that step, because an unbind
returns the filler plus superposition noise. Writing it once stops
three repositories from writing it again.

### What stays here

`WeftspunStudio.FactVector` holds the part that knows what a catalog
fact is:

  * `encode/2` binds the id, the category, and the tags to their
    roles, then bundles the result.
  * `query/2` turns free text into a probe. A term may name any of
    the three roles, so the probe binds it to all three.
  * `codebook/2` and `probe/4` reach `HRR.Cleanup` with the symbols a
    fact can resolve to.

The library knows nothing about catalogs. This module knows nothing
about phase arithmetic.

## Dimension

The library defaults to 4096. This project uses 1024.

A phase vector holds float64 values, so 4096 would take 32 kilobytes
a row. At 1024 a row takes 8 kilobytes. A fact bundles four parts,
and the capacity at 1024 is about 32 items, so the smaller width
still leaves a wide margin.

## Effects

The stored vectors changed from 1024 float32 values to 1024 float64
phase angles. Migration `20260804010000` rewrites every row. Trust
scores survive, because the vector comes from the other columns and
never from itself.

`mix ecto.migrate` starts the repository alone, so EXLA is not
running. The migration therefore selects `Nx.BinaryBackend`. Phase
encoding uses hashing and arithmetic, so it needs no accelerator.

Retrieval quality held. A search for `uv_unwrapping` returns
`xatlas_uv_unwrapping` at 0.21, and the next result scores 0.015. A
probe of the `:category` role of `trellis_text_to_textured_mesh`
returns `text_to_textured_mesh` at 0.52.

## Risks

The library is a Git dependency, not a Hex package. A build therefore
needs network access to GitHub. Publishing to Hex is a later step.

The library stores radians, not turns. A radian phase is irrational,
so the exactness result does not reach it. The measured cost is
2.2e-15, which is 2.3e-11 of one grid step, and similarity after a
round trip reads 1.0. Turns would remove the gap and break the golden
fixture, so the library keeps radians.

## Proofs

The earlier repository proved the algebra in Lean 4, then deleted the
proofs in commit 7303244 once the HRR code left it. The algebra now
has a home again, so the proofs moved with it, into `formal/` of the
library.

`unbind_bind` and `bind_comm` transfer unchanged. `bind_assoc`,
`unbind_bind_left`, and the two grid bounds are new. Together they say
that binding is a commutative and associative group operation on
`ℤ/65536`, and that unbinding inverts it exactly.

The cleanup recall walk from the same file did not move. It modelled
`Recommender.Memory.recommend`, which no longer exists, and it needed
`fire/plausible-witness-dag`. The restored model needs no dependency,
and no axiom beyond `propext` and `Quot.sound`.

`PhaseRat.lean` is new. It carries the grid result across to the
arithmetic that runs it. A phase is a rational with a power-of-two
denominator, so component `k` stands for `k / 2^16` of a turn.
Binary64 holds a value exactly while its significand stays under
`2^53`. Binding adds two numerators below `2^p`, so the exact sum
needs `p + 1` bits, and `p = 16` leaves 36 bits spare. The addition
and the subtraction therefore never round.

Three bridge theorems tie that file to `HrrModel`, so the bounds
apply to the proved algebra and not to a lookalike.

Lean's `Float` is opaque and carries no formal semantics, so no proof
mentions it. The theorems bound the significand, and the standard
binary64 criterion does the rest.

## Status

Done:

- The library exists, with 22 tests. The golden parity tests pass.
- `WeftspunStudio.FactVector` replaces `WeftspunStudio.Hrr`.
- The migration rewrote all 29 rows to 8192 bytes each.
- The whole suite passes with 78 tests.
- The Lean proofs build and run under Lean 4.32.2.
- `PhaseRat` bounds the significand, so binary64 does not round the
  algebra at this precision.

Open:

- Publish the library to Hex.
- Run `lake build` in continuous integration, so a change to the
  algebra cannot pass without the proofs.
