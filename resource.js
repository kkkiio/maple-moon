export class LazyBmpLoader {
    /**
     * 
     * @param {string} imagesPath 
     */
    constructor(imagesPath) {
        this.imagesPath = imagesPath;
        this.bitmaps = {};
    }
    loadImage(bid) {
        let bmp = this.bitmaps[bid];
        if (bmp) {
            return bmp;
        }
        const img = new Image();
        const bmpPath = `${this.imagesPath}/${bid}.png`;
        bmp = {
            data: img,
            loading: true,
        };
        this.bitmaps[bid] = bmp;
        img.onload = () => {
            bmp.w = img.width;
            bmp.h = img.height;
            bmp.loading = false;
        };
        img.src = bmpPath;
        return bmp;
    }
}

async function fetchImageByUrl(url) {
    const img = new Image();
    img.crossOrigin = "anonymous";
    return new Promise((resolve, reject) => {
        img.onload = () => {
            resolve(img);
        };
        img.onerror = (e) => {
            reject(e);
        };
        img.src = url;
    });
}

/**
 * @typedef {Object} LazyImage
 * @property {Image} data
 * @property {boolean} loading
 * @property {number} w
 * @property {number} h
 */

export class BidImageLoader {
    /**
     * 
     * @param {string} imagesUrl 
     */
    constructor(imagesUrl) {
        this.imagesUrl = imagesUrl;
        /**
         * @type {Record<string, LazyImage>}
         */
        this.images = {};
    }
    /**
     * 
     * @param {string} bid 
     * @returns {LazyImage}
     */
    loadImage(bid) {
        let res = this.images[bid];
        if (res) {
            return res;
        }
        const bmpPath = `${this.imagesUrl}/${bid}.png`;
        res = {
            loading: true,
        };
        fetchImageByUrl(bmpPath).then(img => {
            res.w = img.width;
            res.h = img.height;
            res.data = img;
            res.loading = false;
        });
        this.images[bid] = res;
        return res;
    }
}

class Singleflight {
    constructor() {
        /**
         * @type {Map<string, Promise<any>>}
         */
        this.flights = new Map();
    }

    /**
     * @template T
     * @param {string} key 
     * @param {() => Promise<T>} fn 
     * @returns {Promise<T>}
     */
    async run(key, fn) {
        const existing = this.flights.get(key);
        if (existing) {
            return existing;
        }

        const promise = fn().finally(() => {
            this.flights.delete(key);
        });

        this.flights.set(key, promise);
        return promise;
    }
}

export class PathImageLoader {
    /**
     * 
     * @param {string} rootPath 
     * @param {CanvasRenderingContext2D} canvasContext 
     */
    constructor(rootPath, canvasContext) {
        this.rootPath = rootPath;
        this.canvasContext = canvasContext;
        /**
         * @type {Record<string, LazyImage>}
         */
        this.cache = {};
        this.singleflight = new Singleflight();
    }
    /**
     * 
     * @param {string} path ${image}[#${bid}]
     * @returns {LazyImage}
     */
    loadImageByPath(path) {
        let res = this.cache[path];
        if (res) {
            return res;
        }
        const [imagePath, spriteSheetRef] = path.split("#");
        res = {
            loading: true,
        };
        this.cache[path] = res;
        if (spriteSheetRef) {
            this.loadSpritesheet(imagePath).then(images => {
                const data = images[spriteSheetRef];
                res.data = data;
                res.w = data.width;
                res.h = data.height;
                res.loading = false;
            });
        } else {
            fetchImageByUrl(joinPath(this.rootPath, imagePath)).then(img => {
                res.data = img;
                res.w = img.width;
                res.h = img.height;
                res.loading = false;
            });
        }
        return res;
    }
    async loadSpritesheet(path) {
        return this.singleflight.run(path, async () => {
            const jsonUrl = joinPath(this.rootPath, path + ".json");
            const imageUrl = joinPath(this.rootPath, path + ".png");
            const [json, spritesheetImage] = await Promise.all([
                fetch(jsonUrl).then(res => res.json()),
                fetchImageByUrl(imageUrl)
            ]);

            // split spritesheet to portions
            this.canvasContext.canvas.width = spritesheetImage.width;
            this.canvasContext.canvas.height = spritesheetImage.height;
            this.canvasContext.drawImage(spritesheetImage, 0, 0, spritesheetImage.width, spritesheetImage.height);

            /**
             * @type {Record<string, ImageData>}
             */
            const images = {};
            for (const [imagePath, imageInfo] of Object.entries(json.frames)) {
                const { x, y, w, h } = imageInfo.frame;
                const imageRef = imagePath.replace(/\.png$/, "");
                const data = this.canvasContext.getImageData(x, y, w, h);
                images[imageRef] = data;
                this.cache[path + "#" + imageRef] = {
                    data: data,
                    w: w,
                    h: h,
                    loading: false,
                }
            }
            return images;
        });
    }
}

export class ResourceLoader {
    constructor(dataPath, bmpLoader) {
        this.dataPath = dataPath;
        this.nxJson = null;
        this.bmpLoader = bmpLoader
    }
    static fromName(name) {
        return new ResourceLoader(`resource/${name}/nx.json`, new LazyBmpLoader(`resource/${name}/bitmaps`))
    }
    async load() {
        const path = this.dataPath
        const response = await fetch(path);
        this.nxJson = await response.json();
    }
    loadDesc(nodepath) {
        return getByPath(this.nxJson, nodepath)
    }
}

export class FileResourceLoader {
    constructor(filePath) {
        this.filePath = filePath;
        this.nxJson = null;
    }
    async load() {
        const response = await fetch(this.filePath);
        this.nxJson = await response.json();
    }
    loadDesc(nodepath) {
        return getByPath(this.nxJson, nodepath)
    }
}

/**
 * @typedef {Object} Pollable
 * @property {boolean} ready
 * @property {any} value
 */

export class CompositeResourceLoader {
    /**
     * 
     * @param {Record<string, FileResourceLoader>} prefixLoaderMap 
     * @param {PathImageLoader} bmpLoader 
     */
    constructor(prefixLoaderMap, bmpLoader) {
        this.prefixLoaderMap = prefixLoaderMap;
        this.bmpLoader = bmpLoader
    }
    async load() {
        for (let loader of Object.values(this.prefixLoaderMap)) {
            await loader.load();
        }
    }
    /**
     * 
     * @param {string} nodepath 
     * @returns {Pollable}
     */
    loadDesc(nodepath) {
        for (let [prefix, loader] of Object.entries(this.prefixLoaderMap)) {
            if (nodepath.startsWith(prefix)) {
                return loader.loadDesc(nodepath.substring(prefix.length))
            }
        }
        throw new Error(`nodepath not found: ${nodepath}`)
    }
}

export class CompositeAsyncResourceLoader {
    /**
     * 
     * @param {Record<string, DirResourceLoader>} prefixLoaderMap 
     * @param {PathImageLoader} bmpLoader 
     */
    constructor(prefixLoaderMap, bmpLoader) {
        this.prefixLoaderMap = prefixLoaderMap;
        this.bmpLoader = bmpLoader
    }
    /**
     * 
     * @param {string} nodepath 
     * @returns {Pollable}
     */
    loadDescAsync(nodepath) {
        for (let [prefix, loader] of Object.entries(this.prefixLoaderMap)) {
            if (nodepath.startsWith(prefix)) {
                return loader.loadDesc(nodepath.substring(prefix.length))
            }
        }
        throw new Error(`nodepath not found: ${nodepath}`)
    }
}

export class AsyncResourceLoader {
    /**
     * 
     * @param {DirResourceLoader} descLoader 
     * @param {LazyBmpLoader} bmpLoader 
     */
    constructor(descLoader, bmpLoader) {
        this.descLoader = descLoader;
        this.bmpLoader = bmpLoader;
    }
    /**
     * 
     * @param {string} nodepath 
     * @returns {Pollable}
     */
    loadDescAsync(nodepath) {
        return this.descLoader.loadDesc(nodepath)
    }
}


export class DirResourceLoader {
    constructor(rootPath) {
        this.rootPath = rootPath;
        this.cache = {}; // TODO: remove and implement cache in game code
    }
    /**
     * 
     * @param {string} nodepath 
     * @returns {Pollable}
     */
    loadDesc(nodepath) {
        let i = nodepath.indexOf('/');
        if (i == -1) {
            i = nodepath.length;
        }
        const child = nodepath.substring(0, i);
        const rest = nodepath.substring(i + 1);
        if (child in this.cache) {
            const json = this.cache[child]
            return {
                ready: true,
                value: getByPath(json, rest),
            }
        }
        const path = joinPath(this.rootPath, child + ".json")
        const pollable = {
            ready: false,
        }
        fetch(path).then(response => response.json()).then(json => {
            this.cache[child] = json;
            pollable.value = getByPath(json, rest)
            pollable.ready = true
        });
        return pollable;
    }
}

function getByPath(obj, path) {
    if (!path) {
        return obj;
    }
    const parts = path.split("/");
    return parts.reduce((acc, part) => {
        if (acc === null) return null; // TODO: throw error
        if (part in acc) return acc[part];
        return null;
    }, obj);
}

function joinPath(root, path) {
    // remove '/' from the end of root and the beginning of path
    if (root.endsWith("/")) {
        root = root.substring(0, root.length - 1);
    }
    if (path.startsWith("/")) {
        path = path.substring(1);
    }
    return `${root}/${path}`;
}
