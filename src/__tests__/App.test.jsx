import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from '../App';

// Mirrors the value object in SceneContext.jsx.
//
// A partial mock threw inside BottomDisplayMenu, the error boundary
// then replaced the whole tree, and every assertion below failed for
// one missing key. The mock must carry the whole shape.
//
// vi.hoisted, because vitest lifts vi.mock above the imports. A plain
// top level const is not initialized when the factory runs.
const sceneValue = vi.hoisted(() => {
  const value = {
    // State
    isInitialized: true,
    currentModel: null,
    activeWorldId: null,
    renderMode: 'solid',
    rendererType: 'webgl',
    isLoading: false,

    // Refs and managers
    containerRef: { current: null },
    sceneManager: null,
    characterManager: null,
    lookAtManager: null,
    animationManager: null,

    // Character manifests
    manifest: null,
    managersReady: false,
    lootBootstrapDone: false,
    expressionVrmRevision: 0,

    // Webcam avatar control
    webcamAvatarActive: false,
    webcamError: null,
    isWebcamControlActive: false,
  };

  // Every action on the context, as a no-op.
  for (const name of [
    'initializeScene', 'loadModel', 'loadWorldPackage', 'loadWorldFromManifestUrl',
    'loadWorldFromTaskResult', 'loadWorldEnvironment', 'clearWorld', 'updateRenderMode',
    'clearModel', 'exportModel', 'startRenderLoop', 'stopRenderLoop', 'getSceneData',
    'loadHDREnvironment', 'setLighting', 'setLightIntensity', 'setCameraMode',
    'resetCamera', 'focusOnFace', 'setView', 'toggleStats', 'toggleAutoRotate',
    'takeScreenshot', 'toggleFullscreen', 'setAutoTone', 'setToneMapping', 'setExposure',
    'enableAR', 'enableVR', 'startWebcamControl', 'stopWebcamControl',
  ]) {
    value[name] = () => {};
  }

  return value;
});

vi.mock('../context/SceneContext', async () => {
  const { createContext } = await import('react');
  return {
    // The context object itself, and not only the hook. Components
    // below App read it directly with useContext.
    SceneContext: createContext(sceneValue),
    SceneProvider: ({ children }) => <div data-testid="scene-provider">{children}</div>,
    useScene: () => sceneValue,
  };
});

vi.mock('../context/TaskContext', () => ({
  TaskProvider: ({ children }) => <div data-testid="task-provider">{children}</div>,
  useTask: () => ({
    isConnected: false,
    tasks: [],
    isLoading: false,
    checkConnection: vi.fn(),
    forceConnectionCheck: vi.fn(),
    setApiEndpoint: vi.fn(),
    getApiEndpoint: () => '',
    createAndStartTask: vi.fn(),
    removeTask: vi.fn(),
    clearCompletedTasks: vi.fn(),
    adoptJobHandoff: vi.fn(),
    syncTasksFromApi: vi.fn(),
  })
}));

// Mock components
vi.mock('../components/Scene3D', () => ({
  default: () => <div data-testid="scene-3d">Scene3D Component</div>
}));

vi.mock('../components/TaskManager', () => ({
  default: () => <div data-testid="task-manager">TaskManager Component</div>
}));

// FileUpload and RenderModeSelector are not mocked, because App does
// not render either one. App never imports FileUpload. It imports
// RenderModeSelector on line 12 and never uses it, which is a dead
// import in App.jsx.

vi.mock('../components/APIStatus', () => ({
  default: () => <div data-testid="api-status">APIStatus Component</div>
}));

// The product name carries spaces. This test asked for
// "Weftspun3DStudio", which no longer matches the header.
const APP_NAME = 'Weftspun 3D Studio';

describe('App', () => {
  it('should render the main application', () => {
    render(<App />);

    expect(screen.getByText(APP_NAME)).toBeInTheDocument();
    expect(screen.getByTestId('scene-provider')).toBeInTheDocument();
    expect(screen.getByTestId('task-provider')).toBeInTheDocument();
  });

  it('should render all main components', () => {
    render(<App />);

    expect(screen.getByTestId('scene-3d')).toBeInTheDocument();
    expect(screen.getByTestId('task-manager')).toBeInTheDocument();
    expect(screen.getByTestId('api-status')).toBeInTheDocument();
  });

  it('should have proper app structure', () => {
    const { container } = render(<App />);

    // getByRole('application') threw, because no element carries that
    // role. The shell is a .app root with an .app-header inside it.
    expect(container.querySelector('.app')).toBeInTheDocument();

    const header = screen.getByText(APP_NAME).closest('header');
    expect(header).toBeInTheDocument();
  });
});




