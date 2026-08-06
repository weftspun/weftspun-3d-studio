import '@testing-library/jest-dom'
import { beforeAll, afterAll, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'

// Mock Three.js for tests
global.THREE = {
  Object3D: class MockObject3D {
    constructor() {
      this.children = []
      this.position = { x: 0, y: 0, z: 0 }
      this.rotation = { x: 0, y: 0, z: 0 }
      this.scale = { x: 1, y: 1, z: 1 }
    }
    add(child) {
      this.children.push(child)
    }
    remove(child) {
      const index = this.children.indexOf(child)
      if (index > -1) {
        this.children.splice(index, 1)
      }
    }
  },
  Vector3: class MockVector3 {
    constructor(x = 0, y = 0, z = 0) {
      this.x = x
      this.y = y
      this.z = z
    }
  },
  Vector2: class MockVector2 {
    constructor(x = 0, y = 0) {
      this.x = x
      this.y = y
    }
  },
  Raycaster: class MockRaycaster {
    constructor() {
      this.ray = { origin: new global.THREE.Vector3(), direction: new global.THREE.Vector3() }
    }
    setFromCamera() {}
    intersectObjects() { return [] }
  },
}

// Mock WebGL context
global.HTMLCanvasElement.prototype.getContext = function(contextId) {
  if (contextId === 'webgl' || contextId === 'webgl2') {
    return {
      getParameter: () => 'WebGL',
      getExtension: () => null,
      createShader: () => {},
      shaderSource: () => {},
      compileShader: () => {},
      createProgram: () => {},
      attachShader: () => {},
      linkProgram: () => {},
      useProgram: () => {},
      getShaderParameter: () => true,
      getProgramParameter: () => true,
    }
  }
  // A 2D context, because @iwsdk/xr-input draws its cursor texture at
  // module scope. jsdom gave null here, so importing the XR world
  // package threw before any test ran. See RFD 0023 on load-time work.
  if (contextId === '2d') {
    return {
      canvas: this,
      clearRect: () => {},
      fillRect: () => {},
      strokeRect: () => {},
      beginPath: () => {},
      closePath: () => {},
      arc: () => {},
      moveTo: () => {},
      lineTo: () => {},
      fill: () => {},
      stroke: () => {},
      save: () => {},
      restore: () => {},
      translate: () => {},
      rotate: () => {},
      scale: () => {},
      drawImage: () => {},
      putImageData: () => {},
      createRadialGradient: () => ({ addColorStop: () => {} }),
      createLinearGradient: () => ({ addColorStop: () => {} }),
      measureText: () => ({ width: 0 }),
      fillText: () => {},
      strokeText: () => {},
      getImageData: (x, y, w = 1, h = 1) => ({
        data: new Uint8ClampedArray(Math.max(1, w * h) * 4),
        width: w,
        height: h,
      }),
    }
  }
  return null
}

// Observers jsdom does not implement. The app shell measures its
// layout with both, and an undefined global throws during render.
if (typeof global.ResizeObserver === 'undefined') {
  global.ResizeObserver = class ResizeObserver {
    observe() {}
    unobserve() {}
    disconnect() {}
  }
}

if (typeof global.IntersectionObserver === 'undefined') {
  global.IntersectionObserver = class IntersectionObserver {
    constructor() {
      this.root = null
      this.rootMargin = ''
      this.thresholds = []
    }
    observe() {}
    unobserve() {}
    disconnect() {}
    takeRecords() {
      return []
    }
  }
}

// Mock URL.createObjectURL
global.URL.createObjectURL = (blob) => `blob:${blob.type}`
global.URL.revokeObjectURL = () => {}

// Mock OffscreenCanvas for ktx2-encoder
global.OffscreenCanvas = class OffscreenCanvas {
  constructor(width, height) {
    this.width = width
    this.height = height
  }
  getContext() {
    return {
      getImageData: () => ({ data: new Uint8ClampedArray(4), width: 1, height: 1 }),
      putImageData: () => {},
      drawImage: () => {},
    }
  }
}

// Mock LIBKTX for ktx library
global.LIBKTX = {
  KTX2File: class MockKTX2File {
    constructor() {
      this.valid = true
    }
    getWidth() { return 256 }
    getHeight() { return 256 }
    transcode() { return true }
    getImageData() { return new Uint8Array(256 * 256 * 4) }
  }
}

// Mock File API
global.File = class MockFile {
  constructor(content, filename, options = {}) {
    this.content = content
    this.name = filename
    this.type = options.type || 'application/octet-stream'
    this.size = content.length
  }
}

// Mock FileReader
global.FileReader = class MockFileReader {
  constructor() {
    this.onload = null
    this.onerror = null
  }
  readAsArrayBuffer(file) {
    setTimeout(() => {
      if (this.onload) {
        this.onload({ target: { result: new ArrayBuffer(file.size) } })
      }
    }, 0)
  }
  readAsDataURL(file) {
    setTimeout(() => {
      if (this.onload) {
        this.onload({ target: { result: `data:${file.type};base64,` } })
      }
    }, 0)
  }
}

// Cleanup after each test
afterEach(() => {
  cleanup()
})

// Mock console methods to reduce noise in tests
beforeAll(() => {
  global.console = {
    ...console,
    log: () => {},
    warn: () => {},
    error: () => {},
  }
})

afterAll(() => {
  // Restore console
  global.console = console
})