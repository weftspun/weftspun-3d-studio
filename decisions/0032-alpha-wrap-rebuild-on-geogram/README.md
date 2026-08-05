# RFD 0032: Alpha wrap rebuild on Geogram

**State:** ideation
**Feature:** mesh geometry

## Problem

RFD 0031 keeps CGAL optional. That leaves the alpha wrap step absent
from a permissive build. fTetWild and Manifold approximate the step.
Neither one implements it.

## Decision

A clean-room rebuild on Geogram is viable. The algorithm comes from
the paper "Alpha Wrapping with an Offset" (ACM TOG 2022). The paper is
open access on HAL. It specifies the full algorithm.

See `DETAILS.md` for the Geogram primitives, the traversal work
itself, and why remeshing stays a separate stage.

## Related

RFD 0002 records the pipeline stages. RFD 0031 records the alpha wrap
options. RFD 0029 records the retopology replacements.
