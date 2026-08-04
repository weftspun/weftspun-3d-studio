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

## Compatibility

Three identifiers keep a fallback path. Each fallback reads the old
name once.

- The Gradle build reads the old local.properties key.
- The task store reads the old browser storage keys.
- The lighting reader accepts the old glTF extras key.

## Risk

The rebrand renames one backend model identifier. The client sends
weftspun_image_to_world to the 3DAIGC-API server. The server must
accept the new name. Image to World tasks fail until then.

The face bridge APK changes its application identifier. A headset
installs the APK as a new application. Users must delete the old APK.

## References

- Brand terms: `README.md`, section Legal and Trademark Information
- Mark: `public/weftspun-favicon.svg`
- Android icon: `native/android-xr-face-bridge/app/src/main/res/raw/ic_app_icon.svg`
- Fallbacks: `src/library/taskPersistence.js`, `src/library/viewportLighting.js`
- Commit: `16afbc27`

## Related

RFD 0018 records the M3 documentation removal.
