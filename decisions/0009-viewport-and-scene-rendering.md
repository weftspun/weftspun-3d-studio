# RFD 0009: Viewport and scene rendering

**State:** published
**Feature:** viewport

## Problem

The app needs one viewport for meshes, VRM avatars, and splat
worlds. The viewport must also run in WebXR. The renderer must
fall back when WebGPU is absent.

## Decision

Use SceneManager as the single viewport owner. It uses Three.js
with WebGPU when available and WebGL as a fallback.

The viewport supports render modes, three-point lighting,
post-processing, tone mapping, and Spark.js splats in one scene.
One scene keeps WebXR and state consistent.

## References

- Scene: `src/library/sceneManager.js`
- Viewport: `src/components/Scene3D.jsx`
- Splats: `src/library/sparkSplatManager.js`
- Context: `src/context/SceneContext.jsx`
- Migration: `docs/THREEJS_WEBGPU_WEBXR_MIGRATION.md`

## Related

RFD 0010 defines the XR paths.
