/**
 * @param {string} url
 * @returns {Promise<HTMLImageElement>}
 */
async function fetchImageByUrl(url) {
  const img = new Image();
  img.crossOrigin = "anonymous";
  return new Promise((resolve, reject) => {
    img.onload = () => {
      resolve(img);
    };
    img.onerror = (e) => {
      reject(new Error(`fetch image by url failed: ${url}`, { cause: e }));
    };
    img.src = url;
  });
}

/**
 * @typedef {Object} LazyImage
 * @property {HTMLImageElement} data
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
    fetchImageByUrl(bmpPath).then((img) => {
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
   * @param {CanvasRenderingContext2D} cc1
   * @param {CanvasRenderingContext2D} cc2
   */
  constructor(rootPath, cc1, cc2) {
    this.rootPath = rootPath;
    this.cc1 = cc1;
    this.cc2 = cc2;
    /**
     * @type {Record<string, LazyImage>}
     */
    this.cache = {};
    /**
     * @type {Record<string, Promise<Record<string, HTMLImageElement>>>}
     */
    this.spriteSheetCache = {};
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
      this.loadSpritesheet(imagePath).then((images) => {
        const img = images[spriteSheetRef];
        res.data = img;
        res.w = img.width;
        res.h = img.height;
        res.loading = false;
      });
    } else {
      fetchImageByUrl(joinPath(this.rootPath, imagePath)).then((img) => {
        res.data = img;
        res.w = img.width;
        res.h = img.height;
        res.loading = false;
      });
    }
    return res;
  }
  async loadSpritesheet(path) {
    let cached = this.spriteSheetCache[path];
    if (cached) {
      return cached;
    }
    cached = (async () => {
      const jsonUrl = joinPath(this.rootPath, path + ".json");
      const imageUrl = joinPath(this.rootPath, path + ".png");
      const [json, spritesheetImage] = await Promise.all([
        fetch(jsonUrl).then((res) => res.json()),
        fetchImageByUrl(imageUrl),
      ]);

      // split spritesheet to portions
      this.cc1.canvas.width = spritesheetImage.width;
      this.cc1.canvas.height = spritesheetImage.height;
      this.cc1.drawImage(
        spritesheetImage,
        0,
        0,
        spritesheetImage.width,
        spritesheetImage.height
      );

      /**
       * @type {Promise<[string, HTMLImageElement]>[]}
       */
      const promises = [];
      for (const [imagePath, imageInfo] of Object.entries(json.frames)) {
        const { x, y, w, h } = imageInfo.frame;
        const imageRef = imagePath.replace(/\.png$/, "");
        const data = this.cc1.getImageData(x, y, w, h);
        this.cc2.canvas.width = w;
        this.cc2.canvas.height = h;
        this.cc2.putImageData(data, 0, 0);
        promises.push(
          loadImage(this.cc2.canvas.toDataURL()).then((img) => {
            return [imageRef, img];
          })
        );
      }
      return Object.fromEntries(await Promise.all(promises));
    })();
    this.spriteSheetCache[path] = cached;
    return cached;
  }
}

export class ResourceLoader {
  constructor(dataPath, bmpLoader) {
    this.dataPath = dataPath;
    this.nxJson = null;
    this.bmpLoader = bmpLoader;
  }
  async load() {
    const response = await fetch(this.dataPath);
    this.nxJson = await response.json();
  }
  loadDesc(nodepath) {
    return getByPath(this.nxJson, nodepath);
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
    return getByPath(this.nxJson, nodepath);
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
    this.bmpLoader = bmpLoader;
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
        return loader.loadDesc(nodepath.substring(prefix.length));
      }
    }
    throw new Error(`nodepath not found: ${nodepath}`);
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
    this.bmpLoader = bmpLoader;
  }
  /**
   *
   * @param {string} nodepath
   * @returns {Pollable}
   */
  loadDescAsync(nodepath) {
    for (let [prefix, loader] of Object.entries(this.prefixLoaderMap)) {
      if (nodepath.startsWith(prefix)) {
        return loader.loadDesc(nodepath.substring(prefix.length));
      }
    }
    throw new Error(`nodepath not found: ${nodepath}`);
  }
}

export class AsyncResourceLoader {
  /**
   *
   * @param {DirResourceLoader} descLoader
   * @param {PathImageLoader} bmpLoader
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
    return this.descLoader.loadDesc(nodepath);
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
    let i = nodepath.indexOf("/");
    if (i == -1) {
      i = nodepath.length;
    }
    const child = nodepath.substring(0, i);
    const rest = nodepath.substring(i + 1);
    if (child in this.cache) {
      const json = this.cache[child];
      return {
        ready: true,
        value: getByPath(json, rest),
      };
    }
    const path = joinPath(this.rootPath, child + ".json");
    const pollable = {
      ready: false,
    };
    fetch(path)
      .then((response) => response.json())
      .then((json) => {
        this.cache[child] = json;
        pollable.value = getByPath(json, rest);
        pollable.ready = true;
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

/**
 *
 * @param {string} url
 * @returns {Promise<HTMLImageElement>}
 */
function loadImage(url) {
  const img = new Image();
  const promise = new Promise((resolve, reject) => {
    img.onload = () => {
      resolve(img);
    };
    img.onerror = (e) => {
      reject(e);
    };
  });
  img.src = url;
  return promise;
}
