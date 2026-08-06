# RFD 0017 details: compatibility, risk, references

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
