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
    tiles_visible: boolean;
    objs_visible: boolean;
    bg_back_visible: boolean;
    bg_fore_visible: boolean;
    bg_debug_index?: number;
    bg_total_layers: number;
    fps: number;
}

interface MoonBitModule {
    start_editor: (canvas_id: string) => void;
    load_map_ffi: (id: number) => void;
    set_view_options_ffi: (bg: boolean, tiles: boolean, objs: boolean) => void;
    export_scene_graph_ffi?: () => any;
    export_mouse_info_ffi?: () => MouseInfo;
    export_editor_status_ffi?: () => EditorStatus;
    // Add other exported MoonBit functions here as needed
    [key: string]: any;
}



export interface EditorAPI {
    loadMap: (id: number) => void;
    setViewOptions: (showBg: boolean, showTiles: boolean, showObjs: boolean) => void;
    getSceneGraph: () => any;
    getMouseInfo: () => MouseInfo | null;
    getStatus: () => EditorStatus | null;
    cleanup: () => void;
}

export async function initMoonBitEngine(
    canvasId: string,
    onLog: (msg: string, type: 'info' | 'warn' | 'error') => void
): Promise<EditorAPI> {

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
        setViewOptions: (showBg: boolean, showTiles: boolean, showObjs: boolean) => {
            if (m.set_view_options_ffi) m.set_view_options_ffi(showBg, showTiles, showObjs);
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
        cleanup: () => {
            // If there's a way to stop the engine, call it here
        }
    };
}
