# Code map

This page names each module group and points at the source. It does
not repeat the method signatures. Read the source for the current
API. The source stays correct. A copy of the source drifts.

This page replaces the API reference that the fork took from the M3
Character Studio site. That reference covered 7 managers. The code
now holds more than 40. See RFD 0018 for the reason.

## React contexts

Path: `src/context/`

| Context | Role |
|---------|------|
| `SceneContext.jsx` | Scene state and the loaded avatar |
| `Core3DContext.jsx` | Renderer, camera, and viewport state |
| `TaskContext.jsx` | Task list state for the Task Manager |
| `AccountContext.jsx` | Wallet account state |
| `AudioContext.jsx` | Audio graph and lip sync input |
| `SoundContext.jsx` | Interface sound effects |
| `ViewContext.jsx` | Active page and view state |
| `LanguageContext.jsx` | Interface language |

## Scene and rendering

Path: `src/library/`

| Module | Role |
|--------|------|
| `sceneManager.js` | Three.js scene, camera, and render loop |
| `effectManager.js` | Post effects and transitions |
| `sharedHDRManager.js` | Shared environment lighting |
| `viewportLighting.js` | Viewport light and exposure state |
| `cameraFrameManager.js` | Camera framing for avatars |
| `vrmManager.js` | VRM load and unload |
| `sparkSplatManager.js` | Gaussian splat view through Spark.js |

## WebXR

Path: `src/library/sceneManagerXr*.js`

The XR code splits by concern. Each file holds one concern. The list
covers input, locomotion, teleport, grab, interaction, menus, axes,
controller visuals, gamepad buttons, measure, mouse emulation, and
the avatar view.

RFD 0010 records the WebXR design.

## Avatar and traits

| Module | Role |
|--------|------|
| `characterManager.js` | Avatar assembly and trait swap |
| `manifestDataManager.js` | Manifest load and trait lookup |
| `animationManager.js` | Animation load and playback |
| `blinkManager.js` | Eye blink timing |
| `lookatManager.js` | Head and eye aim |
| `EmotionManager.js` | Expression state |
| `assetManager.js` | Asset fetch and cache |

RFD 0005 records the avatar and VRM pipeline.

## Export and generation

| Module | Role |
|--------|------|
| `screenshotManager.js` | Viewport capture |
| `thumbnailsGenerator.js` | Trait thumbnail sheets |
| `spriteAtlasGenerator.js` | Sprite atlas output |
| `loraDataGenerator.js` | LoRA training image sets |
| `OverlayTextureManager.js` | Texture overlay composition |
| `zipManager.js` | Archive output |
| `VRMExporter.js` | VRM write |

## Tasks

| Module | Role |
|--------|------|
| `taskManager.js` | Job submit and poll against 3DAIGC-API |
| `taskPersistence.js` | Task storage in the browser |
| `aiModelsCatalog.js` | Task types and model names |

RFD 0003 records the job lifecycle. RFD 0004 records the task
catalog.

## Wallet and payments

| Module | Role |
|--------|------|
| `solanaManager.js` | Solana wallet calls |
| `baseX402Manager.js` | Base chain x402 calls |
| `thirdwebX402Manager.js` | Thirdweb x402 calls |
| `vanaDataManager.js` | Vana data calls |
| `mint-utils.js` | Mint helpers |

RFD 0012 records the wallet decision. That RFD has the state
abandoned.

## Hardware bridges

| Module | Role |
|--------|------|
| `mbientLabsManager.js` | MbientLab sensor input |
| `tapStrapManager.js` | Tap Strap input |
| `nativeFaceBridge.js` | Android face bridge interface |
| `nativeFaceRelay.js` | Face data relay to the browser |

## Pages

Path: `src/pages/`

Each page file holds one route. `src/App.jsx` maps the routes. RFD
0001 records the app shell and the routing.

## Related

- RFD 0000: conventions and the DRY policy
- RFD 0018: the reason for this page
