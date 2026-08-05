# RFD 0069 details: the model table, the license split, the open questions

## What RF-DETR does

RF-DETR is a real-time transformer for object detection, instance
segmentation, and keypoint detection. It reports state-of-the-art
results on Microsoft COCO. Roboflow publishes it in variants that
trade accuracy against inference latency.

## The model table

| Variant          | Task         | Parameters   | License    |
| ---------------- | ------------ | -----------: | ---------- |
| Nano             | Detection    |       30.5 M | Apache 2.0 |
| Small            | Detection    |       32.1 M | Apache 2.0 |
| Medium           | Detection    |       33.7 M | Apache 2.0 |
| Large            | Detection    |       33.9 M | Apache 2.0 |
| XL               | Detection    |      126.4 M | PML 1.0    |
| 2XL              | Detection    |      126.9 M | PML 1.0    |
| Nano through 2XL | Segmentation | 33.6-38.6 M  | Apache 2.0 |
| Preview          | Keypoint     |       40.7 M | Apache 2.0 |

## The license split

RFD 0028 gates every model on commercial use. The Nano, Small,
Medium, and Large detection models clear the gate. Every
segmentation variant clears it too, and so does the keypoint preview
model. The XL and 2XL detection models carry PML 1.0, and RFD 0028
blocks them the way it blocks a non-commercial weight.

Roboflow's own hosted platform runs a separate license, AGPL-3.0,
over its 3.0 product. That license does not apply here. This RFD
runs the `rfdetr` package and its Apache-tagged weights directly,
and not the hosted platform.

## A second consumer: RFD 0048

RFD 0069 first served one consumer, RFD 0065's resolve step. A
second consumer needs the same detection, for a different reason.

RFD 0048 edits a mesh region from a reference image. Its guard
preserves every vertex outside the edited region, but the reference
image itself carries no such boundary. A whole-frame reference asks
VoxHammer to infer which part of the picture the caller means.

RF-DETR's segmentation output already draws that boundary, one mask
per detected trait. Crop the source image to one trait's mask, and
hand that crop to RFD 0048 as the reference image. The edit then
targets the trait the caller named, and no other.

## Composition with RFD 0044

Two entry points exist, and this RFD does not yet pick one.

RF-DETR can run over a raw dataset image, before any layer
decomposition. Or it can run over each RGBA layer RFD 0044's
composite already writes, after `a_write_psd`. The second order
gives a smaller, cleaner crop per detection, because the layer
already isolates one body part. The first order needs no
seethrough run at all, so it costs less per image.

## Open questions

**Fine-tuning.** RF-DETR trains on COCO, a real-world photo corpus.
RFD 0064's dataset is anime character art. A pretrained COCO
checkpoint may miss a stylized trait, such as a horn or a tail, that
COCO's classes never cover. Measure this before trusting the raw
checkpoint on the dataset.

**Packaging.** RFD 0036 packages a served model as a model image, one
model per catalog entry. The RFD 0065 consumer is an offline labeling
pass over a fixed dataset, and a script could cover it. The RFD 0048
consumer runs on demand, against whatever image a caller supplies at
edit time, and a script cannot serve that call. RF-DETR likely needs
an RFD 0036 model image folder for the second consumer, even if the
first consumer never calls it that way.

**The taxonomy join.** RFD 0065's rule 2 grows the trait taxonomy
from caption text. A detected visual label must resolve through the
same codebook, and not start a second, unlinked taxonomy. The
resolve step's guard needs a test that proves a visual detection and
a caption term for the same trait bind to one capability id.
