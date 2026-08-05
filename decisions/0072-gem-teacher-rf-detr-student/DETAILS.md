# RFD 0072 details: the license terms, the joint mapping, the open questions

## The license terms

GEM-X's source code carries Apache 2.0, copyright NVIDIA Corporation
and Affiliates. The model weights carry a separate document, the
NVIDIA Open Model License Agreement. Four terms matter here.

1. NVIDIA grants a perpetual, worldwide, non-exclusive, no-charge,
   royalty-free right to use, reproduce, distribute, and create
   derivative works of the model.
2. A "Derivative Model" is defined broadly: every modification, and
   every work based on the model. A student model fine-tuned on the
   teacher's output counts.
3. The user owns their Model Derivatives, subject to NVIDIA's
   underlying rights in the base model. NVIDIA claims no ownership
   over outputs, and the user answers for how an output is used.
4. Bypassing a safety guardrail in the model ends the license. This
   RFD's use, reading a pose and nothing else, does not touch that
   clause.

RFD 0028's gate clears this model. It clears it on the same terms
RFD 0069 already reads for RF-DETR: a stated commercial-use
permission, checked against the actual document, and not a summary.

## The joint mapping

GEM returns 77 joints, body, hands, and face together, in the SOMA
format. RF-DETR Keypoint defaults to COCO's 17-joint format, but a
fine-tune can target any joint count, the same way a Roboflow
example retrains it to 33 landmarks for a basketball court.

Two paths exist, and this RFD does not yet pick one.

The narrow path maps GEM's 77 joints down to the 17 COCO joints RFD
0071 already reads. RFD 0071's gate logic changes nothing, and only
the training data's source changes, from none to GEM's pseudo-labels.

The wide path fine-tunes RF-DETR toward a joint set closer to SOMA's
77, such as adding spine curvature or per-finger joints. This gives
RFD 0071's tolerance check more resolution, at the cost of changing
the gate's own logic, not only its training data.

## Open questions

**Single-image input.** GEM's own documentation describes it as a
video-based model, built for monocular video with a dynamic camera.
RFD 0064's dataset holds single static images, not video. Confirm
GEM accepts one frame as a one-frame video before this RFD commits
to it. If it does not, this RFD needs a different teacher.

**The teacher's own domain gap.** GEM trains on NVIDIA-owned data,
which reads as real-world and not stylized. The same anime-art gap
RFD 0071 flags for RF-DETR may apply to GEM as well. A teacher that
guesses wrong on anime art teaches the student its own error.
Measure GEM's output against a small hand-checked sample of RFD
0064's dataset before trusting it at scale.

**Offline compute cost.** GEM's README states Python 3.10+, PyTorch
2.1+, and CUDA 12.6+, with an ONNX/TensorRT accelerated path
available. No throughput figure is stated. Measure the cost of one
pass over RFD 0064's roughly 15,000 images before committing to it
as the label source.
