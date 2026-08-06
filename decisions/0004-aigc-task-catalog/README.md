# RFD 0004: AIGC task catalog

**State:** published
**Feature:** task catalog

## Problem

The app exposes many AI tasks. Each task maps to an API feature and
a model. The catalog must stay in sync with the backend model list.

## Decision

Keep one model catalog as the source of truth. The catalog maps a
task type to an API feature. It also maps a feature to a default
model.

The live model list filters the catalog when the API connects.
License-blocked models stay out of the UI catalog. They remain only
in API documentation until the delete pass removes them.

See `DETAILS.md` for the task list and file references.

## Related

RFD 0003 defines the lifecycle for these tasks. RFD 0005 defines the
avatar paths.
