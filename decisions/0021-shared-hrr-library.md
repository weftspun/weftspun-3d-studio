# RFD 0021: A shared holographic algebra library

**State:** discussion
**Scope:** `weftspun_studio/`, `weftspun/elixir-holographic-reduced-representation`

## Problem

RFD 0019 gave the studio core a local module,
`WeftspunStudio.Hrr`. It held a real-valued Holographic Reduced
Representation. Binding used a Fourier transform, and the inverse
worked only on unitary vectors.

A search of the weftspun repositories found an earlier port of the
same idea. `weftspun/residual-fsq-recommender` held `Holo.Core.HRR`,
a phase-angle representation. An ADR of 2026-07-14 removed it,
because a trained model replaced the training-free recommender that
used it. The algebra itself was never in doubt.

Two representations of one idea is one too many. The two also do not
interoperate, because a vector from one carries no meaning in the
other.

## Decision

Extract the earlier port into a library, and depend on it.

The library is `weftspun/elixir-holographic-reduced-representation`,
which supplies the `:hrr` application and the `HRR` module. The
studio core takes it as a Git dependency.

The algebra and the atom generation move over unchanged, so
`test/fixtures/hrr_golden.json` still certifies parity with the
Python `holographic.py` reference to 1.0e-12.

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
encoding is hashing and arithmetic, so it needs no accelerator.

Retrieval quality held. A search for `uv_unwrapping` returns
`xatlas_uv_unwrapping` at 0.21, and the next result scores 0.015. A
probe of the `:category` role of `trellis_text_to_textured_mesh`
returns `text_to_textured_mesh` at 0.52.

## Risks

The library is a Git dependency, not a Hex package. A build therefore
needs network access to GitHub. Publishing to Hex is a later step.

The earlier ADR states that Lean proofs of the phase algebra remain
in `formal/RecommenderModel.lean`. They do not. That file now holds
only the codec proofs. The algebra carries tests, and no proof.

## Status

Done:

- The library exists, with 22 tests. The golden parity tests pass.
- `WeftspunStudio.FactVector` replaces `WeftspunStudio.Hrr`.
- The migration rewrote all 29 rows to 8192 bytes each.
- The whole suite passes with 78 tests.

Open:

- Publish the library to Hex.
- Restore the Lean proofs of the phase algebra, or drop the claim.
