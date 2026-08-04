---
sidebar_position: 6
---

# VRM to Thumbnails

The thumbnails generator makes a thumbnail for each asset in a trait group.

It takes one image per asset. It writes each image to disk, in a
subdirectory named for the trait group.

Use these thumbnails to update your character `manifest.json`.

---

Example:


```json
{
    "poseAnimation": "/Idle.fbx",
    "animationTime":0,
    "backgroundColor":[0,0,0,0],
    "screenshotOffset":[0,0],
    "topFrameOffset":0.1,
    "bottomFrameOffset":0.1,
    "thumbnailsWidth":512,
    "thumbnailsHeight":512,
    "thumbnailsCollection":[
        {
            "traitGroup":"CLOTHING",
            "cameraPosition":"front-left",
            "cameraFrame":"mediumShot",
            "groupTopOffset":0.1,
            "groupBotomOffset":0.1
        },
        {
            "traitGroup":"HAIR",
            "cameraPosition":"front-left",
            "cameraFrame":"mediumShot",
            "groupTopOffset":0.1,
            "groupBotomOffset":0.1
        }
    ]
}
```
