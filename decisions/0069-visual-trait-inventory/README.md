# RFD 0069: Visual trait detection with RF-DETR

**State:** discussion
**Scope:** RFD 0064's dataset, RFD 0065's resolve step, RFD 0044's
seethrough-layer-decomposition composite, RFD 0048's image edit

## Problem

RFD 0064's dataset holds about 15,000 character images. RFD 0065
resolves each trait from its caption text alone. A caption often
skips a trait the image still shows, such as a hidden accessory or
a background prop. RFD 0044's seethrough-layer-decomposition
composite splits an image into body-part layers, but it names no
trait inside each layer. No stage in the pipeline detects and
labels a visual trait from the pixels themselves.

RFD 0048 edits a mesh region from a reference image, over the whole
frame. A caller who wants to edit one trait, such as the hair alone,
has no way to hand VoxHammer a crop of that trait and nothing else.

## Decision

Detect and segment each trait with RF-DETR, an object detector,
segmenter, and keypoint model from Roboflow. Run it over RFD 0064's
dataset images, and over the layer outputs RFD 0044's composite
already produces.

Feed each detected label into RFD 0065's resolve step, through the
same HRR/HRR.Cleanup codebook RFD 0021 supplies. A visual trait then
binds to the same capability id a caption trait would bind to, so a
near-duplicate detection joins an existing id instead of minting a
new one.

Feed each segmented crop to RFD 0048 as its reference image, when a
caller asks to edit one trait. A precise crop targets the edit RFD
0048's whole-frame reference cannot.

Use the Apache 2.0 tier only. RFD 0028 gates every other license.
See `DETAILS.md` for the model table, the license split, the
composition order, and the open questions.

## References

- RF-DETR: https://github.com/roboflow/rf-detr

## Related

RFD 0064 gives the dataset this RFD scans. RFD 0065 gives the
resolve step a detected trait feeds. RFD 0044 gives the composite
this RFD runs beside. RFD 0048 takes a segmented crop as its
reference image. RFD 0021 gives the `HRR` library. RFD 0028 gives
the license gate this RFD's model choice must clear. RFD 0072 reads
this RFD's license check as its own precedent.
