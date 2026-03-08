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
  mut fixed_dt : Double
  mut max_fixed_steps : Int
  mut accumulator : Double
  mut render_loop : ((Double) -> Unit)?
  mut game_loop : ((Double) -> Unit)?
}

///|
let global_state : GlobalState = {
  canvas: None,
  ctx: None,
  canvas_width: 0.0,
  canvas_height: 0.0,
  fixed_dt: 0.0,
  max_fixed_steps: 0,
  accumulator: 0.0,
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
fn set_key(system : @system.RegisteredSystem, index : Int) -> String {
  match system.in_set {
    Some(set) => set.name
    None => "__system_\{index}"
  }
}

///|
fn sort_systems_by_set(
  systems : Array[@system.RegisteredSystem],
) -> Array[@system.RegisteredSystem] {
  if systems.length() <= 1 {
    return systems
  }

  let group_members : Map[String, Array[@system.RegisteredSystem]] = Map::new()
  let group_order : Map[String, Int] = Map::new()
  let group_keys : Array[String] = []

  for index, system in systems {
    let key = set_key(system, index)
    if !group_members.contains(key) {
      group_members.set(key, [])
      group_order.set(key, index)
      group_keys.push(key)
    }
    let members = group_members.get(key).unwrap_or([])
    members.push(system)
    group_members.set(key, members)
  }

  let outgoing : Map[String, @set.Set[String]] = Map::new()
  let indegree : Map[String, Int] = Map::new()
  for key in group_keys {
    outgoing.set(key, @set.Set::new())
    indegree.set(key, 0)
  }

  fn add_edge(
    from : String,
    to : String,
    outgoing : Map[String, @set.Set[String]],
    indegree : Map[String, Int],
  ) -> Unit {
    if from == to {
      return
    }
    if !outgoing.contains(from) || !outgoing.contains(to) {
      return
    }
    guard outgoing.get(from) is Some(edges) else { return }
    if edges.contains(to) {
      return
    }
    edges.add(to)
    indegree.set(to, indegree.get(to).unwrap_or(0) + 1)
  }

  for index, system in systems {
    let current_key = set_key(system, index)
    for target in system.before {
      add_edge(current_key, target.name, outgoing, indegree)
    }
    for source in system.after {
      add_edge(source.name, current_key, outgoing, indegree)
    }
  }

  let sorted_candidates = group_keys.copy()
  sorted_candidates.sort_by(fn(lhs, rhs) {
    group_order.get(lhs).unwrap_or(0) - group_order.get(rhs).unwrap_or(0)
  })

  let processed : @set.Set[String] = @set.Set::new()
  let sorted_keys : Array[String] = []
  while processed.to_array().length() < group_keys.length() {
    let mut progressed = false
    for key in sorted_candidates {
      if processed.contains(key) {
        continue
      }
      if indegree.get(key).unwrap_or(0) != 0 {
        continue
      }
      progressed = true
      processed.add(key)
      sorted_keys.push(key)
      for target in outgoing.get(key).unwrap_or(@set.Set::new()) {
        let degree = indegree.get(target).unwrap_or(0)
        indegree.set(target, if degree > 0 { degree - 1 } else { 0 })
      }
    }
    if progressed {
      continue
    }
    for key in sorted_candidates {
      if !processed.contains(key) {
        processed.add(key)
        sorted_keys.push(key)
      }
    }
  }

  let ordered : Array[@system.RegisteredSystem] = []
  for key in sorted_keys {
    for system in group_members.get(key).unwrap_or([]) {
      ordered.push(system)
    }
  }
  ordered
}

///|
fn collect_systems(
  systems : Array[@system.RegisteredSystem],
  matcher : (@system.Schedule) -> Bool,
) -> Array[@system.RegisteredSystem] {
  let selected : Array[@system.RegisteredSystem] = []
  for system in systems {
    if matcher(system.schedule) {
      selected.push(system)
    }
  }
  sort_systems_by_set(selected)
}

///|
fn should_run(system : @system.RegisteredSystem) -> Bool {
  let schedule_allows = match system.schedule {
    OnEnter(condition) => condition()
    OnExit(condition) => condition()
    _ => true
  }
  if !schedule_allows {
    return false
  }
  match system.run_if {
    Some(condition) => condition()
    None => true
  }
}

///|
fn run_stage(systems : Array[@system.RegisteredSystem], delta : Double) -> Unit {
  for system in systems {
    if should_run(system) {
      (system.system)(delta)
    }
  }
}

///|
/// Initialize the test app by extracting systems from App and setting up canvas.
pub fn init_app(app : @system.App) -> Unit {
  if app.zoom <= 0.0 {
    abort("App::with_zoom must be a positive number")
  }
  if app.fixed_hz == 0U {
    abort("App::with_fixed_hz must be greater than 0")
  }
  if app.max_fixed_steps_per_frame == 0U {
    abort("App::with_max_fixed_steps_per_frame must be greater than 0")
  }
  let canvas = create_canvas(
    (app.viewport_width * app.zoom).to_int(),
    (app.viewport_height * app.zoom).to_int(),
  )
  let ctx = canvas.get_context("2d")
  ctx.set_image_smoothing_enabled(app.image_smooth)
  @system.configure_display(app.viewport_width, app.viewport_height, app.zoom)
  @system.set_render_alpha(1.0)

  global_state.canvas = Some(canvas)
  global_state.ctx = Some(ctx)
  global_state.canvas_width = app.viewport_width * app.zoom
  global_state.canvas_height = app.viewport_height * app.zoom
  global_state.fixed_dt = 1.0 / app.fixed_hz.to_double()
  global_state.max_fixed_steps = app.max_fixed_steps_per_frame.reinterpret_as_int()
  global_state.accumulator = 0.0

  for plugin in app.plugins {
    plugin(app)
  }

  let startup_systems = collect_systems(app.systems, fn(schedule) {
    schedule is Startup
  })
  run_stage(startup_systems, 0.0)

  let frame_first = collect_systems(app.systems, fn(schedule) {
    schedule is First
  })
  let frame_pre = collect_systems(app.systems, fn(schedule) {
    schedule is PreUpdate
  })
  let frame_on_exit = collect_systems(app.systems, fn(schedule) {
    schedule is OnExit(_)
  })
  let frame_on_enter = collect_systems(app.systems, fn(schedule) {
    schedule is OnEnter(_)
  })
  let frame_update = collect_systems(app.systems, fn(schedule) {
    schedule is Update
  })
  let frame_post = collect_systems(app.systems, fn(schedule) {
    schedule is PostUpdate
  })
  let frame_last = collect_systems(app.systems, fn(schedule) {
    schedule is Last
  })
  let fixed_first = collect_systems(app.systems, fn(schedule) {
    schedule is FixedFirst
  })
  let fixed_pre = collect_systems(app.systems, fn(schedule) {
    schedule is FixedPreUpdate
  })
  let fixed_update = collect_systems(app.systems, fn(schedule) {
    schedule is FixedUpdate
  })
  let fixed_post = collect_systems(app.systems, fn(schedule) {
    schedule is FixedPostUpdate
  })
  let fixed_last = collect_systems(app.systems, fn(schedule) {
    schedule is FixedLast
  })
  let render_extract = collect_systems(app.systems, fn(schedule) {
    schedule is RenderExtract
  })
  let render_prepare = collect_systems(app.systems, fn(schedule) {
    schedule is RenderPrepare
  })
  let render_stage = collect_systems(app.systems, fn(schedule) {
    schedule is Render
  })
  let render_cleanup = collect_systems(app.systems, fn(schedule) {
    schedule is RenderCleanup
  })

  let game_loop : (Double) -> Unit = fn(delta) {
    @event.event_frame_update_system(delta)
    run_stage(frame_first, delta)
    run_stage(frame_pre, delta)
    run_stage(frame_on_exit, delta)
    run_stage(frame_on_enter, delta)
    run_stage(frame_update, delta)
    run_stage(frame_post, delta)
    @event.event_observer_dispatch_system(delta)
    run_stage(frame_last, delta)
    @commands.commands_flush_system(delta)
    @entity.entity_flush_system(delta)

    global_state.accumulator += delta
    let mut fixed_steps = 0
    while global_state.accumulator >= global_state.fixed_dt &&
          fixed_steps < global_state.max_fixed_steps {
      @event.event_fixed_update_system(global_state.fixed_dt)
      run_stage(fixed_first, global_state.fixed_dt)
      run_stage(fixed_pre, global_state.fixed_dt)
      run_stage(fixed_update, global_state.fixed_dt)
      run_stage(fixed_post, global_state.fixed_dt)
      run_stage(fixed_last, global_state.fixed_dt)
      @commands.commands_flush_system(global_state.fixed_dt)
      @entity.entity_flush_system(global_state.fixed_dt)
      global_state.accumulator -= global_state.fixed_dt
      fixed_steps += 1
    }
    if fixed_steps >= global_state.max_fixed_steps {
      global_state.accumulator = 0.0
    }
    let alpha = if global_state.fixed_dt <= 0.0 {
      1.0
    } else {
      global_state.accumulator / global_state.fixed_dt
    }
    @system.set_render_alpha(alpha)
  }
  let render_loop : (Double) -> Unit = fn(delta) {
    @event.event_render_update_system(delta)
    run_stage(render_extract, delta)
    run_stage(render_prepare, delta)
    run_stage(render_stage, delta)
    run_stage(render_cleanup, delta)
  }

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

///|
pub extern "js" fn Image::width(self : Image) -> Double =
  #|(img) => img.width

///|
pub extern "js" fn Image::height(self : Image) -> Double =
  #|(img) => img.height

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
pub extern "js" fn Context2D::set_global_alpha(
  self : Context2D,
  v : Double,
) -> Unit =
  #|(ctx, v) => { ctx.globalAlpha = v; }

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
