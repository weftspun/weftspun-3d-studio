---
sidebar_position: 4
---

# VRM to LoRA data

This manifest generates training data for a LoRA. A tool such as
[Kohya](https://github.com/bmaltais/kohya_ss) then trains on that
data.

The [VRM to LoRA guide](https://hackmd.io/@reneil1337/avatar-lora) by
[reneil1337](https://github.com/reneil1337) is the source of this
design.

![](/img/H1OJTfb36.jpg)

This part collects the screenshots from a VRM file and tags them.
Manual work takes a long time. The output is a set of images and text
files:

![Screenshot from 2024-02-14 12-17-25](/img/SkXX5KWnp.png)

The output text files look like this. The manifest file controls
each screenshot and its text:

```
anata a person slowly walking, full shot plain white background
anata a person saluting, medium shot plain white background
anata a person boxing, full shot plain white background
anata a person sitting on the floor plain white background
anata a person falling with open arms plain white background
anata a person crossing arms, medium shot plain white background
anata a person crossing arms, looking away from camera, full shot plain white background
anata a person dodging to the right, full shot plain white background
anata a person kneeling, full shot plain white background
anata a person kneeling, pointing away, full shot plain white background
anata a person with aiming pose plain white background
anata a person stranding, greeting plain white background
anata a person sitting straight with arms on hips plain white background
anata a person running plain white background
anata a person running away from viewer plain white background
anata a person in fight stance, medium shot plain white background
anata a person in fight stance, cowboy shot plain white background
anata a person doing a high kick, side view, full shot plain white background
anata a person kneeling straight, looking at camera plain white background
anata a person kneeling straight, facing away from camera plain white background
anata a person flexing muscles, full shot plain white background
anata a person strut walking, full frame plain white background
anata a person strut walking away from viewer plain white background
anata a person throwing a punch plain white background
anata a person hanging with arms, shot from behind plain white background
anata a person crawling plain white background
anata a person doing squats plain white background
anata a person sitting with leg crossed plain white background
anata a person in attack stance plain white background
anata a person with taunting pose plain white background
anata a person dancing plain white background
anata a person posing for picture with raised leg plain white background
anata a person cheering with hands up plain white background
anata a person walking plain white background
anata a person posing for picture plain white background
```

For the rest of the steps, follow this guide: https://hackmd.io/@reneil1337/avatar-lora

---

This part of a `manifest.json` file exports LoRA training data. The
animations are mixamo files with no skin, which use Y-bot as the
character.

A later version adds support for VRMA files, the VRM animation
format.

```json!
{
    "assetsLocation": "./lora-assets/",
    "animationsDirectory": "/animations/",
    "backgroundGrayscale": 0,
    "backgroundDescription": "plain black background",
    "width":1024,
    "height":1024,
    "topFrameOffsetPixels":64,
    "bottomFrameOffsetPixels":64,
    "dataCollection":[
        {
            "animationPath":"Walking.fbx",
            "animationFrame":8,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":[-0.5,-0.2,1],
            "cameraFrame":"fullShot",
            "description":"a person slowly walking full shot"
        },
...
```

### Example File

https://github.com/M3-org/CharacterStudio/blob/lora-data-creator/public/lora-assets/manifest.json


<details>

<summary>View full example file</summary>

```json!
{
    "assetsLocation": "./lora-assets/",
    "animationsDirectory": "/animations/",
    "backgroundGrayscale": 0,
    "backgroundDescription": "plain black background",
    "width":1024,
    "height":1024,
    "topFrameOffsetPixels":64,
    "bottomFrameOffsetPixels":64,
    "dataCollection":[
        {
            "animationPath":"Walking.fbx",
            "animationFrame":8,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":[-0.5,-0.2,1],
            "cameraFrame":"fullShot",
            "description":"a person slowly walking full shot"
        },
        {
            "animationPath":"Salute.fbx",
            "animationFrame":30,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"mediumShot",
            "description":"a person saluting medium shot"
        },
        {
            "animationPath":"Boxing.fbx",
            "animationFrame":16,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left",
            "cameraFrame":"fullShot",
            "description":"a person boxing full shot"
        },
        {
            "animationPath":"SittingIdle.fbx",
            "animationFrame":15,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left-front",
            "cameraFrame":"fullShot",
            "description":"a person sitting on the floor"
        },
        {
            "animationPath":"FallArmsOpen.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person falling with open arms"
        },
        {
            "animationPath":"Taunt.fbx",
            "animationFrame":4,
            "lookAtCamera":false,
            "cameraPosition":"left",
            "cameraFrame":"fullShot",
            "description":"a person in fight pose"
        },
        {
            "animationPath":"Angry.fbx",
            "animationFrame":87,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"front",
            "cameraFrame":"mediumShot",
            "description":"a person crossing arms medium shot"
        },
        {
            "animationPath":"Angry.fbx",
            "animationFrame":333,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"back-right",
            "cameraFrame":"fullShot",
            "description":"a person crossing arms looking away from camera, full shot"
        },
        {
            "animationPath":"DodgingRight.fbx",
            "animationFrame":14,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person dodging to the right full shot"
        },
        {
            "animationPath":"KneelingPointing.fbx",
            "animationFrame":4,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front-left",
            "cameraFrame":"fullShot",
            "description":"a person kneeling full shot"
        },
        {
            "animationPath":"KneelingPointing.fbx",
            "animationFrame":45,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person kneeling pointing away full shot"
        },
        {
            "animationPath":"LookOverShoulder.fbx",
            "animationFrame":53,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left-back",
            "cameraFrame":"fullShot",
            "description":"a person looking back over shoulder full shot"
        },
        {
            "animationPath":"Strafe.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left",
            "cameraFrame":"fullShot",
            "description":"a person with aiming pose"
        },
        {
            "animationPath":"StandingGreeting.fbx",
            "animationFrame":65,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front-top",
            "cameraFrame":"fullShot",
            "description":"a person standing and greeting"
        },
        {
            "animationPath":"Shoved.fbx",
            "animationFrame":80,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front-left-top",
            "cameraFrame":"fullShot",
            "description":"a person sitting straight with arms on hips"
        },
        {
            "animationPath":"Running.fbx",
            "animationFrame":3,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left-front",
            "cameraFrame":"fullShot",
            "description":"a person running"
        },
        {
            "animationPath":"Running.fbx",
            "animationFrame":3,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"back",
            "cameraFrame":"fullShot",
            "description":"a person running away from viewer"
        },
        {
            "animationPath":"Running.fbx",
            "animationFrame":3,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person running towards from viewer"
        },
        {
            "animationPath":"DoubleLegTakedown-Attacker.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person in fight stance looking at viewer"
        },
        {
            "animationPath":"DoubleLegTakedown-Attacker.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"front-left",
            "cameraFrame":"mediumShot",
            "description":"a person in fight stance medium shot"
        },
        {
            "animationPath":"DoubleLegTakedown-Attacker.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"left",
            "cameraFrame":"cowboyShot",
            "description":"a person in fight stance, cowboy shot"
        },
        {
            "animationPath":"MmaKick.fbx",
            "animationFrame":20,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"right",
            "cameraFrame":"fullShot",
            "cameraLocalOffset":[0.5,0,0],
            "description":"a person doing a high kick side view, full shot"
        },
        {
            "animationPath":"PullPlant.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person kneeling straight looking at camera"
        },
        {
            "animationPath":"PullPlant.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"back-right",
            "cameraFrame":"fullShot",
            "description":"a person kneeling straight facing away from camera"
        },
        {
            "animationPath":"FemaleCrouchPose.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"mediumShot",
            "description":"a person flexing muscles facing away from camera medium shot"
        },
        {
            "animationPath":"StrongGesture.fbx",
            "animationFrame":37,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front-top",
            "cameraFrame":"fullShot",
            "description":"a person flexing muscles full shot"
        },
        {
            "animationPath":"StrutWalking.fbx",
            "animationFrame":12,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front-left-top",
            "cameraFrame":"fullShot",
            "description":"a person strut walking full frame"
        },
        {
            "animationPath":"StrutWalking.fbx",
            "animationFrame":12,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"back-right",
            "cameraFrame":"fullShot",
            "description":"a person strut walking away from viewer"
        },
        {
            "animationPath":"Punching.fbx",
            "animationFrame":16,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left",
            "cameraFrame":"cowboyShot",
            "description":"a person throwing a punch"
        },
        {
            "animationPath":"Swinging.fbx",
            "animationFrame":13,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"back",
            "cameraFrame":"fullShot",
            "description":"a person hanging with arms shot from behind"
        },
        {
            "animationPath":"GolfPre-Putt.fbx",
            "animationFrame":94,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left",
            "cameraFrame":"fullShot",
            "description":"a person squatting raising hand"
        },
        {
            "animationPath":"Plank.fbx",
            "animationFrame":1,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"left-top-front",
            "cameraFrame":"fullShot",
            "description":"a person doing push-ups"
        },
        {
            "animationPath":"Crawling.fbx",
            "animationFrame":16,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":[0.5,1,-1],
            "cameraFrame":"fullShot",
            "description":"a person crawling"
        },
        {
            "animationPath":"AirSquat.fbx",
            "animationFrame":30,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person doing squats"
        },
        {
            "animationPath":"FemaleSittingPose.fbx",
            "animationFrame":30,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front-left",
            "cameraFrame":"fullShot",
            "description":"a person sitting with leg crossed"
        },
        {
            "animationPath":"MaleActionPose.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"left",
            "cameraFrame":"fullShot",
            "description":"a person in attack stance"
        },
        {
            "animationPath":"Taunt2.fbx",
            "animationFrame":61,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"left-front",
            "cameraFrame":"fullShot",
            "description":"a person with taunting pose"
        },
        {
            "animationPath":"Threatening.fbx",
            "animationFrame":50,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"front",
            "cameraFrame":"mediumShot",
            "description":"a person threatening"
        },
        {
            "animationPath":"Taunt3.fbx",
            "animationFrame":47,
            "lookAtCamera":false,
            "expression":"angry",
            "cameraPosition":"bottom-front",
            "cameraFrame":"mediumShot",
            "description":"a person taunting with open arms"
        },
        {
            "animationPath":"BootyHipHopDance.fbx",
            "animationFrame":44,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person dancing"
        },
        {
            "animationPath":"FemaleStandingPose.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person posing for picture with raised leg"
        },
        {
            "animationPath":"Cheering.fbx",
            "animationFrame":24,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":"front",
            "cameraFrame":"fullShot",
            "description":"a person cheering with hands up"
        },
        {
            "animationPath":"Female_Locomotion_Pose_1.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":[-0.5,0,1],
            "cameraFrame":"fullShot",
            "description":"a person walking"
        },
        {
            "animationPath":"Female_Locomotion_Pose.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"happy",
            "cameraPosition":[-0.5,0,1],
            "cameraFrame":"fullShot",
            "description":"a person posing for picture"
        },
        {
            "animationPath":"Sadness.fbx",
            "animationFrame":0,
            "lookAtCamera":false,
            "expression":"sad",
            "cameraPosition":[0.5,-0.5,1],
            "cameraFrame":"fullShot",
            "description":"a person standing sad"
        },
        {
            "animationPath":"Male_Sitting_Pose_1.fbx",
            "animationFrame":10,
            "lookAtCamera":false,
            "expression":"sad",
            "cameraPosition":[-0.5,-0.5,1],
            "cameraFrame":"fullShot",
            "description":"a person standing sad"
        }   
    ]
}
```

</details>

