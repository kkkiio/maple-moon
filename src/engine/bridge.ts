// This file bridges the gap between React and the MoonBit WASM instance
// It handles loading the WASM, setting up the FFI, and providing control functions

// We are using Selene for rendering now, which manages its own WebGL/Canvas context
// So we don't need manual WebGL setup here, just passing the canvas element ID or reference

export interface MouseInfo {
    screen_x: number;
    screen_y: number;
    world_x: number;
    world_y: number;
}

// Types for the Editor Scene Graph
export type EditorBackground = {
    id: number;
    type_: string;
    bS: string;
    no: number;
    x: number;
    y: number;
    rx: number;
    ry: number;
    type_val: number;
    front: boolean;
};

export type EditorTile = {
    x: number;
    y: number;
    z: number;
    _off: number[];
};

export type EditorObj = {
    x: number;
    y: number;
    z: number;
    _off: number[];
    flip: boolean;
};

export type EditorLayer = {
    index: number;
    tiles: EditorTile[];
    objects: EditorObj[];
};

export type EditorSceneGraph = {
    backgrounds: EditorBackground[];
    layers: EditorLayer[];
};

export interface EditorStatus {
    loading: boolean;
    error_msg?: string;
    map_id: number;
    map_name: string;
    cam_x: number;
    cam_y: number;
    zoom: number;
    bg_visible: boolean;
    bg_back_visible: boolean;
    bg_fore_visible: boolean;
    bg_debug_index?: number;
    bg_total_layers: number;
    fps: number;
}

export type EditorTileObjLayerVisibility = {
    layer: number;
    tiles_visible: boolean;
    objs_visible: boolean;
};

export type EditorTileObjVisibilityState = {
    tiles_visible: boolean;
    objs_visible: boolean;
    layers: EditorTileObjLayerVisibility[];
    tile_items: boolean[][];
    obj_items: boolean[][];
};

interface MoonBitModule {
    start_editor: (canvas_id: string) => void;
    load_map_ffi: (id: number) => void;
    set_background_visible_ffi?: (visible: boolean) => void;
    set_layer_visibility_ffi?: (layer: number, tilesVisible: boolean, objsVisible: boolean) => void;
    set_tile_visibility_ffi?: (layer: number, resourceIndex: number, visible: boolean) => void;
    set_obj_visibility_ffi?: (layer: number, resourceIndex: number, visible: boolean) => void;
    set_tiles_scope_visibility_ffi?: (visible: boolean) => void;
    set_objs_scope_visibility_ffi?: (visible: boolean) => void;
    reset_tile_obj_visibility_ffi?: () => void;
    export_scene_graph_ffi?: () => any;
    export_mouse_info_ffi?: () => MouseInfo;
    export_editor_status_ffi?: () => EditorStatus;
    export_tile_obj_visibility_state_ffi?: () => EditorTileObjVisibilityState;
    // Add other exported MoonBit functions here as needed
    [key: string]: any;
}



export interface EditorAPI {
    loadMap: (id: number) => void;
    setBackgroundVisible: (visible: boolean) => void;
    setLayerVisibility: (layer: number, tilesVisible: boolean, objsVisible: boolean) => void;
    setTileVisibility: (layer: number, resourceIndex: number, visible: boolean) => void;
    setObjVisibility: (layer: number, resourceIndex: number, visible: boolean) => void;
    setTilesScopeVisibility: (visible: boolean) => void;
    setObjsScopeVisibility: (visible: boolean) => void;
    resetTileObjVisibility: () => void;
    getSceneGraph: () => any;
    getMouseInfo: () => MouseInfo | null;
    getStatus: () => EditorStatus | null;
    getTileObjVisibilityState: () => EditorTileObjVisibilityState | null;
    cleanup: () => void;
}

// Prevent duplicate initialization (React StrictMode calls useEffect twice)
let cachedApi: EditorAPI | null = null;
let initPromise: Promise<EditorAPI> | null = null;

export async function initMoonBitEngine(
    canvasId: string,
    onLog: (msg: string, type: 'info' | 'warn' | 'error') => void
): Promise<EditorAPI> {
    // Return cached API if already initialized
    if (cachedApi) {
        console.warn("MoonBit Engine already initialized, returning cached API");
        return cachedApi;
    }

    // Return existing promise if initialization is in progress
    if (initPromise) {
        console.warn("MoonBit Engine initialization in progress, waiting...");
        return initPromise;
    }

    // Start initialization and cache the promise
    initPromise = (async () => {
        // Import object for WASM
        const importObject = {
            // Basic environment expected by MoonBit/Selene
            spectest: {
                print_i32: (x: number) => { }, // console.log(String(x)),
                print_f64: (x: number) => { }, // console.log(String(x)),
                print_char: (x: number) => { }, // console.log(String.fromCharCode(x)),
            },
            "moonbit:ffi": {
                "make_closure": (funcref: Function, closure: any) => funcref.bind(null, closure)
            }
        };

        Object.assign(globalThis, importObject);

        // Load the MoonBit module
        const m = await import("../../target/js/release/build/mapeditor/mapeditor.js");

        // Start the editor engine
        if (m.start_editor) {
            m.start_editor();
        } else {
            console.error("start_editor function not found in MoonBit module");
        }

        return {
            loadMap: (id: number) => {
                if (m.load_map_ffi) m.load_map_ffi(id);
            },
            setBackgroundVisible: (visible: boolean) => {
                if (m.set_background_visible_ffi) m.set_background_visible_ffi(visible);
            },
            setLayerVisibility: (layer: number, tilesVisible: boolean, objsVisible: boolean) => {
                if (m.set_layer_visibility_ffi) m.set_layer_visibility_ffi(layer, tilesVisible, objsVisible);
            },
            setTileVisibility: (layer: number, resourceIndex: number, visible: boolean) => {
                if (m.set_tile_visibility_ffi) m.set_tile_visibility_ffi(layer, resourceIndex, visible);
            },
            setObjVisibility: (layer: number, resourceIndex: number, visible: boolean) => {
                if (m.set_obj_visibility_ffi) m.set_obj_visibility_ffi(layer, resourceIndex, visible);
            },
            setTilesScopeVisibility: (visible: boolean) => {
                if (m.set_tiles_scope_visibility_ffi) m.set_tiles_scope_visibility_ffi(visible);
            },
            setObjsScopeVisibility: (visible: boolean) => {
                if (m.set_objs_scope_visibility_ffi) m.set_objs_scope_visibility_ffi(visible);
            },
            resetTileObjVisibility: () => {
                if (m.reset_tile_obj_visibility_ffi) m.reset_tile_obj_visibility_ffi();
            },
            getSceneGraph: () => {
                if (m.export_scene_graph_ffi) {
                    return m.export_scene_graph_ffi();
                }
                return null;
            },
            getMouseInfo: () => {
                if (m.export_mouse_info_ffi) {
                    return m.export_mouse_info_ffi();
                }
                return null;
            },
            getStatus: () => {
                if (m.export_editor_status_ffi) {
                    return m.export_editor_status_ffi();
                }
                return null;
            },
            getTileObjVisibilityState: () => {
                if (m.export_tile_obj_visibility_state_ffi) {
                    return m.export_tile_obj_visibility_state_ffi();
                }
                return null;
            },
            cleanup: () => {
                // If there's a way to stop the engine, call it here
            }
        };
    })();

    // Cache the result and return
    cachedApi = await initPromise;
    return cachedApi;
}
