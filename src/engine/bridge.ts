// This file bridges the gap between React and the MoonBit WASM instance
// It handles loading the WASM, setting up the FFI, and providing control functions

// We are using Selene for rendering now, which manages its own WebGL/Canvas context
// So we don't need manual WebGL setup here, just passing the canvas element ID or reference

interface MoonBitModule {
    start_editor: (canvas_id: string) => void;
    load_map_ffi: (id: number) => void;
    set_view_options_ffi: (bg: boolean, tiles: boolean, objs: boolean) => void;
    export_scene_graph_ffi?: () => any;
    // Add other exported MoonBit functions here as needed
    [key: string]: any;
}

interface EditorAPI {
    loadMap: (id: number) => void;
    setViewOptions: (showBg: boolean, showTiles: boolean, showObjs: boolean) => void;
    getSceneGraph: () => any;
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
            print_i32: (x: number) => console.log(String(x)),
            print_f64: (x: number) => console.log(String(x)),
            print_char: (x: number) => console.log(String.fromCharCode(x)),
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
        m.start_editor(canvasId);
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
        cleanup: () => {
            // If there's a way to stop the engine, call it here
        }
    };
}


