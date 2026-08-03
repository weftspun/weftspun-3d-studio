# RFD 0002: Studio pipeline graph

**State:** published
**Feature:** Studio pipeline

## Problem

A user wants to go from a text prompt to an animatable asset.
The steps are sequential. Each step needs a status and a result.

## Decision

Model the pipeline as a locked node graph. Each node is one stage.
Each edge is a dependency. The graph has two views: a flow graph
and a kanban board.

Stages, in order:

1. Prompt
2. Image
3. Layers
4. Mesh
5. Rig
6. Motion
7. Export

Runnable kinds, in order:

1. text_to_image
2. layer_decomposition
3. image_to_3d
4. auto_rigging
5. motion_validation

The data model stays pure. The executor runs the nodes. Old saved
projects migrate to the new template. Migration inserts missing
stages.

## References

- Data model: `src/library/studioGraph.js`
- Executor: `src/library/studioGraphExecutor.js`
- Page: `src/pages/StudioPage.jsx`
- Views: `src/components/studio/StudioGraphView.jsx`
- Views: `src/components/studio/StudioKanbanView.jsx`

## Related

RFD 0003 defines the job lifecycle. RFD 0006 defines layer
decomposition. RFD 0007 defines motion validation. RFD 0008 defines
appearance remix.
