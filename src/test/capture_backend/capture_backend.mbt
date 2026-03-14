///|
fn normalize_asset_path(path : String) -> String {
  let path = path.strip_prefix("/").unwrap_or(path)
  let path = path.strip_prefix("assets/").unwrap_or(path)
  "assets/\{path}"
}

///|
fn load_image(path : String) -> @capture_app.Image {
  let full_path = normalize_asset_path(path)
  let img_bytes = @fs.read_file_to_bytes(full_path) catch { _ => panic() }
  let img = @capture_app.create_image()
  img.set_src(@capture_app.Buffer::from_bytes(img_bytes))
  img
}

///|
fn color_to_css(color : @render.Color) -> String {
  "rgba(\{color.r.reinterpret_as_int()}, \{color.g.reinterpret_as_int()}, \{color.b.reinterpret_as_int()}, \{color.a})"
}

///|
fn font_to_css(style : @render2d_types.TextStyle2D) -> String {
  "\{style.size}px \{style.family}"
}

///|
fn align_to_css(align : @math.HAlign) -> String {
  match align {
    Left => "left"
    Center => "center"
    Right => "right"
  }
}

///|
fn baseline_to_css(baseline : @math.VAlign) -> String {
  match baseline {
    Top => "top"
    Center => "middle"
    Bottom => "bottom"
  }
}

///|
fn render_image(command : @render2d_types.ImageDrawCommand2D) -> Unit {
  guard @asset.image_path(command.image) is Some(path) else { return }
  let ctx = @capture_app.get_ctx().unwrap()
  let img = load_image(path)
  let src = match command.source {
    Some(src) => src
    None =>
      {
        position: @math.Vec2D(0.0, 0.0),
        size: @math.Vec2D(img.width(), img.height()),
      }
  }
  let dest_pos = command.destination.position
  let dest_size = command.destination.size
  ctx.save()
  ctx.set_global_alpha(command.color.a)
  ctx.translate(dest_pos.0, dest_pos.1)
  ctx.transform(
    command.transform.a,
    command.transform.b,
    command.transform.c,
    command.transform.d,
    command.transform.tx,
    command.transform.ty,
  )
  if command.repeat is NoRepeat {
    ctx.draw_image(
      img,
      src.position.0,
      src.position.1,
      src.size.0,
      src.size.1,
      0.0,
      0.0,
      dest_size.0,
      dest_size.1,
    )
  } else {
    let repeat_x = command.repeat is Repeat || command.repeat is RepeatX
    let repeat_y = command.repeat is Repeat || command.repeat is RepeatY
    let tile_w = src.size.0
    let tile_h = src.size.1
    let span_x = if repeat_x {
      dest_size.0
    } else {
      @cmp.minimum(dest_size.0, tile_w)
    }
    let span_y = if repeat_y {
      dest_size.1
    } else {
      @cmp.minimum(dest_size.1, tile_h)
    }
    let mut ox = 0.0
    while ox < span_x {
      let mut oy = 0.0
      while oy < span_y {
        let x1 = @cmp.minimum(ox + tile_w, span_x)
        let y1 = @cmp.minimum(oy + tile_h, span_y)
        let local_w = x1 - ox
        let local_h = y1 - oy
        ctx.draw_image(
          img,
          src.position.0,
          src.position.1,
          local_w,
          local_h,
          ox,
          oy,
          local_w,
          local_h,
        )
        oy += tile_h
      }
      ox += tile_w
    }
  }
  ctx.restore()
}

///|
fn render_text(command : @render2d_types.TextDrawCommand2D) -> Unit {
  let ctx = @capture_app.get_ctx().unwrap()
  ctx.save()
  ctx.set_fill_style(color_to_css(command.style.color))
  ctx.set_global_alpha(command.style.color.a)
  ctx.set_font(font_to_css(command.style))
  ctx.set_text_align(align_to_css(command.style.align))
  ctx.set_text_baseline(baseline_to_css(command.style.baseline))
  ctx.fill_text(command.text, command.position.0, command.position.1)
  ctx.restore()
}

///|
fn render_rect(command : @render2d_types.RectDrawCommand2D) -> Unit {
  let ctx = @capture_app.get_ctx().unwrap()
  let rect = command.rect
  ctx.save()
  ctx.set_fill_style(color_to_css(command.fill_color))
  ctx.set_global_alpha(command.fill_color.a)
  ctx.fill_rect(rect.position.0, rect.position.1, rect.size.0, rect.size.1)
  match command.stroke_color {
    Some(color) => {
      ctx.set_stroke_style(color_to_css(color))
      ctx.stroke_rect(
        rect.position.0,
        rect.position.1,
        rect.size.0,
        rect.size.1,
      )
    }
    None => ()
  }
  ctx.restore()
}

///|
fn render_commands(commands : Array[@render2d_types.DrawCommand2D]) -> Unit {
  for command in commands {
    match command {
      Image(image) => render_image(image)
      Text(text) => render_text(text)
      Rect(rect) => render_rect(rect)
      Circle(_) => ()
      GradientRect(_) => ()
    }
  }
}

///|
pub fn submit_frame(frame : @render_pipeline.RenderFrame) -> Unit {
  render_commands(frame.frame2d.world_commands)
  render_commands(frame.frame2d.overlay_commands)
}

///|
pub fn register_font(family : String, path : String) -> Unit {
  ignore(family)
  ignore(path)
}

///|
pub fn measure_text(
  style : @render2d_types.TextStyle2D,
  text : String,
) -> @math.Vec2D {
  let width = text.length().to_double() * style.size * 0.6
  let height = style.size
  @math.Vec2D(width, height)
}

///|
pub fn capability_warning(feature : String, fallback : String) -> Unit {
  ignore(feature)
  ignore(fallback)
}
