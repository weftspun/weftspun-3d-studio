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

## References

- RFD style: `rfd-driven-architecture` skill
- STE spec: https://www.asd-ste100.org/
- STE linter: the `simplified-technical-english` Claude Code plugin
  (`fire/claude-ste-plugin`). RFD 0063 records the move off a
  repo-local script.

## Related

See the DRY policy and the STE policy in `decisions/README.md`.
