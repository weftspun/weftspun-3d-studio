# RFD 0057 details: the open-work list

Delete an entry when it closes. This file shrinks, and it never
grows a history section.

## Verified, and running

| What | Evidence |
| ---- | -------- |
| The planner composes three documents | `pipeline_test.exs`, all 105 pass on this box now that `taskweft_nif` is rebuilt for x86_64 |
| The model image serves HTTP | RFD 0040, run in Docker on this machine |
| CockroachDB provisions and runs | RFD 0020, 92 tests with the node up |
| taskweft composition | PRs 207, 208, 209, merged upstream |
| Both Quadlets run end to end | RFD 0058, `weftspun.service` and `weftspun-crdb.service` both `active (running)`, `/api/v1/health` and `/api/v1/models` answered over `weftspun.network` |
| `taskweft_nif` runs on x86_64 | `make clean && mix deps.compile taskweft_nif --force` from `deps/taskweft_nif/`. `mix test` then runs 105/105 with no arch-mismatch failure |

## Written, and never run

**The dev container.** RFD 0056. The image does not build yet. The
Debian attempt failed at `mix local.hex`, and the Fedora rewrite
answers that by reading the error. Build it before trusting it.

**The Pixal3D worker stage.** RFD 0040. Only the contract stage ran.
The worker stage pulls 24.045 GB and needs an NVIDIA device, thus it
needs a rented card.

**The local worker.** RFD 0055 Phase 2. No worker service runs on
this box yet, only a manual contract-stage test (RFD 0040). No
instance is rented either, and RFD 0062's Gall's law says none
should be, until this box is not enough.

**The Fly.io / 4090 split.** RFD 0062. No `fly.toml`, no worker-side
job-receiving adapter, no Tailscale join between a Fly machine and
this box, no CockroachDB migration off this box. RFD 0062 names the
target. None of it runs yet. The adapter's asset-transport half is
settled, `idtx_transport`/aria-storage, per RFD 0062's own DETAILS.md.
Open work narrows to the job-control envelope, and whether an
aria-storage instance runs anywhere reachable yet.

## Measured, and not built

**Fourteen model folders.** RFD 0036. Each still carries a `cog.yaml`
and a `predict.py`, and RFD 0036 no longer selects Cog. Convert one
when its model is next worked on, and not in a sweep. The folder
names are already converted, and the files inside are not.

**`_to_usd` in the worker.** RFD 0053. The layer records the GLB as an
asset attribute, because `usd-core` alone reads no glTF. A glTF file
format plugin would let it be a reference arc.

**The `idtx_core` NIF adapter.** RFD 0061. `flow/adapters/` in
`thirdparty/fabric-flow-adapters/` holds three hosts — Godot, Unity,
CLI — and no Elixir one. Needs a fourth adapter, a `weftspun_studio`
route, and the browser call site swapped over. RFD 0061's stopgap
(`prepareGlbForApiUpload` in `glbCompress.js`) stays until this
lands.

## Unknown, and blocking a number

**The Q4_K_M quality cost.** RFD 0043. Quantization is a price choice
now, and no measurement compares the two formats.

**The browser client's own test suite.** RFD 0059. Failures span
`skintokensLoadOrientation.test.js`,
`taskAdvancedOptionsDecimation.test.js` (multiple, past the three
already skipped), `viewportAnimationTarget.test.js`, and
`src/library/taskModelUrl.test.js`, unrelated to each other and to
any one commit. `.github/workflows/main.yml` is deleted until this
is fixed, not patched test by test under a deadline.

## Decided, and waiting on order

**The Replicate passthrough.** RFD 0055 Phase 1 step 3 removes it.
RFD 0055 also records why it stays until this box's own worker
answers.

**The abandoned world cluster's stale references.** RFD 0064 pivots
the roadmap to character concepts. RFD 0049, RFD 0050, RFD 0051, and
RFD 0052 record the abandonment, but RFD 0016, RFD 0017, RFD 0026,
RFD 0027, RFD 0037, and RFD 0038 still cite all four as active work.
`lib/weftspun_studio/inventory.ex` still marks all four `:active`.
Update each reference, or mark the four `:vetoed`, when the catalog
is next touched.
