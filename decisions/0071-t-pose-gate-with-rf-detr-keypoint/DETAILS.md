# RFD 0071 details: the keypoint set, the tolerance, the open questions

## The keypoint set

RF-DETR Keypoint (Preview) trains on COCO Keypoints, 17 points per
person: nose, left and right eye, left and right ear, left and
right shoulder, left and right elbow, left and right wrist, left and
right hip, left and right knee, left and right ankle.

Each keypoint returns as an (x, y, visibility) triplet, with a
confidence score and an uncertainty ellipse from a learned
covariance matrix. A gate can read the confidence, and not just the
position, before it trusts a joint.

The model reports 71.8 AP50:95 at 9.7 ms on an NVIDIA T4. RFD 0043's
diffusion edit costs far more than 9.7 ms, so the gate adds little
to the total cost of a rejected image, and nothing to an accepted
one beyond the one keypoint call.

## The tolerance, not yet fixed

"Arms near horizontal, legs together, spine vertical" names the
shape, and not a number. A T-pose gate needs an angle tolerance per
joint pair, such as the shoulder-elbow-wrist angle against 180
degrees, before this RFD moves past discussion. Measure a set of
known-good T-pose edits from RFD 0043, and derive the tolerance from
that set, rather than guess one.

## Open questions

**The retry loop's home.** Rejecting an image tells a caller to
retry RFD 0043, but nothing in this RFD says who calls the retry.
Candidates are RFD 0043's own Cog, a taskweft guard if RFD 0043
gains a composite domain, or the job lifecycle RFD 0003 already
runs in `weftspun_studio`. Decide this before implementation.

**Anime art, again.** RFD 0069 flags the same caveat for its
detection and segmentation modes: RF-DETR trains on COCO, a
real-photo corpus, and RFD 0064's dataset is anime character art.
A T-pose anime figure may carry joint proportions the COCO-trained
keypoint model was never shown. Measure this gate's accuracy on a
sample of RFD 0064's dataset before trusting it as a hard reject.

**A retry ceiling.** A pose that never converges would loop RFD 0043
forever. This RFD needs a retry limit, and a path for the caller
when that limit is reached.
