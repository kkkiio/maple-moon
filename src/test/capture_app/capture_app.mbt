///|
pub type Canvas

///|
pub type Context2D

///|
pub type Image

///|

///|
priv struct GlobalState {
  mut canvas : Canvas?
  mut ctx : Context2D?
  mut canvas_width : Double
  mut canvas_height : Double
  mut render_loop : ((Double) -> Unit)?
  mut game_loop : ((Double) -> Unit)?
}

///|
let global_state : GlobalState = {
  canvas: None,
  ctx: None,
  canvas_width: 0.0,
  canvas_height: 0.0,
  render_loop: None,
  game_loop: None,
}

///|
pub fn get_ctx() -> Context2D? {
  global_state.ctx
}

///|
pub fn set_canvas(c : Canvas) -> Unit {
  global_state.canvas = Some(c)
}

///|
pub fn set_ctx(c : Context2D) -> Unit {
  global_state.ctx = Some(c)
}

///|
/// Initialize the test app by extracting systems from App and setting up canvas.
pub fn init_app(app : @system.App) -> Unit {
  // Initialize canvas FIRST (needed by startup systems)
  let canvas = create_canvas(
    app.canvas_width.to_int(),
    app.canvas_height.to_int(),
  )
  let ctx = canvas.get_context("2d")
  ctx.set_image_smoothing_enabled(app.image_smooth)
  ctx.scale(app.zoom, app.zoom)

  // Store canvas in global state (needed by backends)
  global_state.canvas = Some(canvas)
  global_state.ctx = Some(ctx)
  global_state.canvas_width = app.canvas_width
  global_state.canvas_height = app.canvas_height

  // Run plugins FIRST - they add systems to app.systems
  for plugin in app.plugins {
    plugin(app)
  }

  // Run startup systems
  for system in app.systems {
    if system.1 is Startup {
      (system.0)(0)
    }
  }

  // NOW extract render systems (sorted by priority) - after plugins added their systems
  let renders : Array[((Double) -> Unit, Int)] = []
  for system in app.systems {
    if system.1 is Render(pri) {
      renders.push((system.0, pri))
    }
  }
  renders.sort_by_key(fn(system) { -system.1 })
  let render_loop : (Double) -> Unit = fn(delta) {
    for render in renders {
      (render.0)(delta)
    }
  }

  // Extract game loop systems
  let game_loops : Array[(Double) -> Unit] = []
  for system in app.systems {
    if system.1 is Update {
      game_loops.push(system.0)
    }
  }
  let game_loop : (Double) -> Unit = fn(delta) {
    for system in game_loops {
      system(delta)
    }
  }

  // Store loops in global state
  global_state.render_loop = Some(render_loop)
  global_state.game_loop = Some(game_loop)
}

///|
/// Execute one loop iteration: clear canvas, run game loop, run render loop.
pub fn run_loop(delta : Double) -> Unit {
  let ctx = global_state.ctx.unwrap()
  ctx.clear_rect(
    0.0,
    0.0,
    global_state.canvas_width,
    global_state.canvas_height,
  )
  match global_state.game_loop {
    Some(game_loop) => game_loop(delta)
    None => ()
  }
  match global_state.render_loop {
    Some(render_loop) => render_loop(delta)
    None => ()
  }
}

///|
/// Get canvas as PNG buffer.
pub fn to_buffer() -> Buffer {
  global_state.canvas.unwrap().to_buffer("image/png")
}

///|
pub fn snapshot(path : String) -> Unit raise {
  let actual = to_buffer().to_bytes()
  let update_snapshot = @sys.get_env_var("UPDATE_CANVAS_SNAPS") is Some("true")
  if update_snapshot || !@fs.path_exists(path) {
    let dir = @path.Path(path).dirname().to_string()
    @fs.create_dir(dir)
    @fs.write_bytes_to_file(path, actual)
  } else {
    let expected = @fs.read_file_to_bytes(path)
    if actual != expected {
      abort(snapshot_mismatch_msg(path, actual, expected))
    }
  }
}

///|
fn snapshot_mismatch_msg(
  path : String,
  actual : Bytes,
  expected : Bytes,
) -> String {
  if actual.length() != expected.length() {
    return "snapshot mismatch: \{path}, size changed: expected=\{expected.length()}, actual=\{actual.length()}"
  }
  let mut idx = 0
  while idx < actual.length() {
    if actual[idx] != expected[idx] {
      return "snapshot mismatch: \{path}, first diff at byte=\{idx}, expected=\{expected[idx].to_int()}, actual=\{actual[idx].to_int()}"
    }
    idx += 1
  }
  "snapshot mismatch: \{path}"
}

// canvas module

///|
pub extern "js" fn create_canvas(w : Int, h : Int) -> Canvas =
  #|(w, h) => {
  #|  const { createCanvas } = require('canvas'); 
  #|  return createCanvas(w, h);
  #|}

///|
pub extern "js" fn Canvas::get_context(
  self : Canvas,
  type_ : String,
) -> Context2D =
  #|(c, t) => c.getContext(t)

///|
pub extern "js" fn Canvas::to_buffer(self : Canvas, mime : String) -> Buffer =
  #|(c, m) => c.toBuffer(m)

///|
pub extern "js" fn create_image() -> Image =
  #|() => {
  #|  const { Image } = require('canvas');
  #|  return new Image();
  #|}

///|
pub extern "js" fn Image::set_src(self : Image, src : Buffer) -> Unit =
  #|(img, src) => { img.src = src; }

// context methods

///|
pub extern "js" fn Context2D::set_image_smoothing_enabled(
  self : Context2D,
  v : Bool,
) -> Unit =
  #|(ctx, v) => { ctx.imageSmoothingEnabled = v; }

///|
pub extern "js" fn Context2D::scale(
  self : Context2D,
  x : Double,
  y : Double,
) -> Unit =
  #|(ctx, x, y) => { ctx.scale(x, y); }

///|
pub extern "js" fn Context2D::translate(
  self : Context2D,
  x : Double,
  y : Double,
) -> Unit =
  #|(ctx, x, y) => { ctx.translate(x, y); }

///|
pub extern "js" fn Context2D::transform(
  self : Context2D,
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) -> Unit =
  #|(ctx, a, b, c, d, e, f) => { ctx.transform(a, b, c, d, e, f); }

///|
pub extern "js" fn Context2D::save(self : Context2D) -> Unit =
  #|(ctx) => { ctx.save(); }

///|
pub extern "js" fn Context2D::restore(self : Context2D) -> Unit =
  #|(ctx) => { ctx.restore(); }

///|
pub extern "js" fn Context2D::draw_image(
  self : Context2D,
  img : Image,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
) -> Unit =
  #|(ctx, img, sx, sy, sw, sh, dx, dy, dw, dh) => { 
  #|  ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh); 
  #|}

///|
pub type Buffer

///|
pub extern "js" fn Buffer::to_bytes(self : Buffer) -> Bytes =
  #|(buf) => {
  #|  return new Uint8Array(buf);
  #|}

///|
pub extern "js" fn Buffer::from_bytes(bytes : Bytes) -> Buffer =
  #|(bytes) => {
  #|  return Buffer.from(bytes);
  #|}

///|
pub extern "js" fn Context2D::clear_rect(
  self : Context2D,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit =
  #|(ctx, x, y, w, h) => { ctx.clearRect(x, y, w, h); }

///|
pub extern "js" fn Context2D::set_fill_style(
  self : Context2D,
  v : String,
) -> Unit =
  #|(ctx, v) => { ctx.fillStyle = v; }

///|
pub extern "js" fn Context2D::set_stroke_style(
  self : Context2D,
  v : String,
) -> Unit =
  #|(ctx, v) => { ctx.strokeStyle = v; }

///|
pub extern "js" fn Context2D::set_font(self : Context2D, v : String) -> Unit =
  #|(ctx, v) => { ctx.font = v; }

///|
pub extern "js" fn Context2D::set_text_align(
  self : Context2D,
  v : String,
) -> Unit =
  #|(ctx, v) => { ctx.textAlign = v; }

///|
pub extern "js" fn Context2D::set_text_baseline(
  self : Context2D,
  v : String,
) -> Unit =
  #|(ctx, v) => { ctx.textBaseline = v; }

///|
pub extern "js" fn Context2D::fill_text(
  self : Context2D,
  text : String,
  x : Double,
  y : Double,
) -> Unit =
  #|(ctx, text, x, y) => { ctx.fillText(text, x, y); }

///|
pub extern "js" fn Context2D::fill_rect(
  self : Context2D,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit =
  #|(ctx, x, y, w, h) => { ctx.fillRect(x, y, w, h); }

///|
pub extern "js" fn Context2D::stroke_rect(
  self : Context2D,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit =
  #|(ctx, x, y, w, h) => { ctx.strokeRect(x, y, w, h); }
