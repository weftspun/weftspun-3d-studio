import { LitElement, PropertyValues } from 'lit';
/**
 * @element usd-viewer
 */
export declare class USDViewer extends LitElement {
    #private;
    src: string;
    alt: string;
    controls: boolean;
    fileName: boolean;
    autoRotate: boolean;
    autoRotateSpeed: number;
    minDistance: number;
    maxDistance: number;
    zoom: number;
    private error;
    static styles: CSSStyleSheet[];
    render(): import("lit-html").TemplateResult<1>;
    firstUpdated(props: PropertyValues<this>): Promise<void>;
    updated(props: PropertyValues<this>): Promise<void>;
}
