<template>
    <div id="map-editor">
        <div id="main-content">
            <canvas id="canvas" ref="canvas"></canvas>
            <div id="right-panel">
                <div id="visibility-controls">
                    <h3>Display Controls</h3>
                    <label for="toggle-tiles-checkbox">
                        <input type="checkbox" id="toggle-tiles-checkbox" v-model="showTiles" />
                        Show Tiles
                    </label>
                    <label for="toggle-background-checkbox">
                        <input type="checkbox" id="toggle-background-checkbox" v-model="showBackground" />
                        Show Background
                    </label>
                    <label for="toggle-foreground-checkbox">
                        <input type="checkbox" id="toggle-foreground-checkbox" v-model="showForeground" />
                        Show Foreground
                    </label>
                    <div id="layer-controls">
                        <h4>Backgrounds:</h4>
                        <div v-for="(layer, index) in backgroundLayers" :key="'bg-' + index">
                            <label>
                                <input type="checkbox" v-model="layer.visible"
                                    @change="updateLayerVisibility('background', index)" />
                                Background {{ index }}
                            </label>
                        </div>
                        <h4>Foregrounds:</h4>
                        <div v-for="(layer, index) in foregroundLayers" :key="'fg-' + index">
                            <label>
                                <input type="checkbox" v-model="layer.visible"
                                    @change="updateLayerVisibility('foreground', index)" />
                                Foreground {{ index }}
                            </label>
                        </div>
                        <h4>Portals:</h4>
                        <div id="portals-container">
                            <div v-for="(layer, index) in portals" :key="'portal-' + index" class="portal-item">
                                <label>
                                    <input type="checkbox" v-model="layer.visible"
                                        @change="updateLayerVisibility('portal', index)" />
                                    {{ layer.name }}
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div id="top-controls">
            <n-select v-model:value="selectedLand" filterable placeholder="Select Land" :options="landOptions"
                @update:value="updateMapSelect" style="width: 200px;" />
            <n-select v-model:value="selectedMap" filterable placeholder="Select Map" :options="computedMapOptions"
                style="width: 300px;" />
            <button @click="loadSelectedMap">Load Map</button>
            <label for="speed-input">Speed:</label>
            <input type="number" id="speed-input" v-model.number="speed" placeholder="Speed" min="1" max="10"
                step="1" />
            <div>
                <span>View Position: </span>
                <span>X: {{ viewPosition.x.toFixed(2) }}, Y: {{ viewPosition.y.toFixed(2) }}</span>
            </div>
        </div>
    </div>
</template>
<script>
import { NSelect } from 'naive-ui';
import { setupGl } from "./gl.js";
const VWIDTH = 1366;
const VHEIGHT = 768;

// Create canvas contexts for image loading
const createCanvasContexts = () => {
    const cc1 = document.createElement("canvas").getContext("2d", {
        willReadFrequently: true,
    });
    const cc2 = document.createElement("canvas").getContext("2d", {
        willReadFrequently: true,
    });
    return { cc1, cc2 };
};
// Create base image loader
export const createImageLoader = (cc1, cc2) => {
    return new PathImageLoader("https://maple-res.kkkiiox.work", cc1, cc2);
};

/**
 * @template T
 * @typedef {Object} NamedResourceLoader
 * @property {string} name
 * @property {T} loader
 */


/**
 * Create map loaders
 * 
 * @param {PathImageLoader} imageLoader
 * @returns {NamedResourceLoader<AsyncResourceLoader>[]}
 */
export const createMapLoaders = (imageLoader) => {
    const mapxLoader = new CompositeAsyncResourceLoader(
        {
            "Map0/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map0"),
            "Map1/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map1"),
            "Map2/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map2"),
        },
        imageLoader
    );

    const tileLoader = new AsyncResourceLoader(
        new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Tile"),
        imageLoader
    );

    const backgroundLoader = new AsyncResourceLoader(
        new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Back"),
        imageLoader
    );

    const objLoader = new AsyncResourceLoader(
        new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Obj"),
        imageLoader
    );

    const mapHelperLoader = new AsyncResourceLoader(
        new DirResourceLoader("https://maple-res.kkkiiox.work/Map/MapHelper.img"),
        imageLoader
    );

    const map001Loader = new CompositeAsyncResourceLoader(
        {
            "Back/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map001/Back"),
        },
        imageLoader
    );

    const mapPrettyLoader = new CompositeAsyncResourceLoader(
        {
            "Back/": new DirResourceLoader("https://maple-res.kkkiiox.work/MapPretty/Back"),
        },
        imageLoader
    );

    return [
        { name: "mapx", loader: mapxLoader },
        { name: "tile", loader: tileLoader },
        { name: "background", loader: backgroundLoader },
        { name: "obj", loader: objLoader },
        { name: "maphelper", loader: mapHelperLoader },
        { name: "map001", loader: map001Loader },
        { name: "map_pretty", loader: mapPrettyLoader },
    ]
};

/**
 * 
 * @param {NamedResourceLoader<AsyncResourceLoader>[]} asyncLoaders
 * @returns {Object}
 */
export function createResourceModule(asyncLoaders) {
    /** @type {Record<string, ResourceLoader>} */
    const loaderMap = {}
    /** @type {Record<string, AsyncResourceLoader>} */
    const asyncLoaderMap = {}
    for (const loader of asyncLoaders) {
        asyncLoaderMap[loader.name] = loader.loader;
    }
    return {
        get_async_loader: (name) => {
            const loader = asyncLoaderMap[name];
            if (!loader) {
                throw new Error(`Unknown resource loader: ${name}`);
            }
            return loader;
        },
        load_desc_async: (loader, path) => loader.loadDescAsync(path),
        load_desc: (loader, path) => loader.loadDesc(path),
        as_jsonstring: (data) => JSON.stringify(data),
        load_image: (loader, bid) => loader.loadImage(bid),
        get_image_loader: (loader) => loader.bmpLoader,
        is_ready: (pollable) => pollable.ready,
        get_result: (pollable) => pollable.value,
    };
};

const { cc1, cc2 } = createCanvasContexts();
const imageLoader = createImageLoader(cc1, cc2);
const resourceModule = createResourceModule([
    ...createMapLoaders(imageLoader),
]);

let set_speed,
    set_draw_tiles,
    set_draw_background,
    set_draw_foreground,
    load_map,
    is_loaded,
    get_background_count,
    get_foreground_count,
    set_show_background,
    set_show_foreground,
    get_portal_names,
    set_show_portal;

export default {
    name: "Map",
    components: {
        NSelect,
    },
    data() {
        return {
            mapData: {},
            selectedLand: null,
            selectedMap: null,
            speed: 5,
            showTiles: true,
            showBackground: true,
            showForeground: true,
            showPortal: true,
            backgroundLayers: [],
            foregroundLayers: [],
            portals: [],
            viewPosition: { x: 0, y: 0 },
            program_update: undefined,
            landOptions: [],
        };
    },
    computed: {
        computedMapOptions() {
            if (!this.selectedLand || !this.mapData[this.selectedLand]) {
                return [];
            }
            return Object.entries(this.mapData[this.selectedLand]).map(([mapId, mapInfo]) => ({
                label: `${mapId} - ${mapInfo.mapName}`,
                value: mapId,
            }));
        }
    },
    watch: {
        selectedLand() {
            this.selectedMap = null;
        }
    },
    methods: {
        updateMapSelect() {
            this.selectedMap = null;
        },
        loadSelectedMap() {
            const mapId = parseInt(this.selectedMap);
            if (!isNaN(mapId)) {
                load_map(mapId);
                this.updateLayerControls();
            } else {
                console.error("Invalid Map ID");
            }
        },
        updateSpeed() {
            if (this.program_update) {
                set_speed(this.speed);
            }
        },
        updateDrawTiles() {
            if (this.program_update) {
                set_draw_tiles(this.showTiles);
            }
        },
        updateDrawBackground() {
            if (this.program_update) {
                set_draw_background(this.showBackground);
            }
        },
        updateDrawForeground() {
            if (this.program_update) {
                set_draw_foreground(this.showForeground);
            }
        },
        updateLayerControls() {
            // Wait for the map to load
            const checkLoaded = setInterval(() => {
                if (is_loaded()) {
                    clearInterval(checkLoaded);
                    const bgCount = get_background_count();
                    const fgCount = get_foreground_count();

                    this.backgroundLayers = Array(bgCount)
                        .fill()
                        .map((_, i) => ({ visible: true }));
                    this.foregroundLayers = Array(fgCount)
                        .fill()
                        .map((_, i) => ({ visible: true }));
                    const portalNames = get_portal_names();
                    this.portals = portalNames.map((name, id) => ({
                        visible: true,
                        name,
                        id,
                    }));
                }
            }, 100);
        },
        updateLayerVisibility(type, index) {
            if (type === "background") {
                set_show_background(index, this.backgroundLayers[index].visible);
            } else if (type === "foreground") {
                set_show_foreground(index, this.foregroundLayers[index].visible);
            } else if (type === "portal") {
                set_show_portal(this.portals[index].name, this.portals[index].visible);
            }
        },
    },
    watch: {
        speed() {
            this.updateSpeed();
        },
        showTiles() {
            this.updateDrawTiles();
        },
        showBackground() {
            this.updateDrawBackground();
        },
        showForeground() {
            this.updateDrawForeground();
        },
    },
    mounted() {
        const gl = this.$refs.canvas.getContext("webgl2", {});
        gl.canvas.width = VWIDTH;
        gl.canvas.height = VHEIGHT;
        const glModule = setupGl(gl);
        const importObject = {
            gl: glModule,
            resource: resourceModule,
            bitmap: {
                width: (bmp) => bmp.w,
                height: (bmp) => bmp.h,
                loading: (bmp) => bmp.loading === true,
                load: (bmp) => bmp,
                new_pending: () => ({ loading: true }),
            },
            log: {
                debug: (msg) => console.debug(msg),
                info: (msg) => console.info(msg),
                warn: (msg) => console.warn(msg),
                error: (msg) => console.error(msg),
            },
            map_editor: {
                on_view_position_change: (x, y) => {
                    this.viewPosition = { x, y };
                },
            },
            "async": {
                spawn_background: (f) => {
                    setTimeout(f, 0);
                },
            },
            spectest: {
                print_i32: (x) => console.log(String(x)),
                print_f64: (x) => console.log(String(x)),
            },
            "moonbit:ffi": {
                "make_closure": (funcref, closure) => funcref.bind(null, closure)
            }
        };

        Object.assign(globalThis, importObject);

        let requestAnimationFrameId = 0;
        const update = (time) => {
            this.program_update(time * 1000);
            requestAnimationFrameId = requestAnimationFrame(update);
        }
        import("lib/map_editor/map_editor.js") // load moonbit generated js
            .then((m) => {
                this.program_update = m.update;
                load_map = m.load_map;
                set_speed = m.set_speed;
                set_draw_tiles = m.set_draw_tiles;
                set_draw_background = m.set_draw_background;
                set_draw_foreground = m.set_draw_foreground;
                is_loaded = m.is_loaded;
                get_background_count = m.get_background_count;
                get_foreground_count = m.get_foreground_count;
                get_portal_names = m.get_portal_names;
                set_show_background = m.set_show_background;
                set_show_foreground = m.set_show_foreground;
                set_show_portal = m.set_show_portal;

                const onkeydown = m.onkeydown;
                const onkeyup = m.onkeyup;
                window.addEventListener("keydown", (e) => {
                    onkeydown(e.code);
                });
                window.addEventListener("keyup", (e) => {
                    onkeyup(e.code);
                });

                requestAnimationFrameId = requestAnimationFrame(update);
            });
        // Load map data
        fetch("https://maple-res.kkkiiox.work/String/nx.json")
            .then((res) => res.json())
            .then((json) => {
                this.mapData = Object.entries(json["Map.img"]).reduce(
                    (acc, [landName, land]) => {
                        acc[landName] = Object.entries(land).reduce(
                            (mapAcc, [mapId, map]) => {
                                const { mapName, mapDesc, streetName } = map;
                                mapAcc[mapId] = { mapName, mapDesc, streetName };
                                return mapAcc;
                            },
                            {}
                        );
                        return acc;
                    },
                    {}
                );
                this.landOptions = Object.keys(this.mapData).map(landName => ({
                    label: landName,
                    value: landName,
                }));
            });
    },
};
</script>
<style scoped>
html {
    width: 100%;
}

body {
    background-color: white;
    margin: 0 0;
    padding: 0;
    font-family: "Droid Sans", "sans-serif";
}

div,
p {
    margin: 0;
    padding: 0;
}

#map-editor {
    display: flex;
    flex-direction: column;
    height: 100vh;
}

#main-content {
    display: flex;
    flex: 1;
    min-height: 0;
}

#canvas {
    padding: 0;
    margin: 0;
    display: block;
    border-style: solid;
    border-width: 1px;
    flex-shrink: 0;
}

#right-panel {
    width: 400px;
    padding: 20px;
    border-left: 1px solid #ccc;
    background-color: #f5f5f5;
    overflow-y: auto;
}

#visibility-controls h3 {
    margin-top: 0;
    margin-bottom: 15px;
    color: #333;
}

#visibility-controls label {
    display: flex;
    align-items: center;
    margin-bottom: 8px;
    cursor: pointer;
}

#visibility-controls input[type="checkbox"] {
    margin-right: 8px;
}

#layer-controls {
    margin-top: 20px;
}

#layer-controls h4 {
    margin-top: 15px;
    margin-bottom: 10px;
    color: #555;
    font-size: 14px;
}

#layer-controls label {
    margin-left: 10px;
    font-size: 13px;
}

#portals-container {
    max-height: 200px;
    overflow-y: auto;
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 4px;
}

.portal-item {
    margin-bottom: 4px;
}

.portal-item label {
    margin-left: 0;
    font-size: 12px;
    display: flex;
    align-items: center;
}

.portal-item input[type="checkbox"] {
    margin-right: 4px;
    transform: scale(0.8);
}

#top-controls {
    padding: 10px;
    display: flex;
    justify-content: center;
    align-items: center;
    flex-wrap: wrap;
    gap: 10px;
    border-bottom: 1px solid #ccc;
    background-color: #f9f9f9;
}

#top-controls select,
#top-controls input {
    padding: 5px;
}

#top-controls select {
    width: 200px;
}

#top-controls button {
    padding: 8px 16px;
    font-size: 14px;
    cursor: pointer;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 4px;
    transition: background-color 0.3s;
}

#top-controls button:hover {
    background-color: #0056b3;
}

#top-controls button:disabled {
    background-color: #6c757d;
    cursor: not-allowed;
}

#speed-input {
    width: 80px;
}

label {
    margin-right: 5px;
}
</style>