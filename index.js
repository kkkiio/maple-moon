const vertexShaderSource = `#version 300 es
precision highp float;
in vec4 coord;
in vec4 color;
// Used to pass in the resolution of the canvas
uniform vec2 screensize;
out vec2 texpos;
out vec4 colormod;
void main(void)
{
  // screen resolution is 1366 * 768
  float x = (-1.0 + coord.x * (screensize.y / 384.0) / screensize.x);
  // Set image to left top
  float y = 1.0 - coord.y / 384.0;
  gl_Position = vec4(x, y, 0.0, 1.0);
  // Pass the texcoord to the fragment shader.
  texpos = coord.zw;
  colormod = color;
}
`;
const fragmentShaderSource = `#version 300 es
precision highp float;
// Passed in from the vertex shader.
in vec2 texpos;
in vec4 colormod;
// The texture.
uniform sampler2D u_texture;
uniform vec2 atlassize;
out vec4 FragColor;

void main(void)
{
  FragColor = texture(u_texture, texpos / atlassize) * colormod;
}
`;
/**
 * Wrapped logging function.
 * @param {string} msg The message to log.
 */
function error(msg) {
  if (topWindow.console) {
    if (topWindow.console.error) {
      topWindow.console.error(msg);
    } else if (topWindow.console.log) {
      topWindow.console.log(msg);
    }
  }
}
const defaultShaderType = ["VERTEX_SHADER", "FRAGMENT_SHADER"];
/**
 * Creates a program from 2 sources.
 *
 * @param {WebGLRenderingContext} gl The WebGLRenderingContext
 *        to use.
 * @param {string[]} shaderSourcess Array of sources for the
 *        shaders. The first is assumed to be the vertex shader,
 *        the second the fragment shader.
 * @param {string[]} [opt_attribs] An array of attribs names. Locations will be assigned by index if not passed in
 * @param {number[]} [opt_locations] The locations for the. A parallel array to opt_attribs letting you assign locations.
 * @param {module:webgl-utils.ErrorCallback} opt_errorCallback callback for errors. By default it just prints an error to the console
 *        on error. If you want something else pass an callback. It's passed an error message.
 * @return {WebGLProgram} The created program.
 * @memberOf module:webgl-utils
 */
function createProgramFromSources(
  gl,
  shaderSources,
  opt_attribs,
  opt_locations,
  opt_errorCallback
) {
  const shaders = [];
  for (let ii = 0; ii < shaderSources.length; ++ii) {
    shaders.push(
      loadShader(
        gl,
        shaderSources[ii],
        gl[defaultShaderType[ii]],
        opt_errorCallback
      )
    );
  }
  return createProgram(
    gl,
    shaders,
    opt_attribs,
    opt_locations,
    opt_errorCallback
  );
}
/**
 * Creates a program, attaches shaders, binds attrib locations, links the
 * program and calls useProgram.
 * @param {WebGLShader[]} shaders The shaders to attach
 * @param {string[]} [opt_attribs] An array of attribs names. Locations will be assigned by index if not passed in
 * @param {number[]} [opt_locations] The locations for the. A parallel array to opt_attribs letting you assign locations.
 * @param {module:webgl-utils.ErrorCallback} opt_errorCallback callback for errors. By default it just prints an error to the console
 *        on error. If you want something else pass an callback. It's passed an error message.
 * @memberOf module:webgl-utils
 */
function createProgram(
  gl,
  shaders,
  opt_attribs,
  opt_locations,
  opt_errorCallback
) {
  const errFn = opt_errorCallback || error;
  const program = gl.createProgram();
  shaders.forEach(function (shader) {
    gl.attachShader(program, shader);
  });
  if (opt_attribs) {
    opt_attribs.forEach(function (attrib, ndx) {
      gl.bindAttribLocation(
        program,
        opt_locations ? opt_locations[ndx] : ndx,
        attrib
      );
    });
  }
  gl.linkProgram(program);

  // Check the link status
  const linked = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (!linked) {
    // something went wrong with the link
    const lastError = gl.getProgramInfoLog(program);
    errFn(
      `Error in program linking: ${lastError}\n${shaders
        .map((shader) => {
          const src = addLineNumbersWithError(gl.getShaderSource(shader));
          const type = gl.getShaderParameter(shader, gl.SHADER_TYPE);
          return `${glEnumToString(gl, type)}:\n${src}`;
        })
        .join("\n")}`
    );

    gl.deleteProgram(program);
    return null;
  }
  return program;
}
/**
 * Loads a shader.
 * @param {WebGLRenderingContext} gl The WebGLRenderingContext to use.
 * @param {string} shaderSource The shader source.
 * @param {number} shaderType The type of shader.
 * @param {module:webgl-utils.ErrorCallback} opt_errorCallback callback for errors.
 * @return {WebGLShader} The created shader.
 */
function loadShader(gl, shaderSource, shaderType, opt_errorCallback) {
  const errFn = opt_errorCallback || error;
  // Create the shader object
  const shader = gl.createShader(shaderType);

  // Load the shader source
  gl.shaderSource(shader, shaderSource);

  // Compile the shader
  gl.compileShader(shader);

  // Check the compile status
  const compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
  if (!compiled) {
    // Something went wrong during compilation; get the error
    const lastError = gl.getShaderInfoLog(shader);
    errFn(
      `Error compiling shader: ${lastError}\n${addLineNumbersWithError(
        shaderSource,
        lastError
      )}`
    );
    gl.deleteShader(shader);
    return null;
  }

  return shader;
}

let resourceLoaderNo = 0;

class ResourceLoader {
  constructor(name) {
    this.name = name;
    this.nxJson = null;
    const no = resourceLoaderNo;
    resourceLoaderNo += 1
    this.bmpLoader = new DirectBmpLoader(no, `resource/${name}/bitmaps`)
  }
  async load() {
    const path = `resource/${this.name}/nx.json`
    const response = await fetch(path);
    this.nxJson = await response.json();
  }
  loadDesc(nodepath) {
    let parts = nodepath.split("/");
    return parts.reduce((acc, part) => {
      if (acc === null) return null;
      if (part in acc) return acc[part];
      return null;
    }, this.nxJson);
  }
}

class MergeResourceLoader {
  constructor(name, mappings) {
    this.name = name;
    this.mappings = mappings;
    this.nxJson = null;
    const no = resourceLoaderNo;
    resourceLoaderNo += 1
    this.bmpLoader = new DirectBmpLoader(no, `resource/${name}/bitmaps`)
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
    let parts = nodepath.split("/");
    return parts.reduce((acc, part) => {
      if (acc === null) return null;
      if (part in acc) return acc[part];
      return null;
    }, this.nxJson);
  }
}

class DirectBmpLoader {
  constructor(i, bmpFolderPath) {
    this.i = i;
    this.bmpFolderPath = bmpFolderPath;
    this.bitmaps = {};
  }
  loadBitmap(bid) {
    let bmp = this.bitmaps[bid];
    if (bmp) {
      return bmp;
    }
    const img = new Image();
    const bmpPath = `${this.bmpFolderPath}/${bid}.png`;
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
  isConnected() {
    return this.ws.readyState === WebSocket.OPEN
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
const ATLASW = 8192;
const ATLASH = 8192;
class TextBitmapGenerator {
  constructor() {
    this.textCtx = document.createElement("canvas").getContext("2d", {
      willReadFrequently: true,
    });
    this.textCtx.canvas.width = VWIDTH;
    this.textCtx.canvas.height = VHEIGHT;
  }
  // TODO: allow individual font style
  createImage(innerHtml, fontSize, fontName, maxWidth, textAlign) {
    const htmlSvg = `data:image/svg+xml;charset=utf-8,<svg xmlns="http://www.w3.org/2000/svg" width="${maxWidth}" height="${VHEIGHT}"><foreignObject x="0" y="0" width="100%" height="100%"><body xmlns="http://www.w3.org/1999/xhtml" style="margin: 0px"><p style="margin: 0px; font-size: ${fontSize}px; font-family: ${fontName}; color: black; text-align: ${textAlign};">${innerHtml}</p></body></foreignObject></svg>`;
    const img = new Image();
    const bmp = {
      data: null,
      loading: true,
    }
    img.onload = () => {
      this.textCtx.clearRect(0, 0, this.textCtx.canvas.width, this.textCtx.canvas.height);
      this.textCtx.drawImage(img, 0, 0);
      bmp.data = this.textCtx.getImageData(0, 0, img.width, img.height);
      bmp.w = img.width;
      bmp.h = img.height;
      bmp.loading = false;
    };
    img.src = htmlSvg;
    return bmp;
  }
}
function main() {
  const canvas = document.getElementById("canvas");
  const gl = canvas.getContext("webgl2", {
    // premultipliedAlpha: false,
  });
  if (!gl) {
    throw new Error("WebGL not supported");
  }

  canvas.width = VWIDTH;
  canvas.height = VHEIGHT;
  // Set image to left top, multiplied by phone (screensize y / 384), screen resolution is 1366 * 768
  const program = createProgramFromSources(gl, [
    vertexShaderSource,
    fragmentShaderSource,
  ]);

  // look up where the vertex data needs to go.
  const coordAttributeLocation = gl.getAttribLocation(program, "coord");
  const colorAttributeLocation = gl.getAttribLocation(program, "color");
  // look up uniform locations
  const textureLocation = gl.getUniformLocation(program, "u_texture");
  const screensizeUniformLocation = gl.getUniformLocation(
    program,
    "screensize"
  );
  const atlassizeUniformLocation = gl.getUniformLocation(program, "atlassize");

  // Vertex Buffer Object
  const VBO = gl.createBuffer();
  // Create a vertex array object (attribute state)
  var vao = gl.createVertexArray();
  // and make it the one we're currently working with
  gl.bindVertexArray(vao);
  // Turn on the attribute
  gl.enableVertexAttribArray(coordAttributeLocation);
  gl.enableVertexAttribArray(colorAttributeLocation);

  gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
  const bytesOfCoord = 4 * 2;
  const bytesOfVertex = bytesOfCoord + 4 * 4;
  gl.vertexAttribPointer(
    coordAttributeLocation,
    4,
    gl.SHORT,
    false,
    bytesOfVertex,
    0
  );
  gl.vertexAttribPointer(
    colorAttributeLocation,
    4,
    gl.FLOAT,
    false,
    bytesOfVertex,
    bytesOfCoord
  );

  // Create a texture.
  const texture = gl.createTexture();
  // use texture unit 0
  gl.activeTexture(gl.TEXTURE0 + 0);
  // bind to the TEXTURE_2D bind point of texture unit 0
  gl.bindTexture(gl.TEXTURE_2D, texture);
  // create the atlas buffer
  gl.texImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    ATLASW,
    ATLASH,
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    null
  );
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.enable(gl.BLEND); // enable alpha blending
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA); // specify how alpha must blend: fragment color * alpha + clear color * (1 - alpha)
  // gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
  //   gl.bindVertexArray(null);

  const prepareResourcePromises = [];
  const uiLoader = new ResourceLoader("UI.nx");
  prepareResourcePromises.push(
    uiLoader.load()
  );

  const mapLoader = new MergeResourceLoader("Map.nx", [
    { nodepath: "Map/Map0", filename: "map0.nx.json" },
    { nodepath: "MapHelper.img", filename: "helper.nx.json" },
    { nodepath: "Tile", filename: "tile.nx.json" },
    { nodepath: "Obj", filename: "obj.nx.json" },
    { nodepath: "Back", filename: "back.nx.json" },
  ]);
  prepareResourcePromises.push(
    mapLoader.load()
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
    { nodepath: "Coat/01040002.img", filename: "coat01040002.nx.json" },
    { nodepath: "Pants/01060002.img", filename: "pants01060002.nx.json" },
    { nodepath: "Shoes/01072001.img", filename: "shoes01072001.nx.json" },
    { nodepath: "Weapon/01302000.img", filename: "weapon01302000.nx.json" },
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

  const textBitmapGenerator = new TextBitmapGenerator();

  let requestAnimationFrameId = null;

  let halt = false;
  let game_update = null;

  const importObject = {
    gl: {
      flush: (triangles) => {
        // Tell WebGL how to convert from clip space to pixels
        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

        // Clear the canvas
        gl.clearColor(1, 1, 1, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);
        // Tell it to use our program (pair of shaders)
        gl.useProgram(program);
        // Bind the attribute/buffer set we want.
        gl.bindVertexArray(vao);

        gl.uniform1i(textureLocation, 0);
        // Pass in the canvas resolution so we can convert from
        // pixels to clipspace in the shader
        gl.uniform2f(
          screensizeUniformLocation,
          gl.canvas.width,
          gl.canvas.height
        );
        gl.uniform2f(atlassizeUniformLocation, ATLASW, ATLASH);

        gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
        gl.bufferData(gl.ARRAY_BUFFER, triangles, gl.STREAM_DRAW);
        gl.drawArrays(gl.TRIANGLES, 0, triangles.byteLength / bytesOfVertex);

        // gl.bindVertexArray(null);
      },
      texSubImage2D: (x, y, bmp) => {
        if (bmp.w === 0 || bmp.h === 0) {
          return;
        }
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texSubImage2D(
          gl.TEXTURE_2D,
          0,
          x,
          y,
          bmp.w,
          bmp.h,
          gl.RGBA,
          gl.UNSIGNED_BYTE,
          bmp.data
        );
      },
    },
    vertices: {
      new: (length) => {
        return new ArrayBuffer(length * bytesOfVertex);
      },
      set: (
        buffer,
        i,
        localcoord_x,
        localcoord_y,
        texcoord_x,
        texcoord_y,
        color_r,
        color_g,
        color_b,
        color_a
      ) => {
        const positions = new Int16Array(buffer, i * bytesOfVertex);
        positions[0] = localcoord_x;
        positions[1] = localcoord_y;
        positions[2] = texcoord_x;
        positions[3] = texcoord_y;
        const colors = new Float32Array(
          buffer,
          i * bytesOfVertex + bytesOfCoord
        );
        colors[0] = color_r;
        colors[1] = color_g;
        colors[2] = color_b;
        colors[3] = color_a;
      },
    },
    text: {
      create_image: textBitmapGenerator.createImage.bind(textBitmapGenerator)
    },
    resource: {
      get_loader: (name) => {
        switch (name) {
          case "ui":
            return uiLoader;
          case "map":
            return mapLoader;
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
          default:
            throw new Error(`Unknown resource loader: ${name}`);
        }
      },
      load_bitmap: (loader, bid) => loader.bmpLoader.loadBitmap(bid),
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
      is_connected: (socket) => socket.isConnected(),
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
