# RFD 0063 details: what moved where, what this repository does not gain back

## What moved where

Several checks the deleted script hand-wrote already existed in the
plugin, and more precisely. The plugin cites an ASD-STE100 Part 1
rule number for each one. Its sentence splitter and word counter
follow CommonMark structure, not a line-based heuristic.

Three checks were new. Each one went upstream instead of staying
local, in `fire/claude-ste-plugin#1`:

- `style.bloat`, for an inflated word such as "utilize"
- `style.marketing`, for a marketing word such as "seamless"
- `style.dash`, for an em dash that joins two clauses

This repository's own `decisions/` tree is the prose the PR tested
them against. The plugin checks all three now, in every project it
installs into, not only this one.

## What this repository does not gain back

The deleted script scored a whole document, at violations per 100
words. It also read many files at once and printed one pass or fail
line per file. The plugin has no equivalent to either. It reports one
finding per line, for one file at a time, and it does not score a
document as a whole. A CI run that wants one pass/fail number across
every RFD does not have that number anymore.

This RFD accepts that loss. `decisions/README.md`'s STE policy never
asked for a score. It asked for STE prose. The `Stop` hook catches a
violation earlier than a CI gate can, on every reply that touches
this repository, not only on a push.
