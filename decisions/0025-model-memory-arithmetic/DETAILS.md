# RFD 0025 details: the three costs above the weights

- The load transient. A loader that reads the file into host memory,
  and then copies to the device, holds two copies. A loader that maps
  the file, and copies direct to the device, holds one copy.
- The runtime overhead. A CUDA context, the allocator, and the
  fragmentation add about 10 percent above the weights.
- The activation peak. This depends on the batch size, the resolution,
  and the step count. It does not depend on the parameter count.

The safe rule for one resident model is below.

```
device memory = weight GB x 1.1 + activation peak
```
