# RFD 0034: Krea memory cross-check

**State:** published
**Feature:** capacity planning

## Problem

RFD 0025 gives a rule for the memory. RFD 0026 applies that rule to
models with no published parameter count. An unchecked rule on an
estimated count gives two errors, and not one.

## Decision

Check the rule against the one model with a measured number. Krea 2
Turbo is that model. `scripts-cheatsheet.md` records 57 GB on disk,
and a 32 GB reserve per worker.

See `DETAILS.md` for the parameter estimate by part, and how it
compares against the measured reserve and disk size.

## Related

RFD 0025 gives the rule. RFD 0026 gives the counts this check cannot
confirm.
