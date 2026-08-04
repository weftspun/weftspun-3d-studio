# Character animations
Two ways add animations to a character.

## Default animations

The `defaultAnimations` array in the main manifest names the
animation files. Add as many as you need. Every character that loads
gets these animations.

```json!
{
  "defaultAnimations":[
    {
      "name": "T-Pose",
      "description": "1_T-Pose",
      "location":"./animations/T-Pose.fbx",
      "icon": "|"
    },
    {
      "name": "Idle",
      "description": "Basic Dance Animation",
      "location":"./animations/2_Idle.fbx",
      "icon": "|"
    },
    {
      "name": "Walking",
      "description": "Basic Walk Animation",
      "location":"./animations/3_Walking.fbx",
      "icon": "|"
    },
    {
      "name": "Waving",
      "description": "Basic Waving Animation",
      "location":"./animations/4_Waving.fbx",
      "icon": "|"
    }
  ]
}
```

## Per character animations

The `animationPath` field in `manifest.json` names the animation
files. This example comes from the
[loot-assets manifest](https://github.com/M3-org/loot-assets/blob/main/loot/models/manifest.json):

```json!
{
  "assetsLocation": "./loot-assets/",
  "format": "vrm",
  "traitsDirectory": "./models/",
  "thumbnailsDirectory": "./models/",
  "exportScale": 1,
  "animationPath": [
    "./animations/1_T-Pose.fbx",
    "./animations/2_Idle.fbx",
    "./animations/3_Walking.fbx",
    "./animations/4_Waving.fbx"
  ],
  "traitIconsDirectorySvg": "./icons/",
  "defaultCullingLayer": -1,
  "defaultCullingDistance": [
    0.1,
    0.01
  ],
...
```
The first animation file in the list matters most. Batch processing
of many `manifest.json` files depends on it, when you assemble many
VRM files at once.

1. A screenshot of a VRM uses the first animation file. The
   screenshot previews the collection. An export of the real files
   takes much longer.


Here an `a-pose.fbx` animation overrides the avatars, for previews:
![](/img/5erJutX.gif)


2. The animations also help during batch processing. Load many
   `manifest.json` files, then scroll through them while the default
   animation plays. This finds clipping and weight problems more
   quickly.

![](/img/LbTte4L.gif)


The project retargets VRM avatars with mixamo rigged animations
**without skin**. Always select the `In place` box. If you do not,
the avatar walks off the screen.

These links help:

- https://www.mixamo.com/
- https://github.com/M3-org/CharacterStudio/tree/main/public/3d/animations

![Screenshot_2024-02-19_21-25-22](/img/HJMapKb36.jpg)

