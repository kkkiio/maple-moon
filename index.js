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
      const data = this.pendingData.shift();
      return {
        bytes: data,
        eof: false,
      }
    }
    return { bytes: new Uint8Array(), eof: this.ws.readyState === WebSocket.CLOSED }
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
  const uiLoader = new ResourceLoader("UI.nx");
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

  const soundLoader = new ResourceLoader("Sound.nx");
  prepareResourcePromises.push(
    soundLoader.load()
  );

  const characterLoader = new MergeResourceLoader("Character.nx", [
    { nodepath: "00002000.img", filename: "00002000.nx.json" },
    { nodepath: "00012000.img", filename: "00012000.nx.json" },
    { nodepath: "Hair/00030030.img", filename: "hair00030030.nx.json" },
    { nodepath: "Face/00020000.img", filename: "face00020000.nx.json" },
    { nodepath: "Coat/01040002.img", filename: "Coat/01040002.img.json" },
    { nodepath: "Pants/01060002.img", filename: "Pants/01060002.img.json" },
    { nodepath: "Shoes/01072001.img", filename: "Shoes/01072001.img.json" },
    { nodepath: "Weapon/01302000.img", filename: "Weapon/01302000.img.json" },
    { nodepath: "Weapon/01372005.img", filename: "Weapon/01372005.img.json" },
    { nodepath: "Weapon/01372006.img", filename: "Weapon/01372006.img.json" },
    { nodepath: "Weapon/01372002.img", filename: "Weapon/01372002.img.json" },
    { nodepath: "Weapon/01372004.img", filename: "Weapon/01372004.img.json" },
    { nodepath: "Weapon/01372003.img", filename: "Weapon/01372003.img.json" },
    { nodepath: "Weapon/01382000.img", filename: "Weapon/01382000.img.json" },
    { nodepath: "Weapon/01382003.img", filename: "Weapon/01382003.img.json" },
    { nodepath: "Weapon/01382005.img", filename: "Weapon/01382005.img.json" },
    { nodepath: "Weapon/01382004.img", filename: "Weapon/01382004.img.json" },
    { nodepath: "Weapon/01382002.img", filename: "Weapon/01382002.img.json" },
    { nodepath: "Weapon/01322002.img", filename: "Weapon/01322002.img.json" },
    { nodepath: "Afterimage", filename: "afterimage.nx.json" },
    { nodepath: "Cap/01002017.img", filename: "Cap/01002017.img.json" },
    { nodepath: "Cap/01002102.img", filename: "Cap/01002102.img.json" },
    { nodepath: "Cap/01002103.img", filename: "Cap/01002103.img.json" },
    { nodepath: "Cap/01002104.img", filename: "Cap/01002104.img.json" },
    { nodepath: "Cap/01002105.img", filename: "Cap/01002105.img.json" },
    { nodepath: "Cap/01002106.img", filename: "Cap/01002106.img.json" },
    { nodepath: "Cap/01002016.img", filename: "Cap/01002016.img.json" },
    { nodepath: "Cap/01002067.img", filename: "Cap/01002067.img.json" },
    { nodepath: "Longcoat/01052095.img", filename: "Longcoat/01052095.img.json" },
  ]);
  prepareResourcePromises.push(
    characterLoader.load()
  );

  const stringLoader = new ResourceLoader("String.nx");
  prepareResourcePromises.push(
    stringLoader.load()
  );

  const reactorLoader = new ResourceLoader("Reactor.nx");
  prepareResourcePromises.push(
    reactorLoader.load()
  );

  const map001Loader = new ResourceLoader("Map001.nx");
  prepareResourcePromises.push(
    map001Loader.load()
  );

  const mapPrettyLoader = new ResourceLoader("MapPretty.nx");
  prepareResourcePromises.push(
    mapPrettyLoader.load()
  );

  const etcLoader = new ResourceLoader("Etc.nx");
  prepareResourcePromises.push(
    etcLoader.load()
  );
  const npcLoader = new ResourceLoader("Npc.nx");
  prepareResourcePromises.push(
    npcLoader.load()
  );
  const itemLoader = new ResourceLoader("Item.nx");
  prepareResourcePromises.push(
    itemLoader.load()
  );
  const mobLoader = new ResourceLoader("Mob.nx");
  prepareResourcePromises.push(
    mobLoader.load()
  );
  const effectLoader = new ResourceLoader("Effect.nx");
  prepareResourcePromises.push(
    effectLoader.load()
  );
  const skillLoader = new ResourceLoader("Skill.nx");
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
          default:
            throw new Error(`Unknown resource loader: ${name}`);
        }
      },
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
      window.addEventListener("mousedown", (evt) => {
        onmousedown();
      });
      window.addEventListener("mouseup", (evt) => {
        onmouseup();
      });

      globalThis.transit_to = m.transit_to;
      globalThis.load_player = m.load_player;
      m.game_start();
      requestAnimationFrameId = requestAnimationFrame(update);
    });
}
main();
