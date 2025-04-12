<template>
    <canvas id="canvas" ref="canvas"></canvas>
    <div id="map-input">
        <select v-model="selectedLand" @change="updateMapSelect">
            <option value="">Select Land</option>
            <option v-for="(land, landName) in mapData" :key="landName" :value="landName">
                {{ landName }}
            </option>
        </select>
        <select v-model="selectedMap">
            <option value="">Select Map</option>
            <option v-for="(mapInfo, mapId) in mapData[selectedLand]" :key="mapId" :value="mapId">
                {{ mapInfo.mapName }}
            </option>
        </select>
        <button @click="loadSelectedMap">Load Map</button>
        <label for="speed-input">Speed:</label>
        <input type="number" id="speed-input" v-model.number="speed" placeholder="Speed" min="1" max="10" step="1" />
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
        </div>
    </div>
</template>
<script>
import {
    createCanvasContexts,
    createImageLoader,
    createResourceModule,
    createMapLoaders,
} from "./resources.js";
import { setupGl } from "./gl.js";
const VWIDTH = 1366;
const VHEIGHT = 768;
// Initialize resources
const { cc1, cc2 } = createCanvasContexts();
const imageLoader = createImageLoader(cc1, cc2);
const syncLoaders = [];
const resourceModule = createResourceModule(syncLoaders, [
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
    set_show_foreground;

export default {
    name: "Map",
    data() {
        return {
            mapData: {},
            selectedLand: "",
            selectedMap: "",
            speed: 5,
            showTiles: true,
            showBackground: true,
            showForeground: true,
            backgroundLayers: [],
            foregroundLayers: [],
        };
    },
    methods: {
        updateMapSelect() {
            this.selectedMap = "";
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
            if (program_update) {
                set_speed(this.speed);
            }
        },
        updateDrawTiles() {
            if (program_update) {
                set_draw_tiles(this.showTiles);
            }
        },
        updateDrawBackground() {
            if (program_update) {
                set_draw_background(this.showBackground);
            }
        },
        updateDrawForeground() {
            if (program_update) {
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
                }
            }, 100);
        },
        updateLayerVisibility(type, index) {
            if (type === "background") {
                set_show_background(index, this.backgroundLayers[index].visible);
            } else if (type === "foreground") {
                set_show_foreground(index, this.foregroundLayers[index].visible);
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
        };

        Object.assign(globalThis, importObject);

        let requestAnimationFrameId = 0;
        let program_update = undefined;
        function update(time) {
            program_update(time * 1000);
            requestAnimationFrameId = requestAnimationFrame(update);
        }
        Promise.all(syncLoaders.map((loader) => loader.loader.load())) // load sync resources
            .then(() => import("lib/map_editor/map_editor.js")) // load moonbit generated js
            .then((m) => {
                program_update = m.update;
                load_map = m.load_map;
                set_speed = m.set_speed;
                set_draw_tiles = m.set_draw_tiles;
                set_draw_background = m.set_draw_background;
                set_draw_foreground = m.set_draw_foreground;
                is_loaded = m.is_loaded;
                get_background_count = m.get_background_count;
                get_foreground_count = m.get_foreground_count;
                set_show_background = m.set_show_background;
                set_show_foreground = m.set_show_foreground;

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

#canvas {
    padding: 0;
    margin: 0;
    display: block;
    border-style: solid;
    border-width: 1px;
}

#map-input {
    margin-top: 10px;
    display: flex;
    justify-content: center;
    align-items: center;
    flex-wrap: wrap;
}

#land-select,
#map-select,
#speed-input {
    margin-right: 10px;
    padding: 5px;
    width: 200px;
}

#load-map-btn {
    padding: 5px 10px;
    cursor: pointer;
    margin-right: 10px;
}

label {
    margin-right: 5px;
}

#toggle-tiles-checkbox {
    margin-right: 5px;
}

label[for="toggle-tiles-checkbox"] {
    display: flex;
    align-items: center;
    cursor: pointer;
}
</style>