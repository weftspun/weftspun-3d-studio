# Create an Avatar


There is a few ways to make an avatar with Weftspun3DStudio:

- Select from preloaded assets
- Drag and drop your own 3D models and textures
- Generate based on a manifest.json file

## Select traits

The simple way to dress an avatar is to pick from the assets the app loads. Mix them to build a style, as other character creator programs do.

![](/img/v2zJEiy.gif)

If you want to create your own preloaded asset configuration, check the manifest file documentation to learn more.

## Drag and drop your own assets

> Note: Files must be in VRM format, recommended to use version 0.0 for now

Weftspun3DStudio also features the ability to overwrite textures in a similar way as well. Select the trait whose texture you want to replace. Then drag the image file into the browser window. It would help if the image had a matching UV of the base mesh.


https://www.youtube.com/watch?v=zhpFK4Htxdo

Note: Make sure to click the category you are overwriting the trait for before drag and dropping into the browser window.

## Configure programmatically

> WIP

Weftspun3DStudio has the ability to assemble and export VRMs by loading a JSON file containing information about the traits. This process suits batch assembly of Anata VRM files. It does not yet serve a general purpose.

The project studies ways to read owned assets from a connected
wallet. Code could then configure avatars and wearables.

One idea loads POAPs and other approved collections as
[badges and pins](https://sketchfab.com/3d-models/3d-skill-role-badges-and-pins-e3329ed59b874aad98586657a5f11630).
You attach these to a wearable.

![](/img/rFV2t9G.png)

To learn how to configure an avatar from code, or to create a VRM
collection, join the [M3 discord](https://m3org.com/discord) and
introduce yourself.

A developer can also read the documentation on the manifest files.
The discord holds discussion about this method of avatar assembly.
