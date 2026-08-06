# RFD 0017: Fork rebrand to Weftspun

**State:** published
**Scope:** all files

## Problem

Upstream reserves the names "Space-Time" and "OpenNexus3DStudio".
Upstream also reserves the orbital clock logo artwork. The upstream
terms require a rebrand for each fork. A fork must remove the
upstream names, logos, and trade dress. A fork must then take a
unique name.

## Decision

This repository takes the name Weftspun 3D Studio. The code token is
Weftspun3DStudio. The package name is weftspun-3d-studio. The
Electron identifier is com.weftspun.studio. The Android identifier is
com.weftspun.xrfacebridge.

The application header shows one title line. The rebrand drops the
second title line and its style rules.

A new mark replaces the upstream artwork. The new mark shows a woven
warp and weft lattice. A rename alone does not satisfy the upstream
terms, because the terms reserve the artwork itself.

The repository keeps the upstream repository links. These links give
credit to the upstream authors. Nominative credit does not claim any
affiliation.

See `DETAILS.md` for the compatibility fallbacks, the known risks,
and file references.

## Related

RFD 0018 records the M3 documentation removal.
