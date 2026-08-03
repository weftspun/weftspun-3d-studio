# RFD 0010: WebXR and IWSDK lab

**State:** published
**Feature:** WebXR

## Problem

The app targets XR headsets. Users need VR and AR modes with floor
anchoring. The main app must also support expression tracking for
avatar faces.

## Decision

Use WebXR in the main viewport. Two session modes exist.

- VR mode shows a virtual sky background.
- AR mode shows pass-through transparency.

Floor anchoring places the model at the correct height. The WebXR
expression tracking drives VRM blink and mouth shapes. When the
browser lacks expression tracking, the native face bridge relays
face data from a companion APK.

A separate /xr route hosts the IWSDK lab. It experiments with grab
and locomotion. The main app also runs IWSDK distance grab and
thumbstick locomotion.

## References

- XR: `src/library/sceneManager.js`
- Lab: `src/pages/IwsdkImmersive.jsx`
- Face relay: `src/library/nativeFaceBridge.js`
- Config: `src/library/xrHubConfig.js`
- Docs: `docs/XR_MODE_FLOOR_ANCHORING_AND_BACKGROUNDS.md`
- Docs: `docs/IWSDK_INTEGRATION.md`

## Related

RFD 0009 defines the shared viewport.
