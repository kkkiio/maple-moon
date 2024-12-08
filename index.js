import { setupGl } from './gl.js';
import {
  AsyncResourceLoader,
  BidImageLoader,
  CompositeAsyncResourceLoader,
  CompositeResourceLoader,
  DirResourceLoader,
  FileResourceLoader,
  PathImageLoader,
  ResourceLoader
} from './resource.js';

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
  constructor(textCtx) {
    this.textCtx = textCtx;
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

  const imageGenerateContext = document.createElement("canvas").getContext("2d", {
    willReadFrequently: true,
  });
  const imageLoader = new PathImageLoader("https://maple.kkkiiox.work", imageGenerateContext)
  const prepareResourcePromises = [];
  const uiLoader = new CompositeResourceLoader({
    "Basic.img/": new FileResourceLoader("https://maple.kkkiiox.work/UI/Basic.img.json"),
    "Login.img/": new FileResourceLoader("https://maple.kkkiiox.work/UI/Login.img.json"),
    "StatusBar3.img/": new FileResourceLoader("https://maple.kkkiiox.work/UI/StatusBar3.img.json"),
  }, imageLoader)
  prepareResourcePromises.push(
    uiLoader.load()
  )
  const uiWindow2Loader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/UI/UIWindow2.img"),
    imageLoader
  )
  const uiWindow4Loader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/UI/UIWindow4.img"),
    imageLoader
  )

  const mapxLoader = new CompositeAsyncResourceLoader({
    "Map0/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map0"),
    "Map1/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map1"),
    "Map2/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map2"),
    "Map3/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map3"),
    "Map4/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map4"),
    "Map5/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map5"),
    "Map6/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map6"),
    "Map7/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map7"),
    "Map8/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map8"),
    "Map9/": new DirResourceLoader("https://maple.kkkiiox.work/Map/Map9"),
  }, imageLoader)
  const tileLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Map/Tile"),
    imageLoader
  )
  const backgroundLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Map/Back"),
    imageLoader
  )
  const objLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Map/Obj"),
    imageLoader
  )
  const mapHelperLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Map/MapHelper.img"),
    imageLoader
  )

  const characterLoader = new CompositeAsyncResourceLoader({
    "Pants/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Pants"),
    "Weapon/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Weapon"),
    "Coat/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Coat"),
    "Cap/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Cap"),
    "Longcoat/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Longcoat"),
    "Shield/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Shield"),
    "Shoes/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Shoes"),
    "Glove/": new DirResourceLoader("https://maple.kkkiiox.work/Character/Glove"),
  }, imageLoader);

  const bodyLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Character/Body"),
    imageLoader
  )
  const hairLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Character/Hair"),
    imageLoader
  )
  const faceLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Character/Face"),
    imageLoader
  )
  const afterimageLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Character/Afterimage"),
    imageLoader
  )

  const stringLoader = new ResourceLoader("https://maple.kkkiiox.work/String/nx.json", new BidImageLoader("https://maple.kkkiiox.work/String/images"));
  prepareResourcePromises.push(
    stringLoader.load()
  );

  const reactorLoader = new ResourceLoader("https://maple.kkkiiox.work/Reactor/nx.json", new BidImageLoader("https://maple.kkkiiox.work/Reactor/images"));
  prepareResourcePromises.push(
    reactorLoader.load()
  );

  const map001Loader = new ResourceLoader("https://maple.kkkiiox.work/Map001/nx.json", new BidImageLoader("https://maple.kkkiiox.work/Map001/images"));
  prepareResourcePromises.push(
    map001Loader.load()
  );

  const mapPrettyLoader = new ResourceLoader("https://maple.kkkiiox.work/MapPretty/nx.json", new BidImageLoader("https://maple.kkkiiox.work/MapPretty/images"));
  prepareResourcePromises.push(
    mapPrettyLoader.load()
  );

  const etcLoader = new ResourceLoader("https://maple.kkkiiox.work/Etc/nx.json", new BidImageLoader("https://maple.kkkiiox.work/Etc/images"));
  prepareResourcePromises.push(
    etcLoader.load()
  );

  const npcLoader = new ResourceLoader("https://maple.kkkiiox.work/Npc/nx.json",
    new BidImageLoader("https://maple.kkkiiox.work/Npc/images"));
  prepareResourcePromises.push(
    npcLoader.load()
  );

  const itemLoader = new ResourceLoader("https://maple.kkkiiox.work/Item/nx.json", new BidImageLoader("https://maple.kkkiiox.work/Item/images"));
  prepareResourcePromises.push(
    itemLoader.load()
  );

  const mobLoader = new AsyncResourceLoader(
    new DirResourceLoader("https://maple.kkkiiox.work/Mob"),
    imageLoader
  );

  const effectLoader = new ResourceLoader("https://maple.kkkiiox.work/Effect/nx.json", new BidImageLoader("https://maple.kkkiiox.work/Effect/images"));
  prepareResourcePromises.push(
    effectLoader.load()
  );

  const skillLoader = new ResourceLoader("https://maple.kkkiiox.work/Skill/nx.json", new BidImageLoader("https://maple.kkkiiox.work/Skill/images"));
  prepareResourcePromises.push(
    skillLoader.load()
  );

  const textBitmapGenerator = new TextBitmapGenerator(imageGenerateContext);

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
          case "common_ui":
            return uiLoader;
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
            return afterimageLoader;
          case "background":
            return backgroundLoader;
          case "obj":
            return objLoader;
          case "ui_window_2":
            return uiWindow2Loader;
          case "ui_window_4":
            return uiWindow4Loader;
          case "mob":
            return mobLoader;
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
      width: (bmp) => bmp.w,
      height: (bmp) => bmp.h,
      loading: (bmp) => bmp.loading === true,
      load: (bmp) => bmp,
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
