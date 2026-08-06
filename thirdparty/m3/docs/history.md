---
sidebar_position: 2
---


# History


This project stands on the shoulders of giants with years of history from open source hackers and web3 enthusiasts.

**V1: Atlas Foundation lays the groundwork**

> An open, collaborative and evolving character creator project for the open metaverse. https://github.com/AtlasFoundation/AvatarCreator

![](/img/97bDPrd.png)

![](/img/uXmtEPX.gif)

**V2: Webaverse ships! and then forgets?**

> 3D Avatar Creator for Everyone https://github.com/webaverse-studios/CharacterCreator

![image](/img/rJ80Rwpja.png)

![image](/img/BJ4CkO6ip.png)

![](/img/H1qoTjToa.jpg)



More development screenshots, from a livestream of January 2023. They show more character classes, the AI personality generator, and the mint function:

|  [![Screenshot_2024-02-16_18-22-15](/img/S1Oaao6iT.jpg)](/img/S1Oaao6iT.jpg) |   [![Screenshot_2024-02-16_22-56-01](/img/HJRyjhpia.jpg)](/img/HJRyjhpia.jpg)  |
| --------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| [![Screenshot_2024-02-16_18-22-01](/img/H19p6jaoa.jpg)](/img/H19p6jaoa.jpg) | [![Screenshot_2024-02-16_18-21-46](/img/BJfR6i6oa.jpg)](/img/BJfR6i6oa.jpg) |



**V3: M3 carries the torch with Anata**

![](/img/S1pGC3aj6.jpg)

![Screenshot from 2023-12-30 15-53-13](/img/rJzD026jp.png)

![Screenshot from 2023-11-18 23-09-15](/img/rJN4AnpoT.png)



## Roadmap

- **Immersive XR (in repo)**:
  - The main app runs **WebXR** through `SceneManager`, for VR and AR, with floor anchoring.
  - The **IWSDK lab** at `/xr` holds the locomotion and grab experiments. See [RFD 0090](https://github.com/weftspun/request-for-discussion/tree/main/0090-iwsdk-integration), `weftspun/request-for-discussion`.
  - **Galaxy XR** takes an optional [**Weftspun XR Face** APK](../../native/android-xr-face-bridge/README.md). That APK relays blend shapes when Chrome has no expression tracking. See [RFD 0096](https://github.com/weftspun/request-for-discussion/tree/main/0096-openxr-face-tracking-android-xr), `weftspun/request-for-discussion`.
- **Kimodo text-to-motion**: Animation bar → **3DAIGC-API** `text_to_motion` (Kimodo SOMA-RP-v1.1) → studio motion JSON → VRM / rigged GLB playback in viewport
- AI features: create or load a personality, then talk to your VRM. These are **companion runtimes**. They run beside the app, and the project does **not** merge them.
  - **[moeChat](https://github.com/moeru-ai/chat)** is the **default**. See the [demo](https://chat.moeru.ai/). It covers WebXR, VRM, voice, and the AI model settings.
  - **[AIRI](https://github.com/AlfaOmegaGrafx/airi)** is optional, and gives more companion depth. Weftspun 3D Studio supplies only the export, the handoff, and the shared configuration.
- Connect wallet to load profiles or mint files
- Load a profile and an AI personality from a personal data export that the user controls, such as a local personal server or a data connector. The credentials stay on the device of the user.
- Use a local or self hosted 3D AIGC backend as the main inference engine. 3DAIGC-API on DGX class hardware is one example. It can take profile and personality context, for personal text to 3D, image to 3D, and editing work.
- Connect to an external 3D launchpad, such as a Solana or Arweave mint for VRM and GLB files. Weftspun 3D Studio then assembles those avatars and wearables from wallet owned assets.

The product and revenue detail sits in [`MONETIZATION_ROADMAP.md`](../../MONETIZATION_ROADMAP.md), at the repository root. It covers x402, the tiers, the NFT commissions, and the personal AI pathway of section 11.
