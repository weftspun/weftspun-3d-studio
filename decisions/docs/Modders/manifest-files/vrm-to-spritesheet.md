---
sidebar_position: 5
---

# VRM to Spritesheet

The spritesheet generator works much like the LoRA generator. It
differs in one way: it puts the output images into an atlas, and it
also writes a gif preview.

This manifest file generates a spritesheet:

![](/img/simple-spritesheet-manifest.png)

![](/img/joy2.gif)

A general purpose spritesheet usually needs a walk cycle animation.
A game can use that sheet. A platform that supports sprite avatars
can also use it as a fallback avatar.

![](/img/walk2.gif)

---

The screenshots use the shot sizes in this cheatsheet:

![](/img/shotsize-cheatsheet.png)

`src/library/screenshotManager.js` holds four `cameraFrame` positions:

```javascript
  frameCloseupShot(){
    this.frameShot("head", "head")
  }
  frameMediumShot(){
    this.frameShot("chest", "head")
  }
  frameCowboyShot(){
    this.frameShot("hips", "head")
  }
  frameFullShot(){
    this.frameShot("leftFoot", "head")
  }
```

---

## Extension Research

**WIP**

M3 researches a glTF extension for spritesheets that work as
avatars. See https://hackmd.io/@XR/vrm-spritesheet.

An implementation might look like this:

```json
{
  "extensionsUsed": ["m3_spritesheet_animations"],
  "images": [
    {
      "uri": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
    }
  ],
  "extensions": {
    "m3_spritesheet_animations": {
      "spritesheets": [
        {
          "image": 0,
          "name": "Sprite Animations",
          "dimensions": { "width": 1024, "height": 1024, "framesH": 4, "framesV": 4 },
          "frameRate": 12,
          "animations": [
            { "name": "walking", "startFrame": 0, "endFrame": 3, "loop": true },
            { "name": "jumping", "startFrame": 4, "endFrame": 7, "loop": false }
          ]
        }
      ]
    }
  }
}
```
