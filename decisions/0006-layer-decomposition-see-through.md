# RFD 0006: Layer decomposition (See-Through)

**State:** discussion
**Feature:** image-to-layers

## Problem

An anime illustration is one flat image. A user wants to edit the
hair, the face, and the clothing separately. Image to 3D also works
better with a clean subject.

## Decision

Add a layer decomposition stage between text to image and image to
3D. The stage runs the See-Through model.

The task decomposes one image into RGBA body-part layers. It returns
a layers zip, a PSD, a composite URL, and a layer count. The Studio
pipeline stores the artifacts on the layer_decomposition node.
Image to 3D prefers the composite image as its input.

## References

- Paper: https://doi.org/10.1145/3799902.3811209
- Cog model: weftspun/see-through (branch cog)
- Executor: `src/library/taskManager.js`
- URLs: `src/library/taskModelUrl.js`

## Related

RFD 0002 places the stage in the pipeline. RFD 0008 remixes the
layers into appearance traits. RFD 0004 catalogs the task.
