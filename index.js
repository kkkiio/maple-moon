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

class ResourceLoader {
  constructor(name) {
    this.name = name;
    this.nxJson = null;
  }
  async loadNxJson(path) {
    const response = await fetch(path);
    const json = await response.json();
    this.nxJson = json;
  }
  load(nodepath) {
    let parts = nodepath.split("/");
    return parts.reduce((acc, part) => {
      if (part in acc) return acc[part];
      throw new Error(
        `resolve resource failed, path=${nodepath}, missing part=${part}`
      );
    }, this.nxJson);
  }
}

const bidRegex = /(\d+)\.png/;

class SpriteLoader {
  constructor(i) {
    this.i = i;
    this.bitmaps = {};
  }
  loadSprite(imageFilename) {
    // Asynchronously load an image
    const imageLoad = new Promise((r) => {
      const img = new Image();
      img.onload = () => r(img);
      img.src = imageFilename;
    });
    const jsonFilename =
      imageFilename.substring(0, imageFilename.lastIndexOf(".")) + ".json";
    const spriteJsonFetch = fetch(jsonFilename).then((response) =>
      response.json()
    );
    return Promise.all([imageLoad, spriteJsonFetch]).then(([img, json]) => {
      const canvas = document.createElement("canvas");
      canvas.width = json.meta.size.w;
      canvas.height = json.meta.size.h;
      const ctx = canvas.getContext("2d", {
        willReadFrequently: true,
      });
      ctx.drawImage(img, 0, 0);

      for (const key in json.frames) {
        const frame = json.frames[key].frame;
        const bid = bidRegex.exec(key)[1];
        const data = ctx.getImageData(frame.x, frame.y, frame.w, frame.h);
        this.bitmaps[bid] = {
          id: this.i * 100000 + bid,
          data,
          w: frame.w,
          h: frame.h,
        };
      }
    });
  }
  loadBitmap(bid) {
    const bmp = this.bitmaps[bid];
    if (!bmp) {
      throw new Error(`Bitmap ${bid} not found`);
    }
    return bmp;
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
      id: this.i * 100000 + bid,
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

const VWIDTH = 1366;
const VHEIGHT = 768;
const ATLASW = 8192;
const ATLASH = 8192;
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
    uiLoader.loadNxJson("nx/files/raw/UI.nx/nx.json")
  );

  const uiBmpLoader = new DirectBmpLoader(0, "nx/files/raw/UI.nx/bitmaps");
  uiLoader.bmpLoader = uiBmpLoader;

  const mapLoader = new ResourceLoader("Map.nx");
  prepareResourcePromises.push(
    mapLoader.loadNxJson("nx/files/raw/Map.nx/nx.json")
  );

  const mapBmpLoader = new DirectBmpLoader(1, "nx/files/raw/Map.nx/bitmaps");
  mapLoader.bmpLoader = mapBmpLoader;

  const soundLoader = new ResourceLoader("Sound.nx");
  prepareResourcePromises.push(
    soundLoader.loadNxJson("nx/files/raw/Sound.nx/nx.json")
  );

  const characterLoader = new ResourceLoader("Character.nx");
  prepareResourcePromises.push(
    characterLoader.loadNxJson("nx/files/raw/Character.nx/nx.json")
  );

  const characterBmpLoader = new DirectBmpLoader(
    1,
    "nx/files/raw/Character.nx/bitmaps"
  );
  characterLoader.bmpLoader = characterBmpLoader;

  const stringLoader = new ResourceLoader("String.nx");
  prepareResourcePromises.push(
    stringLoader.loadNxJson("nx/files/raw/String.nx/nx.json")
  );

  let requestAnimationFrameId = null;

  let halt = false;
  let game_win = null;
  let game_lose = null;
  let game_update = null;
  let onkeyup = null;
  let onkeydown = null;
  let onmousemove = null;
  let onmousedown = null;
  let onmouseup = null;

  canvas.addEventListener("keydown", (e) => {
    if (onkeydown) {
      onkeydown(e.code);
    }
  });

  canvas.addEventListener("keyup", (e) => {
    if (onkeyup) {
      onkeyup(e.code);
    }
  });
  canvas.onmousemove = (evt) => {
    const x = evt.offsetX;
    const y = evt.offsetY;
    if (onmousemove) onmousemove(x, y);
  };
  canvas.onmousedown = (evt) => {
    if (onmousedown) onmousedown();
  };
  canvas.onmouseup = (evt) => {
    if (onmouseup) onmouseup();
  };

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
    resource: {
      ui_loader: () => uiLoader,
      map_loader: () => mapLoader,
      sound_loader: () => soundLoader,
      character_loader: () => characterLoader,
      string_loader: () => stringLoader,
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
    spectest: {
      print_i32: (x) => console.log(String(x)),
      print_f64: (x) => console.log(String(x)),
      print_char: (x) => console.log(String.fromCharCode(x)),
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
    .then(() => import("./target/js/release/build/lib/lib.js"))
    .then((m) => {
      game_update = m.game_update;
      onmousemove = m.onmousemove;
      onmousedown = m.onmousedown;
      onmouseup = m.onmouseup;
      onkeydown = m.onkeydown;
      onkeyup = m.onkeyup;
      globalThis.transit_to = m.transit_to;
      globalThis.load_player = m.load_player;
      m.game_start();
      requestAnimationFrameId = requestAnimationFrame(update);
    });
}
main();
