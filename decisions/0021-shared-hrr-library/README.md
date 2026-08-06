# RFD 0021: A shared holographic algebra library

**State:** published
**Scope:** `weftspun_studio/`, `weftspun/elixir-holographic-reduced-representation`

## Problem

RFD 0019 gave the studio core a local module, `WeftspunStudio.Hrr`.
It held a real-valued Holographic Reduced Representation. Binding
used a Fourier transform, and the inverse worked only on unitary
vectors.

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

See `DETAILS.md` for why the phase representation wins, the
dimension choice, the migration effects, and the risks. It also
holds the Lean proofs and the verified status.
