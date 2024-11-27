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
                const imageData = images[spriteSheetRef + ".png"];
                res.data = imageData;
                res.w = imageData.width;
                res.h = imageData.height;
                res.loading = false;
            });
        } else {
            fetchImageByUrl(imagePath).then(img => {
                res.data = img;
                res.w = img.width;
                res.h = img.height;
                res.loading = false;
            });
        }
        return res;
    }
    async loadSpritesheet(path) {
        const jsonPath = joinPath(this.rootPath, path + ".json");
        const imagePath = joinPath(this.rootPath, path + ".png");
        const [json, spritesheetImage] = await Promise.all([fetch(jsonPath).then(res => res.json()), fetchImageByUrl(imagePath)]);
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
            images[imagePath] = this.canvasContext.getImageData(x, y, w, h)
        }
        return images;
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

/**
 * @typedef {Object} Pollable
 * @property {boolean} ready
 * @property {any} value
 */

export class MixResourceLoader {
    constructor(name, mappings) {
        this.name = name;
        this.mappings = mappings;
        this.instant = null;
        /**
         * @type {Array<{prefix: string, loader: DirResourceLoader}>}
         */
        this.folderLoaders = [];
        this.bmpLoader = new LazyBmpLoader(`resource/${name}/bitmaps`)
    }
    async start() {
        this.instant = {}
        for (let mapping of this.mappings) {
            if (mapping.folder) {
                this.folderLoaders.push({
                    prefix: mapping.nodepath + "/",
                    loader: new DirResourceLoader(`resource/${this.name}/${mapping.folder}`)
                })
                continue
            }
            const path = `resource/${this.name}/${mapping.filename}`
            const response = await fetch(path);
            const subJson = await response.json();
            let root = this.instant
            let parts = mapping.nodepath.split("/");
            for (let i = 0; i < parts.length; i++) {
                if (i == parts.length - 1) {
                    root[parts[i]] = subJson
                } else {
                    if (!(parts[i] in root)) {
                        root[parts[i]] = {}
                    }
                    root = root[parts[i]]
                }
            }
        }
    }
    /**
     * 
     * @param {string} nodepath 
     * @returns {Pollable}
     */
    loadDescAsync(nodepath) {
        if (this.folderLoaders.length > 0) {
            for (let pair of this.folderLoaders) {
                if (nodepath.startsWith(pair.prefix)) {
                    return pair.loader.loadDesc(nodepath.substring(pair.prefix.length))
                }
            }
        }
        return {
            ready: true,
            value: getByPath(this.instant, nodepath),
        }
    }
    /**
     * 
     * @param {string} nodepath 
     * @returns {any}
     */
    loadDesc(nodepath) {
        return getByPath(this.instant, nodepath)
    }
}

export class CompositeResourceLoader {
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
        this.cache = {};
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