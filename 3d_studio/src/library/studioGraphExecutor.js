/**
 * Run studio graph nodes via TaskContext createAndStartTask.
 * Keeps download URL rules aligned with taskModelUrl (job download path).
 */
import { resolveTextToImageDownloadUrl, getTaskResultModelUrl, getTaskResultMeshUrl, getTaskResultMotionUrl, getTaskResultLayersUrl, getTaskResultPsdUrl, getTaskResultCompositeUrl, getTaskResultLayerCount, resolveTaskModelUrl } from './taskModelUrl.js';
import {
  buildOrthographicMultiviewPrompts,
  buildTextToImagePrompt,
  createMultiviewSeed,
  normalizeTextToImagePromptOptions,
} from './textToImagePromptOptions.js';
import {
  getPromptText,
  getRunnablePipelineOrder,
  getTextToImagePromptOptions,
  STUDIO_NODE_KINDS,
  updateNode,
} from './studioGraph.js';
import { get3daigcAuthHeaders } from './taskManager.js';
import { slugifyObjectName } from './objectNameUtils.js';
import {
  getDefaultAutoRigOutputFormat,
  resolveAutoRigModelForTask,
} from './aiModelsCatalog.js';
import { AUTO_RIG_MODES, DEFAULT_HUMANOID_TEMPLATE_ID } from './avatarPipelineCatalog.js';
import { mapLayerNamesToAppearanceSlots } from './appearanceClothing.js';

/**
 * @param {string} relativeOrAbsoluteUrl
 * @param {string} apiEndpoint
 * @param {string} [filename]
 * @returns {Promise<File>}
 */
export async function fetchImageAsFile(relativeOrAbsoluteUrl, apiEndpoint, filename = 'studio.png') {
  const absolute = resolveTaskModelUrl(relativeOrAbsoluteUrl, apiEndpoint);
  if (!absolute) {
    throw new Error('No image URL to fetch for Image to 3D');
  }
  const response = await fetch(absolute, { headers: get3daigcAuthHeaders() });
  if (!response.ok) {
    throw new Error(`Failed to download image (${response.status})`);
  }
  const blob = await response.blob();
  const type = blob.type || 'image/png';
  return new File([blob], filename, { type });
}

/**
 * @param {object} apiResult
 * @param {{ getTask?: Function, listTasks?: Function }} deps
 * @param {string|null} jobId
 */
function resolveImageTaskRow(apiResult, deps, jobId) {
  let taskRow = null;
  if (deps.listTasks && jobId) {
    const all = typeof deps.listTasks === 'function' ? deps.listTasks() : [];
    taskRow = all.find((t) => t.job_id === jobId || t.result?.job_id === jobId) || null;
  }
  if (!taskRow) {
    taskRow = {
      id: null,
      type: 'text-to-image',
      status: 'completed',
      result: apiResult,
      job_id: jobId,
    };
  }
  return taskRow;
}

/**
 * Generate one Krea view; returns download URL + metadata.
 */
async function runSingleTextToImageView(createAndStartTask, deps, {
  prompt,
  promptOptions,
  modelPreference,
  objectName,
  seed,
  viewId,
}) {
  const apiResult = await createAndStartTask({
    type: 'text-to-image',
    prompt,
    imageFile: null,
    options: {
      model_preference: modelPreference || 'krea2_turbo_text_to_image',
      width: 1024,
      height: 1024,
      object_name: objectName,
      text_to_image_prompt_options: promptOptions,
      model_parameters: seed != null ? { seed } : undefined,
    },
  });
  const jobId = apiResult?.job_id || null;
  const taskRow = resolveImageTaskRow(apiResult, deps, jobId);
  const imageUrl = resolveTextToImageDownloadUrl(taskRow);
  if (!imageUrl) {
    throw new Error(`Text-to-image (${viewId || 'view'}) completed but no downloadable image URL`);
  }
  return { viewId: viewId || 'front', imageUrl, jobId, prompt, taskId: taskRow?.id || null };
}

/**
 * @param {object} project
 * @param {{
 *   createAndStartTask: Function,
 *   getTask?: Function,
 *   listTasks?: Function,
 *   apiEndpoint: string,
 *   onProjectChange?: (project: object) => void,
 *   onStatus?: (message: string) => void,
 * }} deps
 * @param {{
 *   until?: 'text_to_image' | 'image_to_3d' | 'auto_rigging' | 'motion_validation',
 *   skipKinds?: string[],
 * }} [opts]
 */
export async function runStudioPipeline(project, deps, opts = {}) {
  const { createAndStartTask, apiEndpoint, onProjectChange, onStatus } = deps;
  const until = opts.until || 'motion_validation';
  const skipKinds = new Set(opts.skipKinds || []);
  let current = project;
  const emit = (next) => {
    current = next;
    onProjectChange?.(current);
  };

  const prompt = getPromptText(current).trim();
  if (!prompt) {
    throw new Error('Enter a text prompt before running the pipeline');
  }

  const runnable = getRunnablePipelineOrder(current).filter((n) => !skipKinds.has(n.kind));

  for (const node of runnable) {
    if (node.kind === 'layer_decomposition' && until === 'text_to_image') {
      break;
    }
    if (node.kind === 'image_to_3d' && until === 'text_to_image') {
      break;
    }
    if (node.kind === 'motion_validation' && until !== 'motion_validation') {
      break;
    }
    if (node.kind === 'auto_rigging' && (until === 'text_to_image' || until === 'image_to_3d')) {
      break;
    }

    emit(updateNode(current, node.id, { status: 'running' }));

    if (node.kind === 'text_to_image') {
      const promptOptions = getTextToImagePromptOptions(current);
      const modelPreference = node.data?.modelPreference || 'krea2_turbo_text_to_image';
      const objectName = current.name || 'studio_image';

      try {
        if (promptOptions.all_orthographic_views) {
          const seed = createMultiviewSeed();
          const viewSpecs = buildOrthographicMultiviewPrompts(prompt, promptOptions);
          onStatus?.(
            `Queuing ${viewSpecs.length} orthographic views (shared seed ${seed})…`,
          );

          // Submit all views together so the API queue holds a consistent turnaround batch.
          const settled = await Promise.all(
            viewSpecs.map(async (spec, index) => {
              onStatus?.(
                `Generating ${spec.label} (${index + 1}/${viewSpecs.length}), seed ${seed}…`,
              );
              return runSingleTextToImageView(createAndStartTask, deps, {
                prompt: spec.prompt,
                promptOptions: normalizeTextToImagePromptOptions({
                  ...promptOptions,
                  camera_view: spec.viewId,
                }),
                modelPreference,
                objectName: `${objectName}_${spec.viewId}`,
                seed,
                viewId: spec.viewId,
              });
            }),
          );

          const primaryId = promptOptions.camera_view || 'front';
          const primary =
            settled.find((v) => v.viewId === primaryId) || settled[0];
          if (!primary?.imageUrl) {
            throw new Error('Multiview batch finished without a primary image');
          }

          emit(
            updateNode(current, node.id, {
              status: 'completed',
              data: {
                taskId: primary.taskId,
                imageUrl: primary.imageUrl,
                jobId: primary.jobId,
                composedPrompt: primary.prompt,
                multiviewSeed: seed,
                views: settled,
              },
            }),
          );
        } else {
          const composedPrompt = buildTextToImagePrompt(prompt, promptOptions);
          const single = await runSingleTextToImageView(createAndStartTask, deps, {
            prompt: composedPrompt,
            promptOptions,
            modelPreference,
            objectName,
            seed: null,
            viewId: promptOptions.camera_view || 'front',
          });
          emit(
            updateNode(current, node.id, {
              status: 'completed',
              data: {
                taskId: single.taskId,
                imageUrl: single.imageUrl,
                jobId: single.jobId,
                composedPrompt,
                views: [single],
              },
            }),
          );
        }
      } catch (err) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw err;
      }

      if (until === 'text_to_image') {
        break;
      }
      continue;
    }

    if (node.kind === 'layer_decomposition') {
      // Decompose the text-to-image result into semantic RGBA layers
      // (See-Through / LayerDiff) so image-to-3D consumes a clean,
      // depth-aligned subject and appearance traits are remixable.
      const imageNode = current.nodes.find((n) => n.kind === 'text_to_image');
      const imageUrl = imageNode?.data?.imageUrl;
      if (!imageUrl) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw new Error(
          'Layer Decomposition needs a completed Text to Image result. Run Generate image first, then decompose.',
        );
      }

      const views = Array.isArray(imageNode?.data?.views) ? imageNode.data.views : [];
      const primaryViewId =
        getTextToImagePromptOptions(current).camera_view || views[0]?.viewId || 'front';
      const primaryMeta =
        views.find((v) => v.viewId === primaryViewId) ||
        views[0] || { imageUrl, viewId: 'front' };

      onStatus?.('Decomposing image into semantic layers (See-Through)…');

      try {
        const baseName = slugifyObjectName(
          node.data?.objectName || current.name || 'studio',
          'studio',
        );
        const imageFile = await fetchImageAsFile(
          primaryMeta.imageUrl || imageUrl,
          apiEndpoint,
          `${baseName}_${primaryMeta.viewId || 'front'}.png`,
        );

        const objectName = slugifyObjectName(
          node.data?.objectName || current.name || 'studio_asset',
          'studio_asset',
        );
        const apiResult = await createAndStartTask(
          {
            type: 'image-to-layers',
            prompt: getPromptText(current) || 'Studio layer decomposition',
            imageFile,
            options: {
              model_preference:
                node.data?.modelPreference ||
                STUDIO_NODE_KINDS.layer_decomposition.defaultModel,
              object_name: objectName,
              resolution: node.data?.resolution ?? 768,
              seed: node.data?.seed ?? 42,
              tblr_split: node.data?.tblr_split ?? true,
            },
          },
          null,
        );

        const layerNames = Array.isArray(apiResult?.layer_names)
          ? apiResult.layer_names
          : Array.isArray(apiResult?.result?.layer_names)
            ? apiResult.result.layer_names
            : [];

        emit(
          updateNode(current, node.id, {
            status: 'completed',
            data: {
              taskId: apiResult?.task_id || null,
              jobId: apiResult?.job_id || null,
              objectName,
              layersUrl: getTaskResultLayersUrl(apiResult),
              psdUrl: getTaskResultPsdUrl(apiResult),
              compositeUrl: getTaskResultCompositeUrl(apiResult),
              layerCount: getTaskResultLayerCount(apiResult),
              appearanceSlots: mapLayerNamesToAppearanceSlots(layerNames),
            },
          }),
        );
      } catch (err) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw err;
      }
      continue;
    }

    if (node.kind === 'image_to_3d') {
      // Always read the latest image node from `current` (not a stale runnable snapshot).
      const imageNode = current.nodes.find((n) => n.kind === 'text_to_image');
      const imageUrl = imageNode?.data?.imageUrl;
      if (!imageUrl) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw new Error(
          'Image to 3D needs a completed Text to Image result. Run Generate image first, then Generate mesh.',
        );
      }

      // Prefer the flattened/composited subject from layer decomposition —
      // clean background, separated body parts, depth-aligned.
      const layersNode = current.nodes.find((n) => n.kind === 'layer_decomposition');
      const compositeUrl = layersNode?.data?.compositeUrl || null;
      const primaryImageFromLayers = compositeUrl || imageUrl;

      const views = Array.isArray(imageNode?.data?.views) ? imageNode.data.views : [];
      const primaryViewId =
        getTextToImagePromptOptions(current).camera_view || views[0]?.viewId || 'front';
      const primaryMeta =
        views.find((v) => v.viewId === primaryViewId) ||
        views[0] || { imageUrl, viewId: 'front' };
      const referenceMetas = views.filter((v) => v.viewId !== primaryMeta.viewId && v.imageUrl);

      onStatus?.(
        compositeUrl
          ? `Building TRELLIS mesh from decomposed layer composite…`
          : referenceMetas.length
            ? `Building TRELLIS multiview mesh (${1 + referenceMetas.length} views)…`
            : 'Building TRELLIS.2 mesh…',
      );

      try {
        const baseName = slugifyObjectName(
          node.data?.objectName || current.name || 'studio',
          'studio',
        );
        const imageFile = await fetchImageAsFile(
          primaryImageFromLayers,
          apiEndpoint,
          `${baseName}_${compositeUrl ? 'layers' : primaryMeta.viewId || 'front'}.png`,
        );

        const referenceFiles = [];
        for (const ref of referenceMetas) {
          referenceFiles.push(
            await fetchImageAsFile(ref.imageUrl, apiEndpoint, `${baseName}_${ref.viewId}.png`),
          );
        }

        const objectName =
          slugifyObjectName(node.data?.objectName || current.name || 'studio_asset', 'studio_asset');
        onStatus?.(`Submitting ${objectName} to mesh API…`);
        const apiResult = await createAndStartTask(
          {
            type: 'image-to-3d',
            prompt: getPromptText(current) || 'Studio image to 3D',
            imageFile,
            options: {
              model_preference:
                node.data?.modelPreference || 'trellis2_image_to_textured_mesh',
              object_name: objectName,
              reference_image_files: referenceFiles,
              use_multiview_mesh: referenceFiles.length > 0,
            },
          },
          null,
        );

        if (!apiResult?.job_id && !getTaskResultModelUrl(apiResult)) {
          emit(updateNode(current, node.id, { status: 'failed' }));
          throw new Error(
            'Image to 3D did not return a job id — check API connection and Task Manager.',
          );
        }

        const meshUrl =
          getTaskResultModelUrl(apiResult) ||
          getTaskResultModelUrl({ result: apiResult }) ||
          (apiResult?.job_id
            ? `/api/v1/system/jobs/${apiResult.job_id}/download`
            : null);

        emit(
          updateNode(current, node.id, {
            status: 'completed',
            data: {
              jobId: apiResult?.job_id || null,
              meshUrl,
              objectName,
              viewCount: 1 + referenceFiles.length,
            },
          }),
        );

        // Export stays pending until auto-rig finishes (or if rig is skipped).
        const exportNode = current.nodes.find((n) => n.kind === 'export_asset');
        const hasRig = current.nodes.some((n) => n.kind === 'auto_rigging');
        if (exportNode && !hasRig) {
          emit(
            updateNode(current, exportNode.id, {
              status: meshUrl ? 'completed' : 'ready',
              data: { meshUrl },
            }),
          );
        }
      } catch (err) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw err;
      }
      continue;
    }

    if (node.kind === 'auto_rigging') {
      const meshNode = current.nodes.find((n) => n.kind === 'image_to_3d');
      const meshUrl = meshNode?.data?.meshUrl;
      if (!meshUrl) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw new Error(
          'Auto Rigging needs a completed Image to 3D mesh. Run Generate mesh first.',
        );
      }

      const objectName = slugifyObjectName(
        node.data?.objectName || meshNode?.data?.objectName || current.name || 'studio_asset',
        'studio_asset',
      );
      const rigMode = node.data?.rigMode || AUTO_RIG_MODES.FULL;
      const modelPreference = resolveAutoRigModelForTask(
        rigMode,
        node.data?.modelPreference || 'skintokens_auto_rig',
      );

      onStatus?.(`Auto-rigging ${objectName} with ${modelPreference}…`);

      try {
        const meshFile = await fetchImageAsFile(
          meshUrl,
          apiEndpoint,
          `${objectName}.glb`,
        );
        const apiResult = await createAndStartTask(
          {
            type: 'auto-rigging',
            prompt: `Studio auto-rig ${objectName}`,
            imageFile: null,
            options: {
              object_name: objectName,
              model_preference: modelPreference,
              rig_mode: rigMode,
              output_format: getDefaultAutoRigOutputFormat(modelPreference, rigMode),
              humanoid_template_id:
                rigMode === AUTO_RIG_MODES.TEMPLATE
                  ? node.data?.humanoidTemplateId || DEFAULT_HUMANOID_TEMPLATE_ID
                  : undefined,
            },
          },
          meshFile,
        );

        const riggedUrl =
          getTaskResultMeshUrl(apiResult) ||
          getTaskResultModelUrl(apiResult) ||
          getTaskResultMeshUrl({ result: apiResult }) ||
          getTaskResultModelUrl({ result: apiResult }) ||
          (apiResult?.job_id
            ? `/api/v1/system/jobs/${apiResult.job_id}/download`
            : null);

        emit(
          updateNode(current, node.id, {
            status: 'completed',
            data: {
              jobId: apiResult?.job_id || null,
              meshUrl: riggedUrl || meshUrl,
              objectName,
              modelPreference,
              rigMode,
            },
          }),
        );

        const exportNode = current.nodes.find((n) => n.kind === 'export_asset');
        if (exportNode) {
          emit(
            updateNode(current, exportNode.id, {
              status: riggedUrl || meshUrl ? 'completed' : 'ready',
              data: { meshUrl: riggedUrl || meshUrl },
            }),
          );
        }
      } catch (err) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw err;
      }
    }

    if (node.kind === 'motion_validation') {
      // Kimodo text-to-motion doubles as body-rig validation: playback on the
      // rigged avatar exercises the skeleton, and the studio_motion.json is
      // the companion-runtime asset ("talk to your VRM").
      const rigNode = current.nodes.find((n) => n.kind === 'auto_rigging');
      const meshNode = current.nodes.find((n) => n.kind === 'image_to_3d');
      const riggedUrl = rigNode?.data?.meshUrl || meshNode?.data?.meshUrl;
      if (!riggedUrl) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw new Error(
          'Motion Validation needs a completed Auto Rigging result. Run Auto-rig first.',
        );
      }

      const objectName = slugifyObjectName(
        node.data?.objectName || rigNode?.data?.objectName || current.name || 'studio_asset',
        'studio_asset',
      );
      const motionPrompt =
        node.data?.motionPrompt ||
        `${getPromptText(current) || objectName} — gentle idle breathing loop`;

      onStatus?.(`Validating rig via Kimodo text-to-motion (${motionPrompt})…`);

      try {
        const apiResult = await createAndStartTask(
          {
            type: 'text-to-motion',
            prompt: motionPrompt,
            imageFile: null,
            options: {
              model_preference:
                node.data?.modelPreference ||
                STUDIO_NODE_KINDS.motion_validation.defaultModel,
              duration: node.data?.duration ?? 5,
              output_format: 'studio_motion',
              object_name: `${objectName}_motion`,
            },
          },
          null,
        );

        const motionUrl = getTaskResultMotionUrl(apiResult);
        if (!motionUrl) {
          emit(updateNode(current, node.id, { status: 'failed' }));
          throw new Error(
            'Motion Validation did not return a motion URL — check API connection and Task Manager.',
          );
        }

        emit(
          updateNode(current, node.id, {
            status: 'completed',
            data: {
              taskId: apiResult?.task_id || null,
              jobId: apiResult?.job_id || null,
              objectName,
              meshUrl: riggedUrl,
              motionUrl,
              motionPrompt,
            },
          }),
        );

        const exportNode = current.nodes.find((n) => n.kind === 'export_asset');
        if (exportNode) {
          emit(
            updateNode(current, exportNode.id, {
              status: 'completed',
              data: { meshUrl: riggedUrl, motionUrl },
            }),
          );
        }
      } catch (err) {
        emit(updateNode(current, node.id, { status: 'failed' }));
        throw err;
      }
    }
  }

  return current;
}
