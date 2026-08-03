# RFD 0014: Batch processing

**State:** published
**Feature:** batch processing

## Problem

One avatar at a time is slow. A user with many VRM files wants to
process them in one run. The app must accept a manifest and produce
many results.

## Decision

Add batch processing with manifest files.

- The user loads a manifest.json that lists the input files.
- The app runs each item through the editing pipeline.
- BatchDownload saves the output VRMs.

The pipeline also renders VRM thumbnails, spritesheets, and LoRA
training data from the same manifests.

## References

- UI: `src/pages/BatchManifest.jsx`
- UI: `src/pages/BatchDownload.jsx`
- Parser: `src/library/manifestDataManager.js`
- Docs: `docs/docs/Modders/manifest-files/`

## Related

RFD 0005 defines the avatar pipeline that batch processing runs.
