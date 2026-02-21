///|
priv struct CaptureBackend {
  mut canvas_width : Double
  mut canvas_height : Double
  mut zoom : Double
}

///|
let default_backend : CaptureBackend = {
  canvas_width: 32,
  canvas_height: 32,
  zoom: 1.0,
}

///|

///|
pub fn initialize(
  startup~ : () -> Unit,
  render_loop~ : (Double) -> Unit,
  game_loop~ : (Double) -> Unit,
  canvas_width~ : Double,
  canvas_height~ : Double,
  fps~ : UInt,
  image_smooth~ : Bool,
  zoom~ : Double,
) -> () -> Unit {
  // Canvas is already initialized by init_app before App::run() is called
  // Just store the dimensions for get_canvas_size()
  ignore(startup)
  ignore(render_loop)
  ignore(game_loop)
  ignore(fps)
  ignore(image_smooth)
  default_backend.canvas_width = canvas_width
  default_backend.canvas_height = canvas_height
  default_backend.zoom = zoom
  fn() {  }
}

///|
pub fn draw_picture(
  png~ : String,
  x~ : Double,
  y~ : Double,
  width~ : Double,
  height~ : Double,
  transform~ : @math.Transform,
  repeat~ : @math.RepeatMode,
) -> Unit {
  ignore(repeat)
  let ctx = @capture_app.get_ctx().unwrap()
  // tolerate relative path
  let png = png.strip_prefix("/").unwrap_or(png)
  let png = png.strip_prefix("assets/").unwrap_or(png)
  let png = "assets/\{png}"
  let img_bytes = @fs.read_file_to_bytes(png) catch {
    e => {
      @log.error("Failed to load picture", data={ "error": e })
      panic()
    }
  }
  let img = @capture_app.create_image()
  img.set_src(@capture_app.Buffer::from_bytes(img_bytes))

  ctx.save()
  // Keep the same transform order as draw_sprite.
  ctx.translate(x, y)
  ctx.transform(
    transform.a,
    transform.b,
    transform.c,
    transform.d,
    transform.tx,
    transform.ty,
  )
  ctx.draw_image(
    img,
    0.0,
    0.0,
    width,
    height,
    0.0,
    0.0,
    width,
    height,
  )
  ctx.restore()
}

///|
pub fn draw_sprite(
  sprite_path~ : String,
  x~ : Double,
  y~ : Double,
  offset_x~ : Double,
  offset_y~ : Double,
  width~ : Double,
  height~ : Double,
  transform~ : @math.Transform,
  alpha~ : Double,
) -> Unit {
  ignore(alpha)
  let ctx = @capture_app.get_ctx().unwrap()
  // tolerate relative path
  let sprite_path = sprite_path.strip_prefix("/").unwrap_or(sprite_path)
  let sprite_path = sprite_path.strip_prefix("assets/").unwrap_or(sprite_path)
  let sprite_path = "assets/\{sprite_path}"
  let img_bytes = @fs.read_file_to_bytes(sprite_path) catch {
    e => {
      @log.error("Failed to load sprite", data={ "error": e })
      panic()
    }
  }
  let img = @capture_app.create_image()
  img.set_src(@capture_app.Buffer::from_bytes(img_bytes))
  ctx.save()

  // Transform logic: 
  // 1. Move to drawing position
  ctx.translate(x, y)
  // 2. Apply the sprite's transform matrix
  ctx.transform(
    transform.a,
    transform.b,
    transform.c,
    transform.d,
    transform.tx,
    transform.ty,
  )

  // Draw using source rectangle from spritesheet
  ctx.draw_image(
    img, offset_x, offset_y, width, height, 0.0, 0.0, width, height,
  )
  ctx.restore()
}

///|
pub fn register_key_events(pressed_keys : Set[@inputs.Code]) -> Unit {
  ignore(pressed_keys)
}

///|
pub fn register_mouse_events(
  mouse : @inputs.Mouse,
  mouse_movement : @inputs.MouseMovement,
) -> Unit {
  ignore(mouse)
  ignore(mouse_movement)
}

///|
pub fn lock_mouse(locked : Ref[Bool]) -> Unit {
  ignore(locked)
}

///|
pub fn draw_text(
  text~ : String,
  x~ : Double,
  y~ : Double,
  font~ : String,
  color~ : String,
  align~ : @math.HAlign,
  baseline~ : @math.VAlign,
) -> Unit {
  let ctx = @capture_app.get_ctx().unwrap()
  ctx.save()
  ctx.set_fill_style(color)
  ctx.set_font(font)
  let align_value = match align {
    @math.HAlign::Left => "left"
    @math.HAlign::Center => "center"
    @math.HAlign::Right => "right"
  }
  let baseline_value = match baseline {
    @math.VAlign::Top => "top"
    @math.VAlign::Center => "center"
    @math.VAlign::Bottom => "bottom"
  }
  ctx.set_text_align(align_value)
  ctx.set_text_baseline(baseline_value)
  ctx.fill_text(text, x, y)
  ctx.restore()
}

///|
pub fn draw_color_rect(
  x~ : Double,
  y~ : Double,
  width~ : Double,
  height~ : Double,
  color~ : String,
  stroke_color~ : String,
) -> Unit {
  let ctx = @capture_app.get_ctx().unwrap()
  ctx.save()
  ctx.set_fill_style(color)
  ctx.fill_rect(x, y, width, height)
  if stroke_color != "" {
    ctx.set_stroke_style(stroke_color)
    ctx.stroke_rect(x, y, width, height)
  }
  ctx.restore()
}

///|
pub fn draw_color_circle(
  x~ : Double,
  y~ : Double,
  radius~ : Double,
  color~ : String,
  stroke_color~ : String,
) -> Unit {
  ignore(x)
  ignore(y)
  ignore(radius)
  ignore(color)
  ignore(stroke_color)
}

///|
pub fn draw_gradient_rect(
  x~ : Double,
  y~ : Double,
  width~ : Double,
  height~ : Double,
  color_start~ : String,
  color_end~ : String,
) -> Unit {
  ignore(x)
  ignore(y)
  ignore(width)
  ignore(height)
  ignore(color_start)
  ignore(color_end)
}

///|
pub fn play_audio(
  audio_path~ : String,
  volume~ : Double,
  loop_~ : Bool,
) -> Unit {
  ignore(audio_path)
  ignore(volume)
  ignore(loop_)
}

///|
pub fn get_canvas_size() -> @math.Vec2D {
  Vec2D(default_backend.canvas_width, default_backend.canvas_height)
}

///|
pub fn get_zoom() -> Double {
  default_backend.zoom
}

///|
pub fn preload_img(path : String) -> Unit {
  ignore(path)
}

///|
pub fn preload_audio(path : String) -> Unit {
  ignore(path)
}

///|
pub fn set_time_scale(scale : Double) -> Unit {
  ignore(scale)
}

///|
pub fn load_font(font : String, path : String) -> Unit {
  ignore(font)
  ignore(path)
}

///|
pub fn get_realtime_delta() -> Double {
  0.016
}

///|
pub fn get_time_scale() -> Double {
  1.0
}

// FFI Bindings removed (moved to capture_canvas)
