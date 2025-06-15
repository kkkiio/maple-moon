<template>
    <div id="app">
        <Login v-if="phase === 'login' && game" :game="game" @logined="phase = 'game'" />
        <div :style="{
            position: 'relative',
            display: 'flex',
            justifyContent: 'flex-start',
            alignItems: 'flex-start',
            padding: '0px',
            visibility: phase === 'login' ? 'hidden' : 'visible'
        }">
            <canvas ref="canvas"
                style="padding: 0; margin: 0; display: block; border-style: solid; border-width: 1px;"></canvas>
            <GameUI v-if="game" :game="game" style="position: absolute; top: 10px; right: 10px;"></GameUI>
        </div>
        <div ref="tmpd" style="position: absolute; visibility: hidden; height: auto; width: auto;"></div>
    </div>
</template>

<script>
import { setupGl } from "./gl.js";
import {
    AsyncResourceLoader,
    BidImageLoader,
    CompositeAsyncResourceLoader,
    CompositeResourceLoader,
    DirResourceLoader,
    FileResourceLoader,
    PathImageLoader,
    ResourceLoader
} from "./resource_loader.js";
import GameUI from "./UI.vue";
import Login from "./Login.vue";

const VWIDTH = 1366;
const VHEIGHT = 768;

class Socket {
    constructor(path) {
        console.log("connect server", path);
        // keep the same protocol as the current page
        const protocol = location.protocol === 'https:' ? 'wss://' : 'ws://';
        this.ws = new WebSocket(protocol + location.host + path, "binary");
        this.ws.binaryType = "arraybuffer";
        this.pendingData = [];
        this.ws.addEventListener("open", (event) => {
            console.info("connect server success", event);
        });
        this.ws.addEventListener("message", (event) => {
            this.pendingData.push(new Uint8Array(event.data));
        });
        this.ws.addEventListener("error", (event) => {
            console.error("connect server error", event);
        });
        this.ws.addEventListener("close", (event) => {
            console.info("connect server close", event);
        });
    }
    close() {
        this.ws.close();
    }
    getReadyState() {
        return this.ws.readyState;
    }
    read() {
        if (this.pendingData.length > 0) {
            return this.pendingData.shift();
        }
        return new Uint8Array();
    }
    write(data) {
        this.ws.send(data);
    }
}

class TextBitmapGenerator {
    constructor(textCtx, tmpDom) {
        this.textCtx = textCtx;
        this.testDom = tmpDom;
    }
    // TODO: allow individual font style
    createImage(textHtml, fontSize, fontName, color, textAlign, maxWidth) {
        const html = `<p style="font-size: ${fontSize}px; font-family: ${fontName}; color: ${color}; text-align: ${textAlign};">${textHtml}</p>`;
        const tmpImg = document.createElement("img");
        const [width, height] = this.calculateTextSize(html, maxWidth);
        const bmp = {
            loading: true,
            w: width,
            h: height,
        };
        tmpImg.onload = () => {
            this.textCtx.canvas.width = tmpImg.width;
            this.textCtx.canvas.height = tmpImg.height;
            this.textCtx.clearRect(0, 0, this.textCtx.canvas.width, this.textCtx.canvas.height);
            this.textCtx.drawImage(tmpImg, 0, 0);
            const dataUrl = this.textCtx.canvas.toDataURL();
            // console.debug(dataUrl);
            const targetImg = document.createElement("img");
            bmp.data = targetImg;
            targetImg.onload = () => {
                bmp.loading = false;
            };
            targetImg.src = dataUrl;
        };
        tmpImg.onerror = (evt) => {
            console.error("createImage error", evt, tmpImg.src);
        };
        tmpImg.src =
            "data:image/svg+xml," +
            encodeURIComponent(
                `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><foreignObject width="100%" height="100%"><div xmlns="http://www.w3.org/1999/xhtml"><style>p{margin:0}</style>${html}</div></foreignObject></svg>`
            );
        return bmp;
    }
    calculateTextSize(html, maxWidth) {
        if (maxWidth) {
            this.testDom.style.maxWidth = `${maxWidth}px`;
        } else {
            this.testDom.style.maxWidth = "unset";
        }
        this.testDom.innerHTML = html;
        return [this.testDom.clientWidth + 1, this.testDom.clientHeight + 1];
    }
}

export default {
    name: "App",
    components: {
        GameUI,
        Login,
    },
    data() {
        return {
            phase: 'login', // default phase
            game: null,
        };
    },
    mounted() {
        const canvas = this.$refs.canvas;
        canvas.width = VWIDTH;
        canvas.height = VHEIGHT;

        // Disable context menu on canvas
        canvas.addEventListener("contextmenu", (e) => e.preventDefault());

        const gl = canvas.getContext("webgl2", {});
        if (!gl) {
            throw new Error("WebGL not supported");
        }

        const cc1 = document.createElement("canvas").getContext("2d", {
            willReadFrequently: true,
        });
        const cc2 = document.createElement("canvas").getContext("2d", {
            willReadFrequently: true,
        });

        const imageLoader = new PathImageLoader("https://maple-res.kkkiiox.work", cc1, cc2);
        const uiWindow2Loader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/UI/UIWindow2.img"),
            imageLoader
        );
        const uiWindow4Loader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/UI/UIWindow4.img"),
            imageLoader
        );

        const mapxLoader = new CompositeAsyncResourceLoader(
            {
                "Map0/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map0"),
                "Map1/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map1"),
                "Map2/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map2"),
                "Map3/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map3"),
                "Map4/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map4"),
                "Map5/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map5"),
                "Map6/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map6"),
                "Map7/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map7"),
                "Map8/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map8"),
                "Map9/": new DirResourceLoader("https://maple-res.kkkiiox.work/Map/Map9"),
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

        const characterLoader = new CompositeAsyncResourceLoader(
            {
                "Pants/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Pants"),
                "Weapon/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Weapon"),
                "Coat/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Coat"),
                "Cap/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Cap"),
                "Longcoat/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Longcoat"),
                "Shield/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Shield"),
                "Shoes/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Shoes"),
                "Glove/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Glove"),
                "Accessory/": new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Accessory"),
            },
            imageLoader
        );

        const bodyLoader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Body"),
            imageLoader
        );
        const hairLoader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Hair"),
            imageLoader
        );
        const faceLoader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Face"),
            imageLoader
        );
        const afterImageLoader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/Character/Afterimage"),
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

        const etcLoader = new AsyncResourceLoader(new DirResourceLoader("https://maple-res.kkkiiox.work/Etc"), imageLoader);

        const itemLoader = new CompositeAsyncResourceLoader(
            {
                "Consume/": new DirResourceLoader("https://maple-res.kkkiiox.work/Item/Consume"),
                "Cash/": new DirResourceLoader("https://maple-res.kkkiiox.work/Item/Cash"),
                "Etc/": new DirResourceLoader("https://maple-res.kkkiiox.work/Item/Etc"),
                "Install/": new DirResourceLoader("https://maple-res.kkkiiox.work/Item/Install"),
                "Pet/": new DirResourceLoader("https://maple-res.kkkiiox.work/Item/Pet"),
            },
            imageLoader
        );
        const specialItemLoader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/Item/Special"),
            imageLoader
        );

        const mobLoader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/Mob"),
            imageLoader
        );

        const effectLoader = new CompositeAsyncResourceLoader(
            {
                "BasicEff.img/": new DirResourceLoader("https://maple-res.kkkiiox.work/Effect/BasicEff.img"),
                "CharacterEff.img/": new DirResourceLoader("https://maple-res.kkkiiox.work/Effect/CharacterEff.img"),
            },
            imageLoader
        );

        const skillLoader = new AsyncResourceLoader(
            new DirResourceLoader("https://maple-res.kkkiiox.work/Skill"),
            imageLoader
        );
        const mapLatestLoader = new CompositeAsyncResourceLoader(
            {
                "Obj/login.img/": new DirResourceLoader("https://maple-res.kkkiiox.work/MapLatest/Obj/login.img"),
            },
            imageLoader
        );

        const textBitmapGenerator = new TextBitmapGenerator(cc1, this.$refs.tmpd);

        let requestAnimationFrameId = null;
        let halt = false;
        let game_update = null;
        const glModule = setupGl(gl);

        const importObject = {
            gl: glModule,
            text: {
                create_image: textBitmapGenerator.createImage.bind(textBitmapGenerator),
            },
            resource: {
                get_async_loader: (name) => {
                    switch (name) {
                        case "mapx":
                            return mapxLoader;
                        case "maphelper":
                            return mapHelperLoader;
                        case "tile":
                            return tileLoader;
                        case "character":
                            return characterLoader;
                        case "body":
                            return bodyLoader;
                        case "hair":
                            return hairLoader;
                        case "face":
                            return faceLoader;
                        case "afterimage":
                            return afterImageLoader;
                        case "background":
                            return backgroundLoader;
                        case "obj":
                            return objLoader;
                        case "UI/UIWindow2.img":
                            return uiWindow2Loader;
                        case "UI/UIWindow4.img":
                            return uiWindow4Loader;
                        case "mob":
                            return mobLoader;
                        case "item":
                            return itemLoader;
                        case "special_item":
                            return specialItemLoader;
                        case "effect":
                            return effectLoader;
                        case "map001":
                            return map001Loader;
                        case "map_pretty":
                            return mapPrettyLoader;
                        case "skill":
                            return skillLoader;
                        case "MapLatest":
                            return mapLatestLoader;
                        case "Etc":
                            return etcLoader;
                        default:
                            throw new Error(`Unknown resource loader: ${name}`);
                    }
                },
                load_desc_async: (loader, path) => loader.load_desc_async(path),
                load_desc: (loader, path) => loader.load_desc(path),
                as_jsonstring: (data) => JSON.stringify(data),
                load_image: (loader, bid) => loader.loadImage(bid),
                get_image_loader: (loader) => loader.bmpLoader,
                is_ready: (pollable) => pollable.ready,
                get_result: (pollable) => pollable.value,
                new_dir_resource_loader: (url) => new DirResourceLoader(url),
                new_async_resource_loader: (loader) => new AsyncResourceLoader(loader, imageLoader),
                new_composite_async_resource_loader: (prefixedLoaders) => {
                    const loaderMap = {}
                    for (const elem of prefixedLoaders) {
                        loaderMap[elem.prefix] = elem.loader;
                    }
                    return new CompositeAsyncResourceLoader(loaderMap, imageLoader);
                },
                make_file_resource_loader: async (url) => {
                    const loader = new FileResourceLoader(url);
                    await loader.load();
                    return loader;
                },
                new_bid_image_loader: (url) => new BidImageLoader(url),
                get_path_image_loader: () => imageLoader,
            },
            bitmap: {
                width: (bmp) => bmp.w,
                height: (bmp) => bmp.h,
                loading: (bmp) => bmp.loading === true,
                load: (bmp) => bmp,
                new_pending: () => ({ loading: true }),
            },
            time: {
                now_micro: () => performance.now() * 1000,
            },
            socket: {
                open: (path) => new Socket(path),
                close: (socket) => {
                    socket.close();
                },
                get_ready_state: (socket) => socket.getReadyState(),
            },
            log: {
                debug: (msg) => console.debug(msg),
                info: (msg) => console.info(msg),
                warn: (msg) => console.warn(msg),
                error: (msg) => console.error(msg),
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

        function update(time = 0) {
            game_update(time * 1000);
            if (!halt) {
                requestAnimationFrameId = requestAnimationFrame(update);
            }
        }

        Object.assign(globalThis, importObject);
        import("lib/lib.js")
            .then((m) => {
                game_update = m.game_update;
                const onmousemove = m.onmousemove;
                const onmousedown = m.onmousedown;
                const onmouseup = m.onmouseup;
                const onkeydown = m.onkeydown;
                const onkeyup = m.onkeyup;

                window.addEventListener("keydown", (e) => {
                    onkeydown(e.code);
                });
                window.addEventListener("keyup", (e) => {
                    onkeyup(e.code);
                });
                window.addEventListener("mousemove", (evt) => {
                    const rect = canvas.getBoundingClientRect();
                    const x = evt.clientX - rect.left;
                    const y = evt.clientY - rect.top;
                    onmousemove(x, y);
                });
                window.addEventListener("mousedown", (_) => {
                    onmousedown();
                });
                window.addEventListener("mouseup", (_) => {
                    onmouseup();
                });

                const game = m.game_start();
                this.game = game;
                requestAnimationFrameId = requestAnimationFrame(update);
            });
    },
};
</script>

<style>
@import "tailwindcss";

/* 禁用页面滚动 */
html,
body {
    overflow: hidden;
    height: 100%;
    margin: 0;
    padding: 0;
}

#app {
    height: 100vh;
    overflow: hidden;
}
</style>