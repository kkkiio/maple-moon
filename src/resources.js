import { ResourceLoader, PathImageLoader, AsyncResourceLoader, DirResourceLoader,CompositeAsyncResourceLoader } from "./resource_loader";

// Create canvas contexts for image loading
export const createCanvasContexts = () => {
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
 * Create string loader
 * 
 * @returns {NamedResourceLoader<ResourceLoader>}
 */
export const createStringLoader = () => {
  return { name: "string", loader: new ResourceLoader("https://maple-res.kkkiiox.work/String/nx.json", undefined) };
};

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
