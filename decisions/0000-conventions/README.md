# RFD 0000: Conventions

**State:** published
**Scope:** all files

## Decision

This repository writes Request-for-Discussion documents in the Oxide
style. Each RFD has a state: prediscussion, ideation, discussion,
published, committed, or abandoned.

The repository writes prose in ASD-STE100 Simplified Technical
English. Code and identifiers do not follow STE. STE applies to
documents, comments, and user-visible text.

The repository keeps designs in one place. The decisions directory
records durable decisions. The docs tree holds detailed designs.
An RFD points to its source. It does not copy the source.

Each RFD's `README.md` stays under 40 lines. It states the problem
and the decision, in the fewest lines that keep both true. A
measurement, a verification log, a deep walkthrough, or a code
sample does not fit. Move it to a sibling file, such as
`DETAILS.md`, in the same RFD folder. The `README.md` names that
file in one line.

## References

- RFD style: `rfd-driven-architecture` skill
- STE spec: https://www.asd-ste100.org/
- STE linter: the `simplified-technical-english` Claude Code plugin
  (`fire/claude-ste-plugin`). RFD 0063 records the move off a
  repo-local script.

## Related

See the DRY policy and the STE policy in `decisions/README.md`.
