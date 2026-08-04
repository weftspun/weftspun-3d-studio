---
sidebar_position: 2
---

# Character Select

A `manifest.json` file drives the character select screen. It sits
in the public folder of the repository, at
`Weftspun3DStudio/public/character-assets/manifest.json`.

Each entry is a character template. It works like a class in an MMO,
or a fighter in a video game.

![image](/img/B1DdAF3oa.png)

This screen can also load characters and traits that a user owns,
after that user connects a web3 wallet.

The project does not do this yet. The plan is to read the tokens a
user owns, then load a profile from them. The x-scan feature of the
[AdWorld character creator](https://adworld.game/) works this way.

Each character holds its own traits, in its own `manifest.json`
file. This file names them:

```json!
[
  {
    "name": "Feminine",
    "description": "Anata Female",
    "portrait": "./assets/portraitImages/anata.png",
    "manifest":"./anata-vrm/female/manifest.json",
    "icon": "./assets/icons/class-neural-hacker.svg",
    "format": "vrm"
  },
  {
    "name": "Masculine",
    "description": "Anata Male",
    "portrait": "./assets/portraitImages/anata_male.png",
    "manifest":"./anata-vrm/male/manifest.json",
    "icon": "./assets/icons/class-neural-hacker.svg",
    "format": "vrm"
  }
]
```

The next section describes each of those `manifest.json` files.
