# RFD 0005: Avatar and VRM pipeline

**State:** published
**Feature:** avatar pipeline

## Problem

A user wants an animated avatar from a photo or a trait selection.
The result must meet the rig contract and export as VRM.

## Decision

Support two avatar creation paths.

- Avatar from image chains mesh generation and a template rig.
- Avatar from photo uses AvatarSDK, not the AIGC backend.

The base body VRM stays soulbound. Clothing, hair, and accessories
act as equippable layers. The client validates the rig against the
API contract. The viewport loads the rigged GLB. The user can
download a VRM after the pipeline.

Export paths include GLB download, VRM build, avatar pipeline VRM,
and GLB compression with gltf-transform.

See `DETAILS.md` for file references.

## Related

RFD 0004 catalogs the avatar tasks. RFD 0008 defines trait remix.
The wallet minting link (old RFD 0012) is abandoned. The project
does not do NFTs.
