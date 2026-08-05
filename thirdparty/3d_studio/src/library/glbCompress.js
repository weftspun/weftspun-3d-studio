/**
 * Browser GLB compression — Draco geometry, optional Meshopt simplify, WebP textures.
 * Pipeline adapted from glb-shrink (MIT).
 */
import { NodeIO } from '@gltf-transform/core';
import {
  KHRDracoMeshCompression,
  KHRMeshQuantization,
  ALL_EXTENSIONS,
} from '@gltf-transform/extensions';
import {
  weld,
  simplify,
  textureCompress,
  prune,
  dedup,
  draco,
} from '@gltf-transform/functions';
import { MeshoptSimplifier, MeshoptDecoder, MeshoptEncoder } from 'meshoptimizer';
import draco3d from 'draco3dgltf';
import {
  formatByteSize,
  getCompressHint,
  resolveCompressProfile,
} from './glbCompressPresets.js';

let ioPromise;

async function getIO() {
  if (!ioPromise) {
    ioPromise = (async () => {
      await MeshoptDecoder.ready;
      await MeshoptEncoder.ready;
      await MeshoptSimplifier.ready;
      return new NodeIO()
        .registerExtensions(ALL_EXTENSIONS)
        .registerDependencies({
          'draco3d.decoder': await draco3d.createDecoderModule(),
          'draco3d.encoder': await draco3d.createEncoderModule(),
          'meshopt.decoder': MeshoptDecoder,
          'meshopt.encoder': MeshoptEncoder,
        });
    })();
  }
  return ioPromise;
}

function countTriangles(root) {
  let tris = 0;
  for (const mesh of root.listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      const indices = prim.getIndices();
      if (indices) tris += Math.floor(indices.getCount() / 3);
    }
  }
  return tris;
}

function countVertices(root) {
  let verts = 0;
  for (const mesh of root.listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      const position = prim.getAttribute('POSITION');
      if (position) verts += position.getCount();
    }
  }
  return verts;
}

export function documentNeedsSafeMode(root) {
  for (const mesh of root.listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      // Morph targets live on Primitive in this gltf-transform
      // version, not Mesh — mesh.listTargets() doesn't exist and
      // threw on every real call this function ever made.
      if (prim.listTargets().length > 0) return true;
      if (prim.getAttribute('JOINTS_0') || prim.getAttribute('WEIGHTS_0')) {
        return true;
      }
    }
  }
  return false;
}

function rebakeSmoothNormals(doc, root) {
  for (const mesh of root.listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      const position = prim.getAttribute('POSITION');
      const indices = prim.getIndices();
      if (!position || !indices) continue;

      const posArr = position.getArray();
      const idxArr = indices.getArray();
      if (!posArr || !idxArr) continue;

      const vCount = position.getCount();
      const normals = new Float32Array(vCount * 3);

      for (let t = 0; t < idxArr.length; t += 3) {
        const a = idxArr[t];
        const b = idxArr[t + 1];
        const c = idxArr[t + 2];

        const ax = posArr[a * 3];
        const ay = posArr[a * 3 + 1];
        const az = posArr[a * 3 + 2];
        const bx = posArr[b * 3];
        const by = posArr[b * 3 + 1];
        const bz = posArr[b * 3 + 2];
        const cx = posArr[c * 3];
        const cy = posArr[c * 3 + 1];
        const cz = posArr[c * 3 + 2];

        const abx = bx - ax;
        const aby = by - ay;
        const abz = bz - az;
        const acx = cx - ax;
        const acy = cy - ay;
        const acz = cz - az;

        const nx = aby * acz - abz * acy;
        const ny = abz * acx - abx * acz;
        const nz = abx * acy - aby * acx;

        normals[a * 3] += nx;
        normals[a * 3 + 1] += ny;
        normals[a * 3 + 2] += nz;
        normals[b * 3] += nx;
        normals[b * 3 + 1] += ny;
        normals[b * 3 + 2] += nz;
        normals[c * 3] += nx;
        normals[c * 3 + 1] += ny;
        normals[c * 3 + 2] += nz;
      }

      for (let i = 0; i < vCount; i++) {
        const nx = normals[i * 3];
        const ny = normals[i * 3 + 1];
        const nz = normals[i * 3 + 2];
        const len = Math.sqrt(nx * nx + ny * ny + nz * nz);
        if (len > 1e-8) {
          normals[i * 3] = nx / len;
          normals[i * 3 + 1] = ny / len;
          normals[i * 3 + 2] = nz / len;
        } else {
          normals[i * 3] = 0;
          normals[i * 3 + 1] = 1;
          normals[i * 3 + 2] = 0;
        }
      }

      const existingNormal = prim.getAttribute('NORMAL');
      if (existingNormal) {
        existingNormal.setArray(normals).setType('VEC3').setNormalized(false);
      } else {
        const accessor = doc.createAccessor().setArray(normals).setType('VEC3');
        prim.setAttribute('NORMAL', accessor);
      }
    }
  }
}

async function canvasWebpEncoder(buffer, mimeType) {
  const supported =
    mimeType === 'image/png' || mimeType === 'image/jpeg' || mimeType === 'image/webp';
  if (!supported || typeof document === 'undefined') {
    return buffer;
  }

  const blob = new Blob([buffer], { type: mimeType });
  const bitmap = await createImageBitmap(blob);
  const canvas = document.createElement('canvas');
  canvas.width = bitmap.width;
  canvas.height = bitmap.height;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(bitmap, 0, 0);
  bitmap.close();

  const webpBlob = await new Promise((resolve, reject) => {
    canvas.toBlob(
      (result) => (result ? resolve(result) : reject(new Error('WebP encode failed'))),
      'image/webp',
      0.75,
    );
  });

  return new Uint8Array(await webpBlob.arrayBuffer());
}

/**
 * @param {ArrayBuffer} arrayBuffer
 * @param {Object} options
 * @param {number} [options.quality] 0–100
 * @param {'smallest'|'balanced'|'sharpest'|'safe'} [options.preset]
 * @param {boolean} [options.includeTextures]
 */
export async function compressGlbBuffer(arrayBuffer, options = {}) {
  const beforeBytes = arrayBuffer.byteLength;
  const profile = resolveCompressProfile(options);
  const io = await getIO();
  const doc = await io.readBinary(new Uint8Array(arrayBuffer));
  const root = doc.getRoot();

  for (const ext of [...root.listExtensionsUsed()]) {
    const name = ext.extensionName;
    if (
      name === KHRDracoMeshCompression.EXTENSION_NAME ||
      name === KHRMeshQuantization.EXTENSION_NAME ||
      name === 'EXT_meshopt_compression'
    ) {
      ext.dispose();
    }
  }

  const sourceTris = countTriangles(root);
  const safeMode = options.safeMode ?? documentNeedsSafeMode(root);
  let simplifyRatio = profile.simplifyRatio ?? 0.008;
  if (profile.targetMaxTriangles > 0 && sourceTris > 0) {
    simplifyRatio = Math.min(simplifyRatio, profile.targetMaxTriangles / sourceTris);
  }
  const simplifyEnabled =
    profile.simplify !== false && simplifyRatio > 0 && !safeMode;

  const transforms = [weld({})];
  if (simplifyEnabled) {
    transforms.push(
      simplify({
        simplifier: MeshoptSimplifier,
        ratio: simplifyRatio,
        error: profile.simplifyError,
        lockBorder: false,
      }),
    );
  }
  transforms.push(dedup(), prune({ keepAttributes: false }));
  await doc.transform(...transforms);

  if (simplifyEnabled) {
    rebakeSmoothNormals(doc, root);
  }

  if (options.includeTextures !== false && profile.textureEdge > 0) {
    await doc.transform(
      textureCompress({
        encoder: canvasWebpEncoder,
        targetFormat: 'webp',
        resize: [profile.textureEdge, profile.textureEdge],
      }),
    );
  }

  await doc.transform(
    prune(),
    dedup(),
    draco({
      method: 'edgebreaker',
      quantizePosition: 14,
      quantizeNormal: 10,
      quantizeTexcoord: 12,
      quantizeGeneric: 12,
    }),
  );

  const output = await io.writeBinary(doc);
  const buffer = output.buffer.slice(output.byteOffset, output.byteOffset + output.byteLength);
  const finalTris = countTriangles(doc.getRoot());
  const afterBytes = buffer.byteLength;

  return {
    buffer,
    stats: {
      beforeBytes,
      afterBytes,
      sourceTris,
      finalTris,
      safeMode,
      simplifyApplied: simplifyEnabled,
      savingsPercent: beforeBytes > 0 ? Math.round((1 - afterBytes / beforeBytes) * 100) : 0,
      hint: safeMode
        ? 'Rig detected — geometry simplification skipped; Draco + textures only.'
        : getCompressHint(profile.quality),
      beforeLabel: formatByteSize(beforeBytes),
      afterLabel: formatByteSize(afterBytes),
    },
  };
}

/**
 * The fraction of the current mesh to keep so it lands at or under
 * both a vertex cap and a face cap, driven by whichever cap needs the
 * deeper cut. `headroom` leaves margin below the cap, because a
 * simplifier's output count is a target, not a guarantee.
 *
 * RFD 0061 names this an interim stopgap: the real target is
 * `idtx_core`'s chunked upload path in `thirdparty/fabric-flow-adapters`,
 * once that gets an Elixir NIF adapter and a weftspun_studio route.
 * This function exists so a caller with no NIF, no server change,
 * and no WASM build still gets a size-capped GLB today.
 */
export function computeApiUploadSimplifyRatio(
  sourceVerts,
  sourceFaces,
  maxVertices,
  maxFaces,
  headroom = 0.85,
) {
  if (sourceVerts <= maxVertices && sourceFaces <= maxFaces) return 1;

  const ratios = [];
  if (sourceVerts > maxVertices) ratios.push((maxVertices * headroom) / sourceVerts);
  if (sourceFaces > maxFaces) ratios.push((maxFaces * headroom) / sourceFaces);
  return Math.min(...ratios);
}

/**
 * Decimate a GLB down to a vertex/face cap for API upload — the
 * `image_to_textured_mesh`-style routes cap mesh size, and a mesh
 * over the cap must shrink before it uploads at all. Passes the
 * buffer through unchanged when it already fits.
 *
 * See `computeApiUploadSimplifyRatio`'s doc comment: RFD 0061 records
 * the intended replacement for this function.
 *
 * @param {ArrayBuffer} arrayBuffer
 * @param {Object} options
 * @param {number} [options.maxVertices]
 * @param {number} [options.maxFaces]
 */
export async function prepareGlbForApiUpload(arrayBuffer, options = {}) {
  const maxVertices = options.maxVertices ?? Infinity;
  const maxFaces = options.maxFaces ?? Infinity;

  const io = await getIO();
  const doc = await io.readBinary(new Uint8Array(arrayBuffer));
  const root = doc.getRoot();

  const sourceVerts = countVertices(root);
  const sourceFaces = countTriangles(root);

  if (sourceVerts <= maxVertices && sourceFaces <= maxFaces) {
    return {
      buffer: arrayBuffer,
      stats: { decimated: false, sourceVerts, sourceFaces, verts: sourceVerts, tris: sourceFaces },
    };
  }

  const safeMode = documentNeedsSafeMode(root);
  await doc.transform(weld({}));

  let verts = sourceVerts;
  let tris = sourceFaces;

  // simplify()'s ratio is relative to the *current* triangle count, not
  // the source — so each retarget pass measures fresh against the
  // current doc, rather than compounding the first pass's ratio.
  let attempts = 0;
  while (!safeMode && (verts > maxVertices || tris > maxFaces) && attempts < 5) {
    const stepRatio = computeApiUploadSimplifyRatio(verts, tris, maxVertices, maxFaces);
    await doc.transform(
      simplify({ simplifier: MeshoptSimplifier, ratio: stepRatio, error: 0.01, lockBorder: false }),
    );
    await doc.transform(dedup(), prune({ keepAttributes: false }));
    verts = countVertices(root);
    tris = countTriangles(root);
    attempts += 1;
  }

  if (verts > maxVertices || tris > maxFaces) {
    // TaskManager.jsx's skintokens call site awaits this and reads no
    // return value — it relies on a throw here to drive its "too
    // dense to auto-rig" warning. A joints/weights/morph-target mesh
    // skips decimation entirely (safeMode), so it can still land here
    // unchanged.
    throw new Error(
      safeMode
        ? `mesh has joints, weights, or morph targets — decimation was skipped to protect the rig, and it is still ${verts} verts / ${tris} tris over a ${maxVertices}/${maxFaces} cap`
        : `mesh is still ${verts} verts / ${tris} tris after ${attempts} decimation pass(es), over a ${maxVertices}/${maxFaces} cap`,
    );
  }

  if (attempts > 0) {
    rebakeSmoothNormals(doc, root);
  }

  const output = await io.writeBinary(doc);
  const buffer = output.buffer.slice(output.byteOffset, output.byteOffset + output.byteLength);

  return {
    buffer,
    stats: { decimated: attempts > 0, sourceVerts, sourceFaces, verts, tris },
  };
}

export { formatByteSize, getCompressHint, resolveCompressProfile };
