class LazyBmpLoader {
    constructor(bmpDir) {
        this.bmpDir = bmpDir;
        this.bitmaps = {};
    }
    loadImage(bid) {
        let bmp = this.bitmaps[bid];
        if (bmp) {
            return bmp;
        }
        const img = new Image();
        const bmpPath = `${this.bmpDir}/${bid}.png`;
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

class ResourceLoader {
    constructor(name) {
        this.name = name;
        this.nxJson = null;
        this.bmpLoader = new LazyBmpLoader(`resource/${name}/bitmaps`)
    }
    async load() {
        const path = `resource/${this.name}/nx.json`
        const response = await fetch(path);
        this.nxJson = await response.json();
    }
    loadDesc(nodepath) {
        return getByPath(this.nxJson, nodepath)
    }
}

class LazyResourceLoader {
    constructor(name, mappings) {
        this.name = name;
        this.mappings = mappings;
        this.instant = null;
        this.folderLoaders = [];
        this.bmpLoader = new LazyBmpLoader(`resource/${name}/bitmaps`)
    }
    async start() {
        this.instant = {}
        for (let mapping of this.mappings) {
            if (mapping.folder) {
                this.folderLoaders.push({
                    prefix: mapping.nodepath + "/",
                    loader: new FolderResourceLoader(`resource/${this.name}/${mapping.folder}`)
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
    loadDesc(nodepath) {
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
}

class FolderResourceLoader {
    constructor(folderPath) {
        this.folderPath = folderPath;
        this.cache = {};
    }
    /**
     * 
     * @param {string} nodepath 
     * @returns 
     */
    loadDesc(nodepath) {
        const [child, rest] = nodepath.split("/", 1)
        if (child in this.cache) {
            const json = this.cache[child]
            return {
                ready: true,
                value: getByPath(json, rest),
            }
        }
        const path = `${this.folderPath}/${child}.json`
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