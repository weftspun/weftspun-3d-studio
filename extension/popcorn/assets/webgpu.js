/**
 * Runs one naive WGSL compute kernel and reads the answer back.
 *
 * Nothing here knows what the kernel computes. It takes WGSL, binds
 * one storage buffer per input, binds one for the output, dispatches,
 * and copies the result to the host. That is the whole contract, so a
 * faster kernel needs no change in this file.
 */

const WORKGROUP_SIZE = 64;

/** What the runtime offers, without starting any work. */
export async function probeWebGpu() {
  if (typeof navigator === "undefined" || !navigator.gpu) {
    return { supported: false, reason: "navigator.gpu is not defined" };
  }

  let adapter;
  try {
    adapter = await navigator.gpu.requestAdapter();
  } catch (error) {
    return { supported: false, reason: `requestAdapter threw: ${error}` };
  }

  if (!adapter) {
    return { supported: false, reason: "no adapter, which means no usable GPU" };
  }

  const info = adapter.info ?? {};
  return {
    supported: true,
    vendor: info.vendor ?? "",
    architecture: info.architecture ?? "",
    device: info.device ?? "",
    description: info.description ?? "",
    maxWorkgroupSizeX: adapter.limits?.maxComputeWorkgroupSizeX ?? null,
    adapter,
  };
}

/**
 * Compiles and runs one job.
 *
 * @param {GPUDevice} device
 * @param {{source: string, buffers: number[][], length: number}} job
 * @returns {Promise<number[]>}
 */
export async function runKernel(device, job) {
  const module = device.createShaderModule({ code: job.source });

  // Ask for compilation messages first. A WGSL error otherwise surfaces
  // later as an unrelated validation failure, which is hard to read.
  const compilation = await module.getCompilationInfo?.();
  const errors = (compilation?.messages ?? []).filter((m) => m.type === "error");
  if (errors.length > 0) {
    throw new Error(`WGSL: ${errors.map((m) => `${m.lineNum}: ${m.message}`).join("; ")}`);
  }

  const pipeline = device.createComputePipeline({
    layout: "auto",
    compute: { module, entryPoint: "main" },
  });

  const inputs = job.buffers.map((values) => {
    const buffer = device.createBuffer({
      size: Math.max(4, values.length * 4),
      usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(buffer, 0, new Float32Array(values));
    return buffer;
  });

  const outputBytes = Math.max(4, job.length * 4);
  const output = device.createBuffer({
    size: outputBytes,
    usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC,
  });
  const readback = device.createBuffer({
    size: outputBytes,
    usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST,
  });

  const entries = [...inputs, output].map((buffer, binding) => ({
    binding,
    resource: { buffer },
  }));
  const bindGroup = device.createBindGroup({
    layout: pipeline.getBindGroupLayout(0),
    entries,
  });

  const encoder = device.createCommandEncoder();
  const pass = encoder.beginComputePass();
  pass.setPipeline(pipeline);
  pass.setBindGroup(0, bindGroup);
  pass.dispatchWorkgroups(Math.ceil(job.length / WORKGROUP_SIZE));
  pass.end();
  encoder.copyBufferToBuffer(output, 0, readback, 0, outputBytes);
  device.queue.submit([encoder.finish()]);

  await readback.mapAsync(GPUMapMode.READ);
  const values = Array.from(new Float32Array(readback.getMappedRange()).slice(0, job.length));
  readback.unmap();

  for (const buffer of [...inputs, output, readback]) {
    buffer.destroy();
  }

  return values;
}
