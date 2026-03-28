///|
using @struct {type Point}

///|
/// Resources needed for the MiniMap UI (display only, normal mode).
/// Contains parsed graphical assets for markers and the background canvas.
pub struct MiniMapUIResource {
  /// Marker for portals.
  portal_marker : @resource.NxTexture
  // Window frame elements for Normal mode
  // minmap_middle_center : @graphics.Animation
  minmap_middle_left : @resource.NxTexture
  minmap_middle_right : @resource.NxTexture
  minmap_up_center : @resource.NxTexture
  minmap_up_left : @resource.NxTexture
  minmap_up_right : @resource.NxTexture
  minmap_down_center : @resource.NxTexture
  minmap_down_left : @resource.NxTexture
  minmap_down_right : @resource.NxTexture
}

///|
/// Loads the necessary graphical resources for displaying the MiniMap UI.
pub async fn MiniMapUIResource::load() -> MiniMapUIResource {
  let mini_map_json : Json = @resource.get_async_loader("ui_window_2").load_resource([
      "MiniMap",
    ],
  ) catch {
    e => {
      @log.error("failed to load UIWindow2 MiniMap resource", data={
        "error": e,
      })
      panic()
    }
  }
  let map_helper_minimap_json : Json = @resource.get_async_loader("map_latest").load_resource([
      "MapHelper.img", "minimap",
    ],
  ) catch {
    e => {
      @log.error("failed to load MapHelper minimap resource", data={
        "error": e,
      })
      panic()
    }
  }
  mini_map_ui_resource_from_json(mini_map_json, map_helper_minimap_json)
}

///|
fn mini_map_ui_resource_from_json(
  mini_map_json : Json,
  map_helper_minimap_json : Json,
) -> MiniMapUIResource {
  try {
    let nx_mini_map_ui : NxMiniMapUI = @json.from_json(mini_map_json)
    let map_helper_minimap : NxMapHelperMiniMap = @json.from_json(
      map_helper_minimap_json,
    )
    let minmap_middle_left = nx_mini_map_ui.min_map.w
    let minmap_middle_right = nx_mini_map_ui.min_map.e
    let minmap_up_center = nx_mini_map_ui.min_map.n
    let minmap_up_left = nx_mini_map_ui.min_map.nw
    let minmap_up_right = nx_mini_map_ui.min_map.ne
    let minmap_down_center = nx_mini_map_ui.min_map.s
    let minmap_down_left = nx_mini_map_ui.min_map.sw
    let minmap_down_right = nx_mini_map_ui.min_map.se
    let portal_marker = first_frame_texture(map_helper_minimap.portal)
    {
      portal_marker,
      // minmap_middle_center,
      minmap_middle_left,
      minmap_middle_right,
      minmap_up_center,
      minmap_up_left,
      minmap_up_right,
      minmap_down_center,
      minmap_down_left,
      minmap_down_right,
    }
  } catch {
    e => {
      @log.error("error loading mini map ui resource", data={ "error": e })
      panic()
    }
  }
}

///|
fn first_frame_texture(
  animation : @resource.NxAnimation,
) -> @resource.NxTexture {
  if animation.frames.is_empty() {
    panic()
  }
  animation.frames[0].texture
}

///|
struct NxMiniMapFrames {
  w : @resource.NxTexture
  e : @resource.NxTexture
  n : @resource.NxTexture
  nw : @resource.NxTexture
  ne : @resource.NxTexture
  s : @resource.NxTexture
  sw : @resource.NxTexture
  se : @resource.NxTexture
}

///|
pub impl @json.FromJson for NxMiniMapFrames with from_json(json, path) -> NxMiniMapFrames raise @json.JsonDecodeError {
  match json {
    {
      "w": w,
      "e": e,
      "n": n,
      "nw": nw,
      "ne": ne,
      "s": s,
      "sw": sw,
      "se": se,
      ..
    } =>
      {
        w: @json.from_json(w, path=path.add_key("w")),
        e: @json.from_json(e, path=path.add_key("e")),
        n: @json.from_json(n, path=path.add_key("n")),
        nw: @json.from_json(nw, path=path.add_key("nw")),
        ne: @json.from_json(ne, path=path.add_key("ne")),
        s: @json.from_json(s, path=path.add_key("s")),
        sw: @json.from_json(sw, path=path.add_key("sw")),
        se: @json.from_json(se, path=path.add_key("se")),
      }
    _ =>
      raise @json.JsonDecodeError(
        (path, "invalid nx mini map frames: missing one of w/e/n/nw/ne/s/sw/se"),
      )
  }
}

///|
struct NxMiniMapUI {
  min_map : NxMiniMapFrames
}

///|
pub impl @json.FromJson for NxMiniMapUI with from_json(json, path) -> NxMiniMapUI raise @json.JsonDecodeError {
  match json {
    { "MinMap": min_map_json, .. } =>
      { min_map: @json.from_json(min_map_json, path=path.add_key("MinMap")) }
    _ => raise @json.JsonDecodeError((path, "missing field MinMap"))
  }
}

///|
struct NxMapHelperMiniMap {
  portal : @resource.NxAnimation
}

///|
pub impl @json.FromJson for NxMapHelperMiniMap with from_json(json, path) -> NxMapHelperMiniMap raise @json.JsonDecodeError {
  match json {
    { "portal": portal, "user": _, "npc": _, "another": _, .. } =>
      { portal: @json.from_json(portal, path=path.add_key("portal")) }
    _ =>
      raise @json.JsonDecodeError(
        (path, "missing one of required fields: portal/user/npc/another"),
      )
  }
}

///|
pub enum MiniMapType {
  // MIN
  NORMAL
  // MAX
}

///|
/// Represents the state and logic for the MiniMap UI widget.
pub struct MiniMapUI {
  resource : MiniMapUIResource
  type_ : MiniMapType
  entities : Array[@entity.Entity]
  ui_model : @ui.UIModel
  mut region_name : String
  mut town_name : String
}

///|
pub fn MiniMapUI::new(
  resource : MiniMapUIResource,
  ui_model : @ui.UIModel,
) -> MiniMapUI {
  ui_model.position = @struct.Point::new(0, 0)
  ui_model.dimension = @struct.Point::new(0, 0)
  {
    resource,
    type_: MiniMapType::NORMAL, // NORMAL by default
    entities: [],
    ui_model,
    region_name: "",
    town_name: "",
  }
}

///|
pub fn MiniMapUI::set_map(
  self : MiniMapUI,
  _map_id : Int,
  map_name : String,
  street_name : String,
  mini_map_resources : @map.MiniMapRuntimeResource?,
) -> Unit {
  self.region_name = map_name
  self.town_name = street_name
  clear_entities(self)
  match self.type_ {
    NORMAL => {
      let map_dimensions = mini_map_resources.map_or(Point::default(), fn(it) {
        @struct.Point::new(
          it.canvas.frames[0].texture.w,
          it.canvas.frames[0].texture.h,
        )
      })
      // 48 (offset for text) + longer text's width + 10 (space for right side
      // border)
      let mark_text_width = 48 +
        @cmp.maximum(
          estimate_minimap_label_width(self.region_name),
          estimate_minimap_label_width(self.town_name),
        ) +
        10
      let window_width = @cmp.maximum(
        178,
        @cmp.maximum(mark_text_width, map_dimensions.x + 20),
      )
      let c_stretch = @cmp.maximum(0, window_width - 128)
      let map_draw_origin_x_ = @cmp.maximum(
        10,
        window_width / 2 - map_dimensions.x / 2,
      )
      let (map_draw_origin_y_, m_stretch, down_y_offset) = if map_dimensions.y <=
        20 {
        let m_stretch = 5
        let down_y_offset = 17 + m_stretch
        (10 + m_stretch - map_dimensions.y, m_stretch, down_y_offset)
      } else {
        let m_stretch = map_dimensions.y - 17
        let down_y_offset = 17 + m_stretch
        (20, m_stretch, down_y_offset)
      }
      let frames : Array[MiniMapFrameDraw] = []
      if mini_map_resources is Some(res) {
        frames.push({
          texture: first_frame_texture(res.canvas),
          x: map_draw_origin_x_,
          y: map_draw_origin_y_,
          z: @graphics.MINI_MAP_ZINDEX_,
        })
      }
      push_repeated_texture_y(
        frames,
        self.resource.minmap_middle_left,
        @graphics.MINI_MAP_ZINDEX_,
        0,
        ML_MR_Y_,
        m_stretch + 1,
      )
      let ur_x_offset = CENTER_START_X_ + c_stretch
      let middle_right_x_ = ur_x_offset + 55
      push_repeated_texture_y(
        frames,
        self.resource.minmap_middle_right,
        @graphics.MINI_MAP_ZINDEX_,
        middle_right_x_,
        ML_MR_Y_,
        m_stretch + 1,
      )
      push_repeated_texture_x(
        frames,
        self.resource.minmap_up_center,
        @graphics.MINI_MAP_ZINDEX_,
        CENTER_START_X_,
        0,
        c_stretch + 1,
      )
      frames.push({
        texture: self.resource.minmap_up_left,
        x: 0,
        y: 0,
        z: @graphics.MINI_MAP_ZINDEX_,
      })
      frames.push({
        texture: self.resource.minmap_up_right,
        x: ur_x_offset,
        y: 0,
        z: @graphics.MINI_MAP_ZINDEX_,
      })
      push_repeated_texture_x(
        frames,
        self.resource.minmap_down_center,
        @graphics.MINI_MAP_ZINDEX_,
        CENTER_START_X_,
        down_y_offset + 18,
        c_stretch + 1,
      )
      frames.push({
        texture: self.resource.minmap_down_left,
        x: 0,
        y: down_y_offset,
        z: @graphics.MINI_MAP_ZINDEX_,
      })
      frames.push({
        texture: self.resource.minmap_down_right,
        x: ur_x_offset,
        y: down_y_offset,
        z: @graphics.MINI_MAP_ZINDEX_,
      })
      for frame in frames {
        spawn_minimap_texture_entity(
          self.entities,
          frame.texture,
          self.ui_model.position,
          frame.x,
          frame.y,
          frame.z,
        )
      }
      let _normal_dimensions = Point::new(ur_x_offset + 64, down_y_offset + 27)
      self.ui_model.dimension = _normal_dimensions
      if mini_map_resources is Some(res) {
        let portals = res.portals
        let marker_offset = @selene_math.Vec2D(
          (self.resource.portal_marker.w / 2).to_double(),
          (self.resource.portal_marker.h / 2).to_double(),
        )
        let marker_pos_offset = @selene_math.Vec2D(0, 65)
        for portal in portals {
          match portal.pt {
            @map.MiniMapPortalType::REGULAR => {
              let marker_pos = (@selene_math.Vec2D(
                  portal.x.to_double(),
                  portal.y.to_double(),
                ) +
                marker_pos_offset +
                @selene_math.Vec2D(
                  res.draw_data.center_x.to_double(),
                  res.draw_data.center_y.to_double(),
                )).scalar_div(res.draw_data.scale.to_double()) -
                marker_offset +
                @selene_math.Vec2D(
                  map_draw_origin_x_.to_double(),
                  map_draw_origin_y_.to_double(),
                )
              spawn_minimap_texture_entity(
                self.entities,
                self.resource.portal_marker,
                self.ui_model.position,
                marker_pos[@selene_math.X].to_int(),
                marker_pos[@selene_math.Y].to_int(),
                @graphics.MINI_MAP_ZINDEX_ + 1,
              )
            }
            _ => ()
          }
        }
      }
    }
  }
}

///|
const CENTER_START_X_ = 64

///|
// const BTN_MIN_Y_ = 4

///|
const ML_MR_Y_ = 17

///|
// const MAX_ADJ_ = 40

///|
// const M_START_ = 36

///|
// const LISTNPC_ITEM_HEIGHT_ = 17

///|
// const LISTNPC_ITEM_WIDTH_ = 140

///|
// const LISTNPC_TEXT_WIDTH_ = 114

///|
priv struct MiniMapFrameDraw {
  texture : @resource.NxTexture
  x : Int
  y : Int
  z : Int
}

///|
fn ui_image_from_texture(texture : @resource.NxTexture) -> @selene_ui.UiImage {
  let source = ui_image_source_from_texture(texture)
  @selene_ui.UiImage::new(
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
    texture.i,
    source=Some(source),
  )
}

///|
fn ui_image_source_from_texture(
  texture : @resource.NxTexture,
) -> @render2d_types.ImageRegion2D {
  {
    position: @selene_math.Vec2D(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    size: @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
  }
}

///|
fn spawn_minimap_texture_entity(
  entities : Array[@entity.Entity],
  texture : @resource.NxTexture,
  ui_pos : @struct.Point[Int],
  local_x : Int,
  local_y : Int,
  z : Int,
) -> Unit {
  let entity = @entity.Entity::new()
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2D(
        (ui_pos.x + local_x - texture.origin.x).to_double(),
        (ui_pos.y + local_y - texture.origin.y).to_double(),
      ),
      size=@selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex::new(z))
  @selene_ui.ui_images().set(entity, ui_image_from_texture(texture))
  entities.push(entity)
}

///|
fn push_repeated_texture_x(
  frames : Array[MiniMapFrameDraw],
  texture : @resource.NxTexture,
  z : Int,
  start_x : Int,
  y : Int,
  count : Int,
) -> Unit {
  for i in 0..<count {
    frames.push({ texture, x: start_x + i, y, z })
  }
}

///|
fn push_repeated_texture_y(
  frames : Array[MiniMapFrameDraw],
  texture : @resource.NxTexture,
  z : Int,
  x : Int,
  start_y : Int,
  count : Int,
) -> Unit {
  for i in 0..<count {
    frames.push({ texture, x, y: start_y + i, z })
  }
}

///|
fn estimate_minimap_label_width(text : String) -> Int {
  // A12B latin glyph width is around 7px in current assets.
  text.length() * 7
}

///|
pub fn set_current_map(
  map_id : Int,
  map_name : String,
  street_name : String,
  mini_map_resources : @map.MiniMapRuntimeResource?,
) -> Unit {
  pending_map.val = Some((map_id, map_name, street_name, mini_map_resources))
}

///|
pub fn clear_current_map() -> Unit {
  pending_map.val = None
  if mini_map_ui_state.val is Some(state) {
    if state.ui is Some(ui) {
      clear_entities(ui)
    }
  }
}

///|
pub fn set_minimap_json_for_test(mini_map_json : Json) -> Unit {
  mini_map_json_override.val = Some(mini_map_json)
  if mini_map_ui_state.val is Some(state) {
    if state.ui is Some(ui) {
      clear_entities(ui)
    }
    state.ui = None
    state.loading = None
  }
}

///|
pub fn set_map_helper_minimap_json_for_test(
  map_helper_minimap_json : Json,
) -> Unit {
  map_helper_minimap_json_override.val = Some(map_helper_minimap_json)
  if mini_map_ui_state.val is Some(state) {
    if state.ui is Some(ui) {
      clear_entities(ui)
    }
    state.ui = None
    state.loading = None
  }
}

///|
priv struct MiniMapUIState {
  mut ui : MiniMapUI?
  mut loading : @utils.Future[Result[MiniMapUIResource, Error]]?
}

///|
let mini_map_ui_state : Ref[MiniMapUIState?] = Ref::new(None)

///|
let pending_map : Ref[(Int, String, String, @map.MiniMapRuntimeResource?)?] = Ref::new(
  None,
)

///|
let mini_map_json_override : Ref[Json?] = Ref::new(None)

///|
let map_helper_minimap_json_override : Ref[Json?] = Ref::new(None)

///|
fn ensure_mini_map_ui_state() -> MiniMapUIState {
  if mini_map_ui_state.val is Some(state) {
    return state
  }
  let state = { ui: None, loading: None }
  mini_map_ui_state.val = Some(state)
  state
}

///|
fn clear_entities(ui : MiniMapUI) -> Unit {
  for entity in ui.entities {
    entity.destroy()
  }
  ui.entities.clear()
}

///|
fn poll_or_start_ui_loading(state : MiniMapUIState) -> Unit {
  if state.ui is Some(_) {
    return
  }
  if mini_map_json_override.val is Some(mini_map_json) {
    if map_helper_minimap_json_override.val is Some(map_helper_minimap_json) {
      let resource = mini_map_ui_resource_from_json(
        mini_map_json, map_helper_minimap_json,
      )
      let ui_model = @ui.UIModel::new(Point::new(0, 20), Point::new(0, 0))
      state.ui = Some(MiniMapUI::new(resource, ui_model))
      return
    }
    @log.fatal(
      "mini map test override missing map helper minimap json; call set_map_helper_minimap_json_for_test",
    )
  }
  match state.loading {
    Some(future) =>
      match future.poll() {
        Some(Ok(resource)) => {
          state.loading = None
          let ui_model = @ui.UIModel::new(Point::new(0, 20), Point::new(0, 0))
          state.ui = Some(MiniMapUI::new(resource, ui_model))
        }
        Some(Err(err)) =>
          @log.fatal("failed to load mini map ui resources", data={
            "error": err.to_string(),
          })
        None => ()
      }
    None =>
      state.loading = Some(
        @io_service.submit_background_task(async fn() {
          MiniMapUIResource::load()
        }),
      )
  }
}

///|
pub fn mini_map_ui_system(_world : @ecs.World) -> Unit {
  let state = ensure_mini_map_ui_state()
  poll_or_start_ui_loading(state)
  guard state.ui is Some(ui) else { return }
  if pending_map.val is Some((map_id, map_name, street_name, mini_map_res)) {
    ui.set_map(map_id, map_name, street_name, mini_map_res)
    pending_map.val = None
  }
}
