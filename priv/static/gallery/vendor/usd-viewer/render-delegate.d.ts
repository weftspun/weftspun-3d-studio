/**
 * Modified from original source https://github.com/autodesk-forks/USD/blob/gh-pages/usd_for_web_demos/ThreeJsRenderDelegate.js
 */
import { BufferGeometry, Mesh } from 'three';
declare global {
    interface Window {
        envMap: any;
        usdRoot: any;
        driver: any;
    }
}
declare class TextureRegistry {
    private driver;
    basename: any;
    textures: any;
    loader: any;
    constructor(basename: string, driver: any);
    getTexture(filename: string): any;
}
declare class HydraMesh {
    _geometry: BufferGeometry;
    _id: any;
    _interface: any;
    _points: any;
    _normals: any;
    _colors: any;
    _uvs: any;
    _indices: any;
    _mesh: Mesh;
    constructor(id: any, hydraInterface: any, usdRoot: any);
    updateOrder(attribute: any, attributeName: any, dimension?: number): void;
    updateIndices(indices: any): void;
    setTransform(matrix: any): void;
    updateNormals(normals: any): void;
    setMaterial(materialId: any): void;
    setDisplayColor(data: any, interpolation: any): void;
    setUV(data: any, dimension: any, interpolation: any): void;
    updatePrimvar(name: any, data: any, dimension: any, interpolation: any): void;
    updatePoints(points: any): void;
    commit(): void;
}
declare class HydraMaterial {
    static usdPreviewToMeshPhysicalTextureMap: {
        diffuseColor: string;
        clearcoat: string;
        clearcoatRoughness: string;
        emissiveColor: string;
        occlusion: string;
        roughness: string;
        metallic: string;
        normal: string;
        opacity: string;
    };
    static channelMap: {
        r: import("three").PixelFormat;
        rgb: import("three").PixelFormat;
        rgba: import("three").PixelFormat;
    };
    static usdPreviewToMeshPhysicalMap: {
        clearcoat: string;
        clearcoatRoughness: string;
        diffuseColor: string;
        emissiveColor: string;
        ior: string;
        metallic: string;
        opacity: string;
        roughness: string;
    };
    _id: any;
    _nodes: any;
    _interface: any;
    _material: any;
    constructor(id: any, hydraInterface: any);
    updateNode(_networkId: any, path: any, parameters: any): void;
    assignTexture(mainMaterial: any, parameterName: any): void;
    assignProperty(mainMaterial: any, parameterName: any): void;
    updateFinished(_type: any, relationships: any): void;
}
export declare class RenderDelegateInterface {
    private usdRoot;
    meshes: any;
    registry: TextureRegistry;
    materials: any;
    driver: any;
    constructor(filename: any, Usd: any, usdRoot: any);
    createRPrim(_typeId: any, id: any): HydraMesh;
    createBPrim(_typeId: any, _id: any): void;
    createSPrim(typeId: any, id: any): HydraMaterial;
    CommitResources(): void;
}
export {};
