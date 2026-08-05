# RFD 0064: Character Concept Generator

**State:** pre-discussion
**Scope:** To be determined

## Problem

Gall's law asks for the smallest working piece of character
authoring, with appearance traits, animation, and export to an
OpenUSD intermediate format.

## Decision

Encode useful combinations of character concepts into taskweft, and
run it on Fly.io with Nx, with no GPU acceleration.

1. Use taskweft to generate a character description, from a vision
   inspection of the training dataset. This is the Gall's law step.
2. Postpone RFD 0042 (Krea 2 Turbo) for image generation.
3. Postpone RFD 0043 (Qwen image edit) to match a T-pose character
   pose.
4. Postpone RFD 0044 (See-Through layer decomposition) to remove
   eyes, eyebrows, irises, and eye whites from the face.
5. Postpone RFD 0040 (Pixal3D) to generate a mesh.
6. Postpone RFD 0046 (SkinTokens) to auto-rig the mesh.
7. Postpone Godot Engine 4.7's humanoid skeleton silhouette
   retargeting.
8. Postpone research into RFD 0045 (Kimodo) to generate a body, if
   clothing, accessories, and objects need separation from the
   Soma-X body.

## Related

RFD 0042 gives Krea 2 Turbo text-to-image. RFD 0043 gives Qwen image
edit. RFD 0044 gives See-Through layer decomposition. RFD 0040 gives
Pixal3D, and RFD 0045 gives Kimodo text-to-motion.

RFD 0046 gives SkinTokens auto rig. `DETAILS.md` holds the reference
links.
