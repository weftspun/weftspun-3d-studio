# RFD 0028: Model license gate

**State:** published
**Feature:** model licensing

## Problem

Some model weights permit non-commercial use only. Some carry
territory rules and user-count rules. The catalog must not ship them
to paying users.

## Decision

Any model shipped to paying users must clear commercial use. The gate
is the hard prerequisite in MODEL_LICENSES.md. The repository keeps a
FOSS blocklist for permissive licenses only.

See `DETAILS.md` for the deleted models and the blocklisted models,
each with its license and its replacement.

## Related

RFD 0016 lists the active models. RFD 0029 gives the FOSS
replacements. RFD 0035 lists the legacy models. The license audit is
docs/MODEL_LICENSES.md in AlfaOmegaGrafx/3DAIGC-API.
