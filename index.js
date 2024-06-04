"use strict";
const vertexShaderSource = `#version 300 es
precision highp float;
// an attribute is an input (in) to a vertex shader.
// It will receive data from a buffer
in vec2 a_position;
in vec2 a_texcoord;
// Used to pass in the resolution of the canvas
uniform vec2 u_resolution;
// a varying to pass the texture coordinates to the fragment shader
out vec2 v_texcoord;
void main(void)
{
  // convert the position from pixels to 0.0 to 1.0
  vec2 zeroToOne = a_position / u_resolution;

  // convert from 0->1 to 0->2
  vec2 zeroToTwo = zeroToOne * 2.0;

  // convert from 0->2 to -1->+1 (clipspace)
  vec2 clipSpace = zeroToTwo - 1.0;

  gl_Position = vec4(clipSpace * vec2(1, -1), 0, 1);
  // Pass the texcoord to the fragment shader.
  v_texcoord = a_texcoord;
}
`;
const fragmentShaderSource = `#version 300 es
precision highp float;
// Passed in from the vertex shader.
in vec2 v_texcoord;
// The texture.
uniform sampler2D u_texture;
out vec4 FragColor;

void main(void)
{
  FragColor = texture(u_texture, v_texcoord);
}
`;
function main() {
  const canvas = document.getElementById("canvas");
  const gl = canvas.getContext("webgl2");
  if (!gl) {
    throw new Error("WebGL not supported");
  }
  const VWIDTH = 1366;
  const VHEIGHT = 768;

  canvas.width = VWIDTH;
  canvas.height = VHEIGHT;
  // Set image to left top, multiplied by phone (screensize y / 384), screen resolution is 1366 * 768
  const program = webglUtils.createProgramFromSources(gl, [
    vertexShaderSource,
    fragmentShaderSource,
  ]);

  // look up where the vertex data needs to go.
  const positionAttributeLocation = gl.getAttribLocation(program, "a_position");
  const texcoordAttributeLocation = gl.getAttribLocation(program, "a_texcoord");
  // look up uniform locations
  const resolutionUniformLocation = gl.getUniformLocation(
    program,
    "u_resolution"
  );

  // Vertex Buffer Object
  const VBO = gl.createBuffer();
  // Create a vertex array object (attribute state)
  var vao = gl.createVertexArray();
  // and make it the one we're currently working with
  gl.bindVertexArray(vao);
  // Turn on the attribute
  gl.enableVertexAttribArray(positionAttributeLocation);
  gl.enableVertexAttribArray(texcoordAttributeLocation);

  gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
  const bytes_of_vertex = 2 * 2 + 2 * 4;
  gl.vertexAttribPointer(
    positionAttributeLocation,
    2,
    gl.SHORT,
    false,
    bytes_of_vertex,
    0
  );
  gl.vertexAttribPointer(
    texcoordAttributeLocation,
    2,
    gl.FLOAT,
    false,
    bytes_of_vertex,
    4
  );

  // Create a texture.
  const texture = gl.createTexture();
  // use texture unit 0
  gl.activeTexture(gl.TEXTURE0 + 0);
  // bind to the TEXTURE_2D bind point of texture unit 0
  gl.bindTexture(gl.TEXTURE_2D, texture);
  // Fill the texture with a 1x1 blue pixel.
  gl.texImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    1,
    1,
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    new Uint8Array([0, 0, 255, 255])
  );
  //   gl.bindVertexArray(null);

  // Asynchronously load an image
  const cursor_img = new Image();
  cursor_img.src = "nx/files/raw/Basic.img/Cursor/0/0.png";
  cursor_img.addEventListener("load", function () {
    // Now that the image has loaded make copy it to the texture.
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RGBA,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      cursor_img
    );
    gl.generateMipmap(gl.TEXTURE_2D);
  });

  let requestAnimationFrameId = null;
  let lastTime = 0;
  let dropCounter = 0;
  let dropInterval = 10;

  let halt = false;
  let game_win = null;
  let game_lose = null;
  let game_update = null;
  let keydown_up = null;
  let keydown_down = null;
  let keydown_left = null;
  let keydown_right = null;
  let keydown_B = null;
  let keyup_up = null;
  let keyup_down = null;
  let keyup_left = null;
  let keyup_right = null;
  let onmousemove = null;

  // window.addEventListener("keydown", (e) => {
  //   if (halt && e.keyCode === 32) {
  //     halt = false;
  //     start();
  //     return;
  //   }

  //   if (!requestAnimationFrameId) return;
  //   switch (e.keyCode) {
  //     case 37:
  //     case 65:
  //       keydown_left();
  //       break;
  //     case 39:
  //     case 68:
  //       keydown_right();
  //       break;
  //     case 32:
  //     case 38:
  //     case 87:
  //       keydown_up();
  //       break;
  //     case 40:
  //     case 83:
  //       keydown_down();
  //       break;
  //     case 66:
  //       keydown_B();
  //   }
  // });

  // window.addEventListener("keyup", (e) => {
  //   if (!requestAnimationFrameId) return;
  //   switch (e.keyCode) {
  //     case 37:
  //     case 65:
  //       keyup_left();
  //       break;
  //     case 39:
  //     case 68:
  //       keyup_right();
  //       break;
  //     case 32:
  //     case 38:
  //     case 87:
  //       keyup_up();
  //       break;
  //     case 40:
  //     case 83:
  //       keyup_down();
  //       break;
  //     case 66:
  //       keyup_B();
  //   }
  // });
  canvas.onmousemove = (evt) => {
    // var rect = canvas.getBoundingClientRect();
    // const x = evt.clientX - rect.left;
    // const y = evt.clientY - rect.top;
    const x = evt.offsetX;
    // const y = VHEIGHT - evt.offsetY;
    const y = evt.offsetY;
    onmousemove(x, y);
  };

  const importObject = {
    // canvas: {
    //   render_box: (a, b, c, d) => {
    //     context.strokeStyle = "#FF0000";
    //     context.strokeRect(a, b, c, d);
    //   },
    //   render3: (img, sx, sy) => {
    //     context.drawImage(img, sx, sy);
    //   },
    //   render: (img, sx, sy, sw, sh, dx, dy, dw, dh) => {
    //     context.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh);
    //   },
    //   draw: (
    //     g,
    //     bitmap,
    //     rect_left,
    //     rect_top,
    //     rect_right,
    //     rect_bottom,
    //     color_r,
    //     color_g,
    //     color_b,
    //     color_a,
    //     angle
    //   ) => {},
    // },
    gl: {
      flush: (triangles) => {
        // Tell WebGL how to convert from clip space to pixels
        gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

        // Clear the canvas
        gl.clearColor(0, 0, 0, 0);
        gl.clear(gl.COLOR_BUFFER_BIT);
        // Tell it to use our program (pair of shaders)
        gl.useProgram(program);
        // Bind the attribute/buffer set we want.
        gl.bindVertexArray(vao);

        // Pass in the canvas resolution so we can convert from
        // pixels to clipspace in the shader
        gl.uniform2f(
          resolutionUniformLocation,
          gl.canvas.width,
          gl.canvas.height
        );

        gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
        gl.bufferData(gl.ARRAY_BUFFER, triangles, gl.STREAM_DRAW);
        gl.drawArrays(gl.TRIANGLES, 0, triangles.byteLength / bytes_of_vertex);

        // gl.bindVertexArray(null);
      },
    },
    vertices: {
      new: (length) => {
        return new ArrayBuffer(length * bytes_of_vertex);
      },
      set: (
        buffer,
        i,
        localcoord_x,
        localcoord_y,
        texcoord_x,
        texcoord_y
        // color_r,
        // color_g,
        // color_b,
        // color_a
      ) => {
        const positions = new Int16Array(buffer, i * bytes_of_vertex);
        positions[0] = localcoord_x;
        positions[1] = localcoord_y;
        const texcoords = new Float32Array(buffer, i * bytes_of_vertex + 2 * 2);
        texcoords[0] = texcoord_x;
        texcoords[1] = texcoord_y;
      },
    },
    resource: {
      load_idle_cursor: () => {
        return cursor_img;
        // return {
        //   width: 32,
        //   height: 32,
        // };
      },
    },
    bitmap: {
      width: (bmp) => {
        return bmp.width;
      },
      height: (bmp) => {
        return bmp.height;
      },
    },
    spectest: {
      print_i32: (x) => console.log(String(x)),
      print_f64: (x) => console.log(String(x)),
      print_char: (x) => console.log(String.fromCharCode(x)),
    },
  };

  function update(time = 0) {
    game_update(time);
    if (!halt) {
      requestAnimationFrameId = requestAnimationFrame(update);
    }
  }

  function start() {
    Object.assign(globalThis, importObject);
    //   WebAssembly.instantiateStreaming(
    //     fetch("target/wasm-gc/release/build/lib/lib.wasm"),
    //     importObject
    //   ).then((obj) => {
    //     obj.instance.exports._start();
    //     // game_win = obj.instance.exports["mario/main::game_win"];
    //     // game_lose = obj.instance.exports["mario/main::game_lose"];
    //     // game_update = obj.instance.exports["game_update"];
    //     // keydown_up = obj.instance.exports["mario/main::keydown_up"];
    //     // keydown_down = obj.instance.exports["mario/main::keydown_down"];
    //     // keydown_left = obj.instance.exports["mario/main::keydown_left"];
    //     // keydown_right = obj.instance.exports["mario/main::keydown_right"];
    //     // keydown_B = obj.instance.exports["mario/main::keydown_B"];
    //     // keyup_up = obj.instance.exports["mario/main::keyup_up"];
    //     // keyup_down = obj.instance.exports["mario/main::keyup_down"];
    //     // keyup_left = obj.instance.exports["mario/main::keyup_left"];
    //     // keyup_right = obj.instance.exports["mario/main::keyup_right"];
    // requestAnimationFrameId = requestAnimationFrame(update);
    //   });
    import("./target/js/release/build/lib/lib.js").then((m) => {
      game_update = m.game_update;
      onmousemove = m.onmousemove;
      requestAnimationFrameId = requestAnimationFrame(update);
    });
  }
  start();
}
main();
