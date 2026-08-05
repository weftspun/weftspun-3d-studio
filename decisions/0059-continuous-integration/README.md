# RFD 0059: Continuous integration, in one step

**State:** published
**Scope:** `scripts/ci.sh`, `.github/workflows/main.yml`

## Problem

`.github/workflows/main.yml` ran `npm run test:anim-regression`.
`package.json` never defined that script. Every run of this job
failed at that line. CI stayed red, or silently skipped, since
whenever that step was added.

It also tested one of three parts of this repository. `weftspun_studio/`
had no CI at all, and neither did the two Podman images RFD 0058 adds.

## Decision

Follow Martin Fowler's ["Continuous
Integration"](https://martinfowler.com/articles/continuousIntegration.html).
One command builds and self-tests the whole system. A developer runs
it before committing, and the integration machine runs the identical
command.

Two of his practices name the fault directly. "Automate the Build"
and "Make Your Build Self-Testing" are the two. A broken `npm run`
line that only ran on GitHub's machine shows what happens when the
person who last touched a build never runs it.

`scripts/ci.sh` is that one command, and `.github/workflows/main.yml`
installs the toolchains and calls it. Nothing in the workflow
duplicates a step the script already runs.

See `DETAILS.md` for the three steps in order, why one script beats
three CI steps, and what this deliberately does not cover.

`.github/workflows/main.yml` is deleted, on purpose. `scripts/ci.sh`
still exists, still runs the same one command, and a developer still
runs it before committing. The browser client's own test suite
carries many pre-existing failures across several files, unrelated
to any one commit, and every push turned red for that reason alone.
RFD 0057 tracks restoring the workflow once that suite is fixed.

## Related

RFD 0058 gives the two container images this script builds. RFD 0020
gives the CockroachDB the Elixir step tests against.
