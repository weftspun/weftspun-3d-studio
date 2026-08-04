---
sidebar_position: 3
---


# Character Traits


Setting up this manifest will populate the asset trait section with your own traits that people can select from. It also drives the trait culling options. Weftspun 3D Studio removes the faces under a layer, so the triangles under a garment disappear.

![](/img/By1NZXbhT.jpg)


### Example Files

- https://github.com/memelotsqui/character-assets/blob/main/neurohacker/manifest.json
- https://github.com/M3-org/loot-assets/blob/main/loot/models/manifest.json


---

## Main Section
Includes generic and important information such as root assets location, and trait default values.

### assetsLocation
*required string*

The root location of every asset:

Example:
```json
"assetsLocation":"./character-assets/"
```
```json
"assetsLocation":"https://memelotsqui.github.io/character-assets"
```

### traitsDirectory
*optional string*

The subfolder that holds your traits:

Example:

```json
"traitsDirectory":"/traits/"
```

Weftspun3DStudio will search on assetLocation + traitsDirectory:

```./character-assets/traits/```


### thumbnailsDirectory
*optional string*

The subfolder that holds the trait thumbnails:

Example:

```json
"thumbnailsDirectory":"/traitsThumbnails/"
```

Weftspun3DStudio will search on assetLocation + thumbnailsDirectory:

```./character-assets/traitThumbnails/```


### traitIconsDirectorySvg
*optional string*

The subfolder that holds the trait SVG icons:

Example:

```json
"traitIconsDirectorySvg":"/traitIcons/"
```

Weftspun3DStudio will search on assetLocation + traitIconsDirectorySvg:

```./character-assets/traitIcons/```

### animationPath
*optional string array*

Animations that will played on the character for previewing, in case of using vrm traits, you may use Mecanim animations.

Example:

```json
"animationPath":["/animations/idle.fbx", "/animations/t-pose.fbx"]
```
Weftspun3DStudio will search on root directory + each animation path:

```./character-assets/animations/idle.fbx```

### displayScale
*optional number*

Default display scale value for character when previewing in 3d view, final model will not have this scale, default is 1

Example:
```json
"displayScale":0.7
```

### exportScale
*optional number*

Scale value for the exported model, default is 1

Example:
```json
"exportScale":0.7
```

### initialTraits
*optional object*

The traits the app selects when it loads the character. Keys are trait group IDs and values are trait IDs.

Example:
```json
"initialTraits": {
    "BODY": "Feminine",
    "CLOTHING": "Dress"
}
```

### requiredTraits
*optional string array*

Trait group names that must have at least one option selected. The trait collections hold the trait group names.

Example:
```json
"requiredTraits":["BODY", "CLOTHING"]
```

### randomTraits
*optional string array*

The trait groups the randomize button changes. The trait collections hold the trait group names.

Example:
```json
"randomTraits":["CLOTHING", "HAIR"]
```

### colliderTraits
*optional string array*

The trait groups that supply collider data, from the VRM file specification.

Example:
```json
"colliderTraits":["BODY"]
```

### lipSyncTraits
*optional string array*

The trait groups the lip sync preview uses during a test.

Example:
```json
"lipSyncTraits":["BODY"]
```

### blinkerTraits
*optional string array*

The trait groups the blink preview uses during a test.

Example:
```json
"blinkerTraits":["BODY"]
```

### traitRestrictions
*optional type object*

Definition for what traits cannot be together with other traits or types

**restrictedTraits *(optional string array)***: The traits that this trait excludes.

**restrictedTypes *(optional string array)***: The types that this trait excludes.


Example:
```json
"traitRestrictions":{
    "CLOTHING":{
      "restrictedTraits":[],
      "restrictedTypes":["hoodie"]
    }
}
```

### typeRestrictions
*optional type object*

Definition for what types cannot be together with other types

**type object *(optional string array)***: The types that another type excludes.



Example:
```json
"typeRestrictions":{
    "pants":["high_boots"]
 }
```

### defaultCullingLayer
*optional number (integer)*

The default culling layer for every trait model in the collection. The trait group, or the trait itself, can override it. Default is -1. Use integers only.

Culling layers go from -1 to any number. Lowest layer number trait (starting from 0) will get culled by higher layer number trait. This process skips a layer numbered -1.

Example:
```json
"defaultCullingLayer":0
```

### defaultCullingDistance
*optional array[2] number*

The default culling distance for every trait model in the collection, as an array of two numbers. The trait group, or the trait itself, can override it. Default is [0,0].

Example:
```json
"defaultCullingDistance":[0.1,0.01]
```



### offset
*optional array[3] number*

Character position offset from origin (array of 3 numbers: x, y, z). Default is [0,0,0].

Example:
```json
"offset":[0.0,0.1,0.0]
```

### canDownload
*optional boolean*

Whether a user may download the character. Default is true.

Example:
```json
"canDownload": false
```

### downloadOptions
*optional object*

Includes export download options for final downloaded 3d model.

```json
"downloadOptions":{
    "scale": 0.7,
    "exportStdAtlas": true,
    "exportMtoonAtlas": true,
    "mToonAtlasSize": 2048,
    "mToonAtlasSizeTransp": 2048,
    "stdAtlasSize": 2048,
    "stdAtlasSizeTransp": 2048,
    "screenshotFaceDistance": 1.0,
    "screenshotFaceOffset": [0, 0, 0],
    "screenshotResolution": [512, 512],
    "screenshotBackground": [0.1, 0.1, 0.1],
    "screenshotFOV": 75
}
```

### vrmMeta
*optional object*

The metadata that the download writes into the final VRM file.

Example:
```json
"vrmMeta":{
    "authors":["Author Name"],
    "version":"v1",
    "commercialUssageName": "personalNonProfit",
    "contactInformation": "https://example.com/", 
    "allowExcessivelyViolentUsage":false,
    "allowExcessivelySexualUsage":false,
    "allowPoliticalOrReligiousUsage":false,
    "allowAntisocialOrHateUsage":false,
    "creditNotation":"required",
    "allowRedistribution":false,
    "modification":"prohibited"
}
```

### chainName
*optional string*

Name of the blockchain chain for NFT integration.

Example:
```json
"chainName": "ethereum"
```

### collectionLockID
*optional string*

ID for locking the collection.

Example:
```json
"collectionLockID": "my-collection-123"
```

### dataSource
*optional string*

Source of the data for the collection. ("attributes", "image", "none")

Example:
```json
"dataSource": "attributes"
```

### solanaPurchaseAssets
*optional object*

Configuration for Solana purchase assets.

Example:
```json
"solanaPurchaseAssets": {
    "collectionAddress": "Add",
    "merkleTreeAddress":"AnrgANw3znNQ52TyAmBth7kqeTxbacyS8bWwezS6XP9J"
}
```

### price
*optional number*

Default price all assets of the character in the specified currency.

Example:
```json
"price": 10.99
```

### currency
*optional string*

Currency for the price.

Example:
```json
"currency": "USD"
```

### purchasable
*optional boolean*

Whether an asset defaults to purchasable.

Example:
```json
"purchasable": true
```

### locked
*optional boolean*

Whether an asset defaults to locked.

Example:
```json
"locked": false
```

___

## Trait Group Section (traits)
*required object array*

Includes trait collection and group specific information such as culling values.
An array holds every option below. This example shows a full trait option:
```json
  "traits": [
    {
      "trait": "head",
      "name": "head",
      "iconSvg": "head.svg",
      "cullingLayer":0,
      "cullingDistance":[0.01,0.001],
      "cameraTarget": {
        "distance": 0.75,
        "height": 1.35
      },
      "collection": [...]
    }
]
```

### trait
*required string*

The id of this trait group. It separates the trait groups into types.

Example:

```json
"trait":"BODY"
```

### name
*required string*

Display name for this group trait.

Example:

```json
"name":"Skin"
```

### iconSvg
*required string*

Display svg icon for this trait. This will be the icon that shows up on the left side menu when selecting traits. Location will be in:

```assetsLocation + traitIconsDirectorySvg + iconSvg```

Example:

```json
"iconSvg": "body-icon.svg"
```

### cullingLayer
*optional number (integer)*

An override for the default culling layer. Every trait in this collection takes this `cullingLayer` value. A trait with its own culling layer keeps that value.

Example:
```json
"cullingLayer":1
```

### cullingDistance
*optional array[2] number*

An override for the default culling distance, as an array of two numbers. The trait group, or the trait itself, can override it again. Default is [0,0].

Example:
```json
"cullingDistance":[0.2,0.0]
```

### cameraTarget
*required object*

Where the camera moves when a user selects this trait.

**distance**: Zoom distance from the Character.

**height**: Height distance from the floor.


Example:
```json
"cameraTarget": {
    "distance": 3.0,
    "height": 0.8
}
```

### collection (traits)
*required array of objects*

An array of all the traits that will be available for this trait group.

Each element from the array represent a single trait. This will be your options in the side menu when selecting any group trait

**id *(required string)***: The unique id of this trait. NFT metadata can fetch the value by this id.

**name *(required string)***: Display Name for this trait.

**directory *(required string)***: Relative location of the file model for this tait (Full location will be ```assetsLocation + traitsDirectory + directory```)

**thumbnail *(optional string)***: Relative location of the file model for this tait (Full location will be ```assetsLocation + traitsDirectory + directory```)

**cullingLayer *(optional number(integer))***: Override culling layer for this trait

**cullingDistance *(optional array[2] number)***: Override culling distance for this trait

**type *(optional array string)***: An array of type description of this trait, can be any descriptive word

**textureCollection *(optional string)***: The texture collection id. A user picks a texture from it for this trait. Use `textureCollection` or `colorCollection`, but not both.

**colorCollection *(optional string)***: The color collection id. A user picks a color from it for this trait. Use `textureCollection` or `colorCollection`, but not both.

Example:
```json
"collection": [
    {
          "id": "Feminine",
          "name": "Female",
          "directory": "BODY/feminine.vrm",
          "thumbnail": "BODY/feminine.png",
          "cullingLayer": 0,
          "cullingDistance": [0.3,0.001],
          "type": ["strong"],
          "textureCollection":"SKIN_TONES",
          "colorCollection":"SKIN_COLORS"
    }
]
```

**blendshapeTraits *(optional Object[])***: An array of Blendshape Trait definition. Let us you define blendshapes as traits. The export stage removes these blendshapes.
Note that we currently treat every blendshape trait (those defined in the manifest) as binary. I.e. they are either on or off.

```json
...
"collection": [
  {
    "id": "male",
    "name": "male",
    "directory": "Body/male.vrm",
    "thumbnail": "Body/male.png",
    "blendshapeTraits":[{      < ---------------
      "trait":"nose",
      "name":"Nose",
      "cameraTarget": {
        "distance": 0.75,
        "height": 1.5
      },
      "collection":[{
        "id":"Nose_LONG",
        "name":"Long Nose"
      }]
    }]
  }
]
```

A BlendshapeTrait Group definition has the following properties:

**trait *(string)***: Group id of the blendshape group.

**name *(string)***: Name of the blendshape group.

**cameraTarget *(optional Object)***: Define distance and height of the blendshape group.

**collection *( Array of Object)***: The Array of Blendshape traits, defined below.

> **id *(string)***: ID of the blendshape, this also has to be the exact blendshape name (case-sensitive)
>
> **name *(string)***: Name of the trait.
>
> **fullThumbnail *(optional string)***: Path to the thumbnail of that blendshape trait.




___

## Texture Collection Section (textureCollections):
Defines a collection of textures. A trait can take one of them.

```json
  "textureCollections": [
    {
      "trait": "SKIN_TONES",
      "collection": [...]
    }
]
```

### collection (textures)

An array of all the textures that will be available for this texture trait id.

**id *(required string)***: The unique id of this trait. NFT metadata can fetch the value by this id.

**name *(optional string)***: Display Name for this texture trait.

**directory *(required string)***: Relative location of the file texture for this tait (Full location will be ```assetsLocation + directory```)

**thumbnail *(optional string)***: Relative location of the file model for this tait (Full location will be ```assetsLocation + directory```)

```json
"collection": [
    {
          "id": "BELT_0",
          "name": "Belt 0",
          "directory": "_textureCollections/BeltOutfit3/belt_0.png",
          "thumbnail": "_textureCollections/BeltOutfit3/belt_0.png"
    }
]
```
___
## Color Collection Section (colorCollections):
Defines a collection of colors. A trait can take one of them.

```json
  "colorCollections": [
    {
      "trait": "SKIN_COLORS",
      "collection": [...]
    }
]
```

### collection (colors)

An array of all the textures that will be available for this texture trait id.

**id *(required string)***: The unique id of this color trait. NFT metadata can fetch the value by this id.

**name *(optional string)***: Display Name for this texture trait.

**value *(required string array)***: Color value enclosed in array.

```json
"collection": [
    {
          "id": "EMERALD",
          "name": "Emerald",
          "value":["#7BFFBA"]
    }
]
```

___

## Decal Collection Section (decalCollections):
Defines a collection of decals. A trait can take one of them.

```json
  "decalCollections": [
    {
      "trait": "DECALS",
      "collection": [...]
    }
]
```

### collection (decals)

An array of all the decals that will be available for this decal trait id.

**id *(required string)***: The unique id of this decal trait. NFT metadata can fetch the value by this id.

**name *(optional string)***: Display Name for this decal trait.

**directory *(required string)***: Relative location of the decal texture file.

**thumbnail *(optional string)***: Relative location of the thumbnail for this decal.

```json
"collection": [
    {
          "id": "STAR_DECAL",
          "name": "Star",
          "directory": "decals/star.png",
          "thumbnail": "decals/star_thumb.png"
    }
]
```

___
# Culling Distance

An array of two numbers holds the culling distance: `[outer, inner]`.

`Outer` sets how far a raycast travels along the outward normal before it hits something. A hit means a trait with a higher culling layer blocks the vertex, so the vertex stays hidden.

`Inner` sets how far a raycast travels along the inward normal before it hits something. A hit means a trait with a higher culling layer blocks the vertex, so the vertex stays hidden.

This option changes only how other traits act on this trait.
