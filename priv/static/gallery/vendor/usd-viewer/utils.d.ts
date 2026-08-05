declare global {
    interface Window {
        getUsdModule: any;
    }
}
export declare function loadWasmUSD(dir?: string): Promise<any>;
export declare function fetchArrayBuffer(src: string): Promise<Uint8Array>;
export declare function includeScript(url: string): Promise<unknown>;
