# RFD 0035: Legacy model identifiers

**State:** published
**Feature:** model inventory

## Problem

Seven model identifiers remain in the code after the TRELLIS.2 move.
A reader who sees them in a picker cannot tell them from the current
models.

## Decision

Keep the identifiers, and list them last in every picker.
`LEGACY_MODEL_IDS` in src/library/aiModelsCatalog.js drives that
order. Do not delete them, because saved tasks reference them.

See `DETAILS.md` for the seven identifiers and the two rules that
still apply to two of them.

## Related

RFD 0016 lists the active models. RFD 0005 records the avatar
pipeline. RFD 0028 records the license gate.
