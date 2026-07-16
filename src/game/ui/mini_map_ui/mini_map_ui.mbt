///|
using @struct {type Point}

///|
using @ui {type UIModel}

///|
/// Resources needed for the MiniMap UI (display only, normal mode).
/// Contains parsed graphical assets for markers and the background canvas.
pub struct MiniMapUIResource {
  /// Marker for portals.
  portal_marker : @res.NxTexture
  /// Window frame pieces for Normal mode.
  min_map : NxMiniMapFrames
}

///|
/// Loads the necessary graphical resources for displaying the MiniMap UI.
pub fn MiniMapUIResource::load() -> MiniMapUIResource {
  let mini_map_json : Json = @res.require_json(
    "res://UI/UIWindow2.img/MiniMap.json",
  )
  let map_helper_minimap_json : Json = @res.require_json(
    "res://Map/MapHelper.img/minimap.json",
  )
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
    let portal_marker = first_frame_texture(map_helper_minimap.portal)
    { portal_marker, min_map: nx_mini_map_ui.min_map }
  } catch {
    e => abort("error loading mini map ui resource, err=\{e}")
  }
}

///|
fn first_frame_texture(
  animation : @res.NxAnimation,
) -> @res.NxTexture {
  if animation.frames.is_empty() {
    abort("mini map ui resource not set")
  }
  animation.frames[0].texture
}

///|
struct NxMiniMapFrames {
  w : @res.NxTexture
  e : @res.NxTexture
  n : @res.NxTexture
  nw : @res.NxTexture
  ne : @res.NxTexture
  s : @res.NxTexture
  sw : @res.NxTexture
  se : @res.NxTexture
} derive(@json.FromJson)

///|
struct NxMiniMapUI {
  min_map : NxMiniMapFrames
} derive(@json.FromJson(fields(min_map(rename="MinMap"))))

///|
struct NxMapHelperMiniMap {
  portal : @res.NxAnimation
}

///|
pub impl @json.FromJson for NxMapHelperMiniMap with fn from_json(json, path) -> NxMapHelperMiniMap raise @json.JsonDecodeError {
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
pub fn MiniMapUI::MiniMapUI(
  resource : MiniMapUIResource,
  ui_model : @ui.UIModel,
) -> MiniMapUI {
  ui_model.position = Point(0, 0)
  ui_model.dimension = Point(0, 0)
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
      let map_dimensions = mini_map_resources.map_or(Default::default(), fn(
        it,
      ) {
        Point(it.canvas.width, it.canvas.height)
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
      let frames : Array[MiniMapFrameDraw] = [
        ..if mini_map_resources is Some(res) {
          [
            {
              texture: {
                i: res.canvas.path,
                w: res.canvas.width,
                h: res.canvas.height,
                offset: Default::default(),
                origin: Default::default(),
              },
              x: map_draw_origin_x_,
              y: map_draw_origin_y_,
              z: @graphics.MINI_MAP_ZINDEX_,
            },
          ]
        },
      ]
      let ur_x_offset = CENTER_START_X_ + c_stretch
      let middle_right_x_ = ur_x_offset + 55
      spawn_minimap_frame_entities(
        self.entities,
        self.resource.min_map,
        self.ui_model.position,
        c_stretch,
        m_stretch,
        down_y_offset,
        ur_x_offset,
        middle_right_x_,
      )
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
      let _normal_dimensions = Point(ur_x_offset + 64, down_y_offset + 27)
      self.ui_model.dimension = _normal_dimensions
      if mini_map_resources is Some(res) {
        let portals = res.portals
        let marker_offset = @selene_math.Vec2(
          (self.resource.portal_marker.w / 2).to_double(),
          (self.resource.portal_marker.h / 2).to_double(),
        )
        let marker_pos_offset = @selene_math.Vec2(0, 65)
        for portal in portals {
          match portal.pt {
            @map.MiniMapPortalType::REGULAR => {
              let marker_pos = (@selene_math.Vec2(
                  portal.x.to_double(),
                  portal.y.to_double(),
                ) +
                marker_pos_offset +
                @selene_math.Vec2(
                  res.draw_data.center_x.to_double(),
                  res.draw_data.center_y.to_double(),
                )).scalar_div(res.draw_data.scale.to_double()) -
                marker_offset +
                @selene_math.Vec2(
                  map_draw_origin_x_.to_double(),
                  map_draw_origin_y_.to_double(),
                )
              spawn_minimap_texture_entity(
                self.entities,
                self.resource.portal_marker,
                self.ui_model.position,
                marker_pos[@selene_math.X].to_int(),
                marker_pos[@selene_math.Y].to_int(),
                @graphics.MINI_MAP_ZINDEX_ + 2,
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
  texture : @res.NxTexture
  x : Int
  y : Int
  z : Int
}

///|
fn ui_image_from_texture(texture : @res.NxTexture) -> @selene_ui.UiImage {
  let source = ui_image_source_from_texture(texture)
  @selene_ui.UiImage::from_image(
    @selene_math.Vec2(texture.w.to_double(), texture.h.to_double()),
    @res.require_image(texture.i),
    source=Some(source),
  )
}

///|
fn ui_image_source_from_texture(
  texture : @res.NxTexture,
) -> @render2d_types.ImageRegion2D {
  {
    position: @selene_math.Vec2(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    size: @selene_math.Vec2(texture.w.to_double(), texture.h.to_double()),
  }
}

///|
fn spawn_minimap_frame_entities(
  entities : Array[@entity.Entity],
  frames : NxMiniMapFrames,
  ui_pos : @struct.Point[Int],
  c_stretch : Int,
  m_stretch : Int,
  down_y_offset : Int,
  ur_x_offset : Int,
  middle_right_x : Int,
) -> Unit {
  let frame_z = @graphics.MINI_MAP_ZINDEX_ + 1
  spawn_minimap_texture_entity_sized(
    entities,
    frames.w,
    ui_pos,
    0,
    ML_MR_Y_,
    frames.w.w,
    m_stretch + 1,
    frame_z,
  )
  spawn_minimap_texture_entity_sized(
    entities,
    frames.e,
    ui_pos,
    middle_right_x,
    ML_MR_Y_,
    frames.e.w,
    m_stretch + 1,
    frame_z,
  )
  spawn_minimap_texture_entity_sized(
    entities,
    frames.n,
    ui_pos,
    CENTER_START_X_,
    0,
    c_stretch + 1,
    frames.n.h,
    frame_z,
  )
  spawn_minimap_texture_entity(entities, frames.nw, ui_pos, 0, 0, frame_z)
  spawn_minimap_texture_entity(
    entities,
    frames.ne,
    ui_pos,
    ur_x_offset,
    0,
    frame_z,
  )
  spawn_minimap_texture_entity_sized(
    entities,
    frames.s,
    ui_pos,
    CENTER_START_X_,
    down_y_offset + 18,
    c_stretch + 1,
    frames.s.h,
    frame_z,
  )
  spawn_minimap_texture_entity(
    entities,
    frames.sw,
    ui_pos,
    0,
    down_y_offset,
    frame_z,
  )
  spawn_minimap_texture_entity(
    entities,
    frames.se,
    ui_pos,
    ur_x_offset,
    down_y_offset,
    frame_z,
  )
}

///|
fn ui_image_from_texture_with_size(
  texture : @res.NxTexture,
  width : Int,
  height : Int,
) -> @selene_ui.UiImage {
  let source = ui_image_source_from_texture(texture)
  @selene_ui.UiImage::from_image(
    @selene_math.Vec2(width.to_double(), height.to_double()),
    @res.require_image(texture.i),
    source=Some(source),
  )
}

///|
fn spawn_minimap_texture_entity_sized(
  entities : Array[@entity.Entity],
  texture : @res.NxTexture,
  ui_pos : @struct.Point[Int],
  local_x : Int,
  local_y : Int,
  width : Int,
  height : Int,
  z : Int,
) -> Unit {
  let entity = @entity.Entity()
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(
        (ui_pos.x + local_x - texture.origin.x).to_double(),
        (ui_pos.y + local_y - texture.origin.y).to_double(),
      ),
      size=@selene_math.Vec2(width.to_double(), height.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex(z))
  @selene_ui.ui_images().set(
    entity,
    ui_image_from_texture_with_size(texture, width, height),
  )
  entities.push(entity)
}

///|
fn spawn_minimap_texture_entity(
  entities : Array[@entity.Entity],
  texture : @res.NxTexture,
  ui_pos : @struct.Point[Int],
  local_x : Int,
  local_y : Int,
  z : Int,
) -> Unit {
  let entity = @entity.Entity()
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2(
        (ui_pos.x + local_x - texture.origin.x).to_double(),
        (ui_pos.y + local_y - texture.origin.y).to_double(),
      ),
      size=@selene_math.Vec2(texture.w.to_double(), texture.h.to_double()),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex(z))
  @selene_ui.ui_images().set(entity, ui_image_from_texture(texture))
  entities.push(entity)
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
let mini_map_ui_state : Ref[MiniMapUIState?] = Ref(None)

///|
let pending_map : Ref[(Int, String, String, @map.MiniMapRuntimeResource?)?] = Ref(
  None,
)

///|
let mini_map_json_override : Ref[Json?] = Ref(None)

///|
let map_helper_minimap_json_override : Ref[Json?] = Ref(None)

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
      if state.loading is None {
        state.loading = Some(
          @io_service.submit_background_task(fn() {
            mini_map_ui_resource_from_json(
              mini_map_json, map_helper_minimap_json,
            )
          }),
        )
      }
    } else {
      @log.fatal(
        "mini map test override missing map helper minimap json; call set_map_helper_minimap_json_for_test",
      )
      return
    }
  }
  match state.loading {
    Some(future) =>
      match future.poll() {
        Some(Ok(resource)) => {
          state.loading = None
          let ui_model = UIModel(Point(0, 20), Point(0, 0))
          state.ui = Some(MiniMapUI(resource, ui_model))
        }
        Some(Err(err)) =>
          @log.fatal("failed to load mini map ui resources", data={
            "error": err.to_string(),
          })
        None => ()
      }
    None =>
      state.loading = Some(
        @io_service.submit_background_task(fn() { MiniMapUIResource::load() }),
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
