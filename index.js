import { setupGl } from './gl.js';
import {
  ImageLoader,
  LazyBmpLoader,
  LazyResourceLoader,
  ResourceLoader,
} from './resource.js';

class MergeResourceLoader {
  constructor(name, mappings) {
    this.name = name;
    this.mappings = mappings;
    this.nxJson = null;
    this.bmpLoader = new LazyBmpLoader(`resource/${name}/bitmaps`)
  }
  async load() {
    this.nxJson = {}
    for (let mapping of this.mappings) {
      const path = `resource/${this.name}/${mapping.filename}`
      const response = await fetch(path);
      const subJson = await response.json();
      let root = this.nxJson
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
    return getByPath(this.nxJson, nodepath)
  }
}

class Socket {
  constructor(path) {
    console.log("connect server", path)
    this.ws = new WebSocket("ws://" + location.host + path, "binary");
    this.ws.binaryType = "arraybuffer";
    this.pendingData = [];
    this.ws.addEventListener("open", (event) => {
      console.info("connect server success", event)
    })
    this.ws.addEventListener("message", (event) => {
      this.pendingData.push(new Uint8Array(event.data));
    })
    this.ws.addEventListener("error", (event) => {
      console.error("connect server error", event)
    })
    this.ws.addEventListener("close", (event) => {
      console.info("connect server close", event)
    })
  }
  close() {
    this.ws.close()
  }
  getReadyState() {
    return this.ws.readyState
  }
  read() {
    if (this.pendingData.length > 0) {
      return this.pendingData.shift();
    }
    return new Uint8Array();
  }
  write(bytes) {
    this.ws.send(bytes.buffer);
  }
}
const VWIDTH = 1366;
const VHEIGHT = 768;
class TextBitmapGenerator {
  constructor() {
    this.textCtx = document.createElement("canvas").getContext("2d", {
      willReadFrequently: true,
    });
    this.testDom = document.getElementById("test");
  }
  // TODO: allow individual font style
  createImage(textHtml, fontSize, fontName, color, textAlign, maxWidth) {
    const html =
      `<p style="font-size: ${fontSize}px; font-family: ${fontName}; color: ${color}; text-align: ${textAlign};">${textHtml}</p>`;
    const tmpImg = document.createElement('img');
    const [width, height] = this.calculateTextSize(html, maxWidth);
    const bmp = {
      loading: true,
      w: width,
      h: height,
    }
    tmpImg.onload = () => {
      this.textCtx.canvas.width = tmpImg.width;
      this.textCtx.canvas.height = tmpImg.height;
      this.textCtx.clearRect(0, 0, this.textCtx.canvas.width, this.textCtx.canvas.height);
      this.textCtx.drawImage(tmpImg, 0, 0);
      const dataUrl = this.textCtx.canvas.toDataURL();
      console.debug(dataUrl)
      const targetImg = document.createElement('img');
      bmp.data = targetImg;
      targetImg.onload = () => {
        bmp.loading = false;
      }
      targetImg.src = dataUrl;
    };
    tmpImg.src = 'data:image/svg+xml,' + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><foreignObject width="100%" height="100%"><div xmlns="http://www.w3.org/1999/xhtml"><style>p{margin:0}</style>${html}</div></foreignObject></svg>`)
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
function main() {
  const canvas = document.getElementById("canvas");
  canvas.width = VWIDTH;
  canvas.height = VHEIGHT;

  // Add this line to disable context menu on canvas
  canvas.addEventListener('contextmenu', e => e.preventDefault());

  const gl = canvas.getContext("webgl2", {});
  if (!gl) {
    throw new Error("WebGL not supported");
  }

  const prepareResourcePromises = [];
  const uiLoader = ResourceLoader.fromName("UI.nx");
  prepareResourcePromises.push(
    uiLoader.load()
  );

  const mapLoader = new LazyResourceLoader("Map.nx", [
    { nodepath: "MapHelper.img", filename: "helper.nx.json" },
    { nodepath: "Tile", filename: "tile.nx.json" },
    { nodepath: "Obj", filename: "obj.nx.json" },
    { nodepath: "Back", filename: "back.nx.json" },
    { nodepath: "Map/Map0", folder: "Map/Map0" },
    { nodepath: "Map/Map1", folder: "Map/Map1" },
    { nodepath: "Map/Map6", folder: "Map/Map6" },
  ]);
  prepareResourcePromises.push(
    mapLoader.start()
  );

  const soundLoader = ResourceLoader.fromName("Sound.nx");
  prepareResourcePromises.push(
    soundLoader.load()
  );

  const characterLoader = new LazyResourceLoader("Character.nx", [
    { nodepath: "00002000.img", filename: "00002000.nx.json" },
    { nodepath: "00012000.img", filename: "00012000.nx.json" },
    { nodepath: "Hair/00030030.img", filename: "hair00030030.nx.json" },
    { nodepath: "Face/00020000.img", filename: "face00020000.nx.json" },
    { nodepath: "Pants", folder: "Pants" },
    { nodepath: "Weapon", folder: "Weapon" },
    { nodepath: "Coat", folder: "Coat" },
    { nodepath: "Cap", folder: "Cap" },
    { nodepath: "Longcoat", folder: "Longcoat" },
    { nodepath: "Shield", folder: "Shield" },
    { nodepath: "Shoes", folder: "Shoes" },
    { nodepath: "Glove", folder: "Glove" },
    { nodepath: "Afterimage", filename: "afterimage.nx.json" },
  ]);
  prepareResourcePromises.push(
    characterLoader.start()
  );

  const stringLoader = ResourceLoader.fromName("String.nx");
  prepareResourcePromises.push(
    stringLoader.load()
  );

  const reactorLoader = ResourceLoader.fromName("Reactor.nx");
  prepareResourcePromises.push(
    reactorLoader.load()
  );

  const map001Loader = ResourceLoader.fromName("Map001.nx");
  prepareResourcePromises.push(
    map001Loader.load()
  );

  const mapPrettyLoader = ResourceLoader.fromName("MapPretty.nx");
  prepareResourcePromises.push(
    mapPrettyLoader.load()
  );

  const etcLoader = ResourceLoader.fromName("Etc.nx");
  prepareResourcePromises.push(
    etcLoader.load()
  );

  const npcLoader = new ResourceLoader("resource/Npc.nx/nx.json",
    new ImageLoader("https://maple.kkkiiox.work/Npc/images"));
  prepareResourcePromises.push(
    npcLoader.load()
  );

  const itemLoader = ResourceLoader.fromName("Item.nx");
  prepareResourcePromises.push(
    itemLoader.load()
  );

  const mobLoader = ResourceLoader.fromName("Mob.nx");
  prepareResourcePromises.push(
    mobLoader.load()
  );

  const effectLoader = ResourceLoader.fromName("Effect.nx");
  prepareResourcePromises.push(
    effectLoader.load()
  );

  const skillLoader = ResourceLoader.fromName("Skill.nx");
  prepareResourcePromises.push(
    skillLoader.load()
  );

  const textBitmapGenerator = new TextBitmapGenerator();

  let requestAnimationFrameId = null;

  let halt = false;
  let game_update = null;
  const glModule = setupGl(gl);

  const importObject = {
    gl: glModule,
    text: {
      create_image: textBitmapGenerator.createImage.bind(textBitmapGenerator)
    },
    resource: {
      get_loader: (name) => {
        switch (name) {
          case "ui":
            return uiLoader;
          case "sound":
            return soundLoader;
          case "character":
            return characterLoader;
          case "string":
            return stringLoader;
          case "reactor":
            return reactorLoader;
          case "map001":
            return map001Loader;
          case "map_pretty":
            return mapPrettyLoader;
          case "etc":
            return etcLoader;
          case "npc":
            return npcLoader;
          case "item":
            return itemLoader;
          case "mob":
            return mobLoader;
          case "effect":
            return effectLoader;
          case "skill":
            return skillLoader;
          default:
            throw new Error(`Unknown resource loader: ${name}`);
        }
      },
      get_async_loader: (name) => {
        switch (name) {
          case "map":
            return mapLoader;
          case "character":
            return characterLoader;
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
    },
    bitmap: {
      id: (bmp) => bmp.id,
      width: (bmp) => bmp.w,
      height: (bmp) => bmp.h,
      loading: (bmp) => bmp.loading === true,
    },
    time: {
      now_micro: () => {
        return performance.now() * 1000;
      },
    },
    socket: {
      open: (path) => new Socket(path),
      close: (socket) => { socket.close() },
      get_ready_state: (socket) => socket.getReadyState(),
    },
    log: {
      debug: (msg) => console.debug(msg),
      info: (msg) => console.info(msg),
      warn: (msg) => console.warn(msg),
      error: (msg) => console.error(msg),
    },
    spectest: {
      print_i32: (x) => console.log(String(x)),
      print_f64: (x) => console.log(String(x)),
    },
  };

  function update(time = 0) {
    game_update(time * 1000);
    if (!halt) {
      requestAnimationFrameId = requestAnimationFrame(update);
    }
  }

  Object.assign(globalThis, importObject);
  Promise.all(prepareResourcePromises)
    .then(() => import("./lib/lib.js"))
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

      globalThis.transit_to = m.transit_to;
      globalThis.load_player = m.load_player;
      m.game_start();
      requestAnimationFrameId = requestAnimationFrame(update);
    });
}
main();
