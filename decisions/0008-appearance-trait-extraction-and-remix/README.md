# RFD 0008: Appearance trait extraction and remix

**State:** discussion
**Feature:** appearance traits

## Problem

The See-Through layers split an image into body parts. Each part
maps to an appearance slot. The app should reuse the layers for
trait remixing.

## Decision

Map See-Through layer names to appearance slots. The map uses the
existing appearance vocabulary. Hair, eyes, and face map to Head.
Torso and clothing map to Chest. Legs and shoes map to Legs.

The layer_decomposition node stores the mapped slots. The Studio
page shows the remix candidates. A future remix flow equips the
layer artifacts into the avatar slots.

## References

- Mapping: `src/library/appearanceClothing.js`
- Trait authoring: `src/pages/AppearanceSimple.jsx`
- Slots: `src/library/lootAssetsConfig.js`

## Related

RFD 0006 produces the layers. RFD 0005 defines the avatar slots.
