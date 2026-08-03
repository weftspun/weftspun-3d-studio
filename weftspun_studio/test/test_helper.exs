# CUDA tests need the NVIDIA runtime libraries (nccl, cublas, cudart,
# cudnn, nvshmem) and XLA_TARGET=cuda12. Run them with:
#     mix test --include cuda
ExUnit.configure(exclude: [:cuda])
ExUnit.start()
