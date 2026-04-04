///|
/// Supported UI slice layouts encoded in Aseprite JSON slice metadata.
pub(all) enum UiSliceKind {
  NineSlice
  ThreeSliceV
} derive(Eq, Show)

///|
/// Parsed UI slice resource and prepared material handle for rendering.
pub struct UiSliceResource {
  /// Registered material handle that draws the slice frame.
  material : @selene_ui.UiMaterialHandle
  /// Derived slice kind from `bounds + center`.
  kind : UiSliceKind
  /// Source slice width in pixels.
  width : Int
  /// Source slice height in pixels.
  height : Int
  /// Left fixed border size in pixels.
  left : Int
  /// Right fixed border size in pixels.
  right : Int
  /// Top fixed border size in pixels.
  top : Int
  /// Bottom fixed border size in pixels.
  bottom : Int
}

///|
let ui_slice_cache : Map[String, UiSliceResource] = Map::new()

///|
/// Load and cache one UI slice resource from an exported `slice.json`.
pub async fn load_ui_slice_resource(
  loader : @resource.AsyncLoader,
  slice_json_path : String,
) -> UiSliceResource {
  let cache_key = loader.resolve_json_path(slice_json_path)
  match ui_slice_cache.get(cache_key) {
    Some(cached) => cached
    None => {
      let source = loader.load_data(slice_json_path)
      let parsed = parse_ui_slice_json(loader, slice_json_path, source)
      ui_slice_cache.set(cache_key, parsed)
      parsed
    }
  }
}

///|
fn parse_ui_slice_json(
  loader : @resource.AsyncLoader,
  slice_json_path : String,
  source : Json,
) -> UiSliceResource raise {
  guard source
    is {
      "meta": {
        "image": String(image_ref),
        "slices": [
          {
            "keys": [
              {
                "bounds": {
                  "x": Number(bounds_x, ..),
                  "y": Number(bounds_y, ..),
                  "w": Number(bounds_w, ..),
                  "h": Number(bounds_h, ..),
                  ..
                },
                "center": {
                  "x": Number(center_x, ..),
                  "y": Number(center_y, ..),
                  "w": Number(center_w, ..),
                  "h": Number(center_h, ..),
                  ..
                },
                ..
              },
              ..,
            ],
            ..
          },
          ..,
        ],
        ..
      },
      ..
    } else {
    fail(
      "invalid ui slice json: missing meta.image/meta.slices[0].keys[0].bounds+center",
    )
  }

  let bx = bounds_x.to_int()
  let by = bounds_y.to_int()
  let bw = bounds_w.to_int()
  let bh = bounds_h.to_int()
  let cx = center_x.to_int()
  let cy = center_y.to_int()
  let cw = center_w.to_int()
  let ch = center_h.to_int()

  guard bw > 0 && bh > 0 else { fail("invalid ui slice bounds: \{bw}x\{bh}") }
  guard cx >= 0 && cy >= 0 && cw > 0 && ch > 0 else {
    fail("invalid ui slice center: x=\{cx}, y=\{cy}, w=\{cw}, h=\{ch}")
  }
  guard cx + cw <= bw && cy + ch <= bh else {
    fail("invalid ui slice center out of bounds")
  }

  let left = cx
  let right = bw - (cx + cw)
  let top = cy
  let bottom = bh - (cy + ch)
  guard left >= 0 && right >= 0 && top >= 0 && bottom >= 0 else {
    fail("invalid ui slice edges")
  }

  let kind = if left == 0 && right == 0 && top > 0 && bottom > 0 {
    UiSliceKind::ThreeSliceV
  } else {
    UiSliceKind::NineSlice
  }

  let image_path = resolve_meta_image_path(loader, slice_json_path, image_ref)
  let image = loader.load_image(image_path)

  let handle = @selene_ui.register_ui_material_asset(
    @selene_ui.UiMaterialAsset::from_draw(fn(context) {
      let bounds_rect : @selene_math.Rect = {
        position: @selene_math.Vec2D(bx.to_double(), by.to_double()),
        size: @selene_math.Vec2D(bw.to_double(), bh.to_double()),
      }
      let center_rect : @selene_math.Rect = {
        position: @selene_math.Vec2D(cx.to_double(), cy.to_double()),
        size: @selene_math.Vec2D(cw.to_double(), ch.to_double()),
      }
      draw_ui_slice_material(
        image,
        bounds_rect,
        center_rect,
        kind,
        left,
        right,
        top,
        bottom,
        context.rect,
      )
    }),
  )

  { material: handle, kind, width: bw, height: bh, left, right, top, bottom }
}

///|
fn resolve_meta_image_path(
  loader : @resource.AsyncLoader,
  slice_json_path : String,
  image_ref : String,
) -> String {
  if image_ref.has_prefix("/") || image_ref.contains("/") {
    return image_ref
  }
  let base = path_parent(slice_json_path)
  if base == "" {
    loader.resolve_json_path(image_ref)
  } else {
    "\{base}/\{image_ref}"
  }
}

///|
fn path_parent(path : String) -> String {
  js_path_parent(path)
}

///|
extern "js" fn js_path_parent(path : String) -> String =
  #| (path) => {
  #|   const idx = path.lastIndexOf("/")
  #|   if (idx < 0) return ""
  #|   return path.slice(0, idx)
  #| }

///|
fn push_image(
  image : @asset.ImageHandle,
  dst : @selene_math.Rect,
  src : @selene_math.Rect,
) -> Unit {
  if dst.size[@selene_math.X] <= 0.0 || dst.size[@selene_math.Y] <= 0.0 {
    return
  }
  @render2d.push_ui_image({
    image,
    destination: dst,
    source: Some({ position: src.position, size: src.size }),
    transform: @selene_math.Transform::new(),
    repeat: @selene_math.NoRepeat,
    color: @selene_ui.rgba(255, 255, 255, 1.0),
  })
}

///|
fn draw_ui_slice_material(
  image : @asset.ImageHandle,
  bounds : @selene_math.Rect,
  center : @selene_math.Rect,
  kind : UiSliceKind,
  left : Int,
  right : Int,
  top : Int,
  bottom : Int,
  dst : @selene_math.Rect,
) -> Unit {
  let fixed_w = left + right
  let fixed_h = top + bottom
  let dst_w = dst.size[@selene_math.X].to_int()
  let dst_h = dst.size[@selene_math.Y].to_int()
  if dst_w < fixed_w || dst_h < fixed_h {
    panic()
  }

  let bx = bounds.position[@selene_math.X]
  let by = bounds.position[@selene_math.Y]
  let bw = bounds.size[@selene_math.X]
  let bh = bounds.size[@selene_math.Y]
  let cx = center.position[@selene_math.X]
  let cy = center.position[@selene_math.Y]
  let cw = center.size[@selene_math.X]
  let ch = center.size[@selene_math.Y]
  let dx = dst.position[@selene_math.X]
  let dy = dst.position[@selene_math.Y]
  let dw = dst.size[@selene_math.X]
  let dh = dst.size[@selene_math.Y]

  let dst_center_w = dw - left.to_double() - right.to_double()
  let dst_center_h = dh - top.to_double() - bottom.to_double()

  match kind {
    UiSliceKind::ThreeSliceV => {
      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx, dy),
          size: @selene_math.Vec2D(dw, top.to_double()),
        },
        {
          position: @selene_math.Vec2D(bx, by),
          size: @selene_math.Vec2D(bw, top.to_double()),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx, dy + top.to_double()),
          size: @selene_math.Vec2D(dw, dst_center_h),
        },
        {
          position: @selene_math.Vec2D(bx + cx, by + cy),
          size: @selene_math.Vec2D(cw, ch),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx, dy + dh - bottom.to_double()),
          size: @selene_math.Vec2D(dw, bottom.to_double()),
        },
        {
          position: @selene_math.Vec2D(bx, by + bh - bottom.to_double()),
          size: @selene_math.Vec2D(bw, bottom.to_double()),
        },
      )
    }
    UiSliceKind::NineSlice => {
      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx, dy),
          size: @selene_math.Vec2D(left.to_double(), top.to_double()),
        },
        {
          position: @selene_math.Vec2D(bx, by),
          size: @selene_math.Vec2D(left.to_double(), top.to_double()),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx + left.to_double(), dy),
          size: @selene_math.Vec2D(dst_center_w, top.to_double()),
        },
        {
          position: @selene_math.Vec2D(bx + left.to_double(), by),
          size: @selene_math.Vec2D(cw, top.to_double()),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx + dw - right.to_double(), dy),
          size: @selene_math.Vec2D(right.to_double(), top.to_double()),
        },
        {
          position: @selene_math.Vec2D(bx + bw - right.to_double(), by),
          size: @selene_math.Vec2D(right.to_double(), top.to_double()),
        },
      )

      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx, dy + top.to_double()),
          size: @selene_math.Vec2D(left.to_double(), dst_center_h),
        },
        {
          position: @selene_math.Vec2D(bx, by + top.to_double()),
          size: @selene_math.Vec2D(left.to_double(), ch),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(
            dx + left.to_double(),
            dy + top.to_double(),
          ),
          size: @selene_math.Vec2D(dst_center_w, dst_center_h),
        },
        {
          position: @selene_math.Vec2D(bx + cx, by + cy),
          size: @selene_math.Vec2D(cw, ch),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(
            dx + dw - right.to_double(),
            dy + top.to_double(),
          ),
          size: @selene_math.Vec2D(right.to_double(), dst_center_h),
        },
        {
          position: @selene_math.Vec2D(
            bx + bw - right.to_double(),
            by + top.to_double(),
          ),
          size: @selene_math.Vec2D(right.to_double(), ch),
        },
      )

      push_image(
        image,
        {
          position: @selene_math.Vec2D(dx, dy + dh - bottom.to_double()),
          size: @selene_math.Vec2D(left.to_double(), bottom.to_double()),
        },
        {
          position: @selene_math.Vec2D(bx, by + bh - bottom.to_double()),
          size: @selene_math.Vec2D(left.to_double(), bottom.to_double()),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(
            dx + left.to_double(),
            dy + dh - bottom.to_double(),
          ),
          size: @selene_math.Vec2D(dst_center_w, bottom.to_double()),
        },
        {
          position: @selene_math.Vec2D(
            bx + left.to_double(),
            by + bh - bottom.to_double(),
          ),
          size: @selene_math.Vec2D(cw, bottom.to_double()),
        },
      )
      push_image(
        image,
        {
          position: @selene_math.Vec2D(
            dx + dw - right.to_double(),
            dy + dh - bottom.to_double(),
          ),
          size: @selene_math.Vec2D(right.to_double(), bottom.to_double()),
        },
        {
          position: @selene_math.Vec2D(
            bx + bw - right.to_double(),
            by + bh - bottom.to_double(),
          ),
          size: @selene_math.Vec2D(right.to_double(), bottom.to_double()),
        },
      )
    }
  }
}
