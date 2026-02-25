///|
using @struct {type Point}

///|
/// Resources needed for the MiniMap UI (display only, normal mode).
/// Contains parsed graphical assets for markers and the background canvas.
pub struct MiniMapUIResource {
  /// Marker for portals.
  portal_marker : @sprite.Animation
  // Window frame elements for Normal mode
  // minmap_middle_center : @graphics.Animation
  minmap_middle_left : @sprite.AnimationFrame
  minmap_middle_right : @sprite.AnimationFrame
  minmap_up_center : @sprite.AnimationFrame
  minmap_up_left : @sprite.AnimationFrame
  minmap_up_right : @sprite.AnimationFrame
  minmap_down_center : @sprite.AnimationFrame
  minmap_down_left : @sprite.AnimationFrame
  minmap_down_right : @sprite.AnimationFrame
}

///|
/// Loads the necessary graphical resources for displaying the MiniMap UI.
pub async fn MiniMapUIResource::load() -> MiniMapUIResource {
  let mini_map_json : Json = @resource.get_ui_window_2_loader()
    .load_res_async(["MiniMap"])
    .value() catch {
      e => {
        @log.error("failed to load UIWindow2 MiniMap resource", data={
          "error": e,
        })
        panic()
      }
    }
  let map_helper_minimap_json : Json = @resource.get_map_latest_loader()
    .load_res_async(["MapHelper.img", "minimap"])
    .value() catch {
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
    let portal_marker = @resource.nx_animation_to_selene_animation(
      map_helper_minimap.portal,
      loop_=true,
    )
    {
      portal_marker,
      // minmap_middle_center,
      minmap_middle_left: nx_texture_to_frame(minmap_middle_left),
      minmap_middle_right: nx_texture_to_frame(minmap_middle_right),
      minmap_up_center: nx_texture_to_frame(minmap_up_center),
      minmap_up_left: nx_texture_to_frame(minmap_up_left),
      minmap_up_right: nx_texture_to_frame(minmap_up_right),
      minmap_down_center: nx_texture_to_frame(minmap_down_center),
      minmap_down_left: nx_texture_to_frame(minmap_down_left),
      minmap_down_right: nx_texture_to_frame(minmap_down_right),
    }
  } catch {
    e => {
      @log.error("error loading mini map ui resource", data={ "error": e })
      panic()
    }
  }
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
  ui_model.position = @struct.Point::new(128, 20)
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
  for entity in self.entities {
    entity.destroy()
  }
  self.entities.clear()
  match self.type_ {
    // MIN =>
    //   return {
    //     render_elements: [
    //       @ui.RenderElement::Static(
    //         @ui.StaticUI::new_ex(
    //           @ui.TextUI(
    //             @graphics.Text::new(
    //               @graphics.FontId::A12M,
    //               @graphics.TextAlignment::LEFT,
    //               @struct.ColorName::WHITE,
    //               text=map_info.get_full_name(),
    //             ),
    //           ),
    //           args=@graphics.DrawArgument::new(pos=@struct.Point::new(7, -3)),
    //         ),
    //       ),
    //     ],
    //   }
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
      // Normal sprites queue
      // (7, 10) is the top left corner of the inner window
      // 114 = 128 (width of left and right borders) - 14 (width of middle borders
      // * 2). 27 = height of inner frame drawn on up and down borders
      let frames = []
      // frames.push(
      //   @graphics.Sprite::new(
      //     self.resource.minmap_middle_center,
      //     @graphics.DrawArgument::from_pos_and_stretch(
      //       Point::new(7, 10),
      //       Point::new(c_stretch + 114, m_stretch + 27),
      //     ),
      //   ),
      // )
      if mini_map_resources is Some(res) {
        let canvas_sprite = @sprite.Sprite::from_animation(
          @resource.nx_animation_to_selene_animation(res.canvas),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(
            map_draw_origin_x_.to_double(),
            map_draw_origin_y_.to_double(),
          ),
        )
        frames.push(canvas_sprite)
      }
      push_repeated_frame_y(
        frames,
        self.resource.minmap_middle_left,
        @graphics.MINI_MAP_ZINDEX_,
        0,
        ML_MR_Y_,
        m_stretch + 1,
      )
      let ur_x_offset = CENTER_START_X_ + c_stretch
      let middle_right_x_ = ur_x_offset + 55
      push_repeated_frame_y(
        frames,
        self.resource.minmap_middle_right,
        @graphics.MINI_MAP_ZINDEX_,
        middle_right_x_,
        ML_MR_Y_,
        m_stretch + 1,
      )
      push_repeated_frame_x(
        frames,
        self.resource.minmap_up_center,
        @graphics.MINI_MAP_ZINDEX_,
        CENTER_START_X_,
        0,
        c_stretch + 1,
      )
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new([self.resource.minmap_up_left]),
          @graphics.MINI_MAP_ZINDEX_,
          offset=window_ul_pos_,
        ),
      )
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new([self.resource.minmap_up_right]),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(ur_x_offset.to_double(), 0) + window_ul_pos_,
        ),
      )
      push_repeated_frame_x(
        frames,
        self.resource.minmap_down_center,
        @graphics.MINI_MAP_ZINDEX_,
        CENTER_START_X_,
        down_y_offset + 18,
        c_stretch + 1,
      )
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new([self.resource.minmap_down_left]),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(0, down_y_offset.to_double()),
        ),
      )
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new([self.resource.minmap_down_right]),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(
            ur_x_offset.to_double(),
            down_y_offset.to_double(),
          ),
        ),
      )
      for sprite in frames {
        spawn_minimap_sprite_entity(
          self.entities,
          sprite,
          self.ui_model.position,
        )
      }
      let _normal_dimensions = Point::new(ur_x_offset + 64, down_y_offset + 27)
      self.ui_model.dimension = _normal_dimensions
      if mini_map_resources is Some(res) {
        let portal_marker = self.resource.portal_marker
        let portals = res.portals
        let marker_sprite = portal_marker
        let mark_sprite_dim = marker_sprite.frames[0].size
        let marker_offset = mark_sprite_dim.scalar_div(2)
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
              let sprite = @sprite.Sprite::from_animation(
                portal_marker,
                @graphics.MINI_MAP_ZINDEX_ + 1,
                offset=marker_pos,
              )
              spawn_minimap_sprite_entity(
                self.entities,
                sprite,
                self.ui_model.position,
              )
            }
            _ => ()
          }
        }
        //         draw_movable_markers(position_, alpha);

        //         if (list_npc_enabled_) {
        //             draw_npclist(normal_dimensions_, alpha);
        //         }
      }
    }
  }

  // } else {
  //     for (const auto &sprite : max_sprites_) {
  //         sprite.draw(position_, alpha);
  //     }

  //     region_text_.draw(position_ + Point<int16_t>(48, 14));
  //     town_text_.draw(position_ + Point<int16_t>(48, 28));

  //     if (has_map_) {
  //         Animation portal_marker(marker_["portal"]);

  //         for (const auto &sprite : static_marker_info_) {
  //             portal_marker.draw(
  //                 position_ + sprite.second + Point<int16_t>(0, MAX_ADJ_),
  //                 alpha);
  //         }

  //         draw_movable_markers(position_ + Point<int16_t>(0, MAX_ADJ_),
  //                              alpha);

  //         if (list_npc_enabled_) {
  //             draw_npclist(max_dimensions_, alpha);
  //         }
  //     }
  // }

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
let window_ul_pos_ : @selene_math.Vec2D = @selene_math.Vec2D(0, 0)

///|
fn nx_texture_to_frame(
  nx_texture : @resource.NxTexture,
) -> @sprite.AnimationFrame {
  @sprite.AnimationFrame::{
    sprite_path: nx_texture.i,
    size: @selene_math.Vec2D(nx_texture.w.to_double(), nx_texture.h.to_double()),
    offset: @selene_math.Vec2D(
      nx_texture.offset.x.to_double(),
      nx_texture.offset.y.to_double(),
    ),
    pivot: @selene_math.Vec2D(
      nx_texture.origin.x.to_double(),
      nx_texture.origin.y.to_double(),
    ),
    duration: 0.0,
  }
}

///|
fn spawn_minimap_sprite_entity(
  entities : Array[@entity.Entity],
  sprite : @sprite.Sprite,
  ui_pos : @struct.Point[Int],
) -> Unit {
  let entity = @entity.Entity::new()
  @sprite.sprites.set(entity, sprite)
  @position.positions.set(
    entity,
    @position.Position(
      @selene_math.Vec2D(ui_pos.x.to_double(), ui_pos.y.to_double()),
    ),
  )
  @selene_ui.uis.set(entity, @selene_ui.Ui::new())
  entities.push(entity)
}

///|
fn sync_minimap_entity_positions(ui : MiniMapUI) -> Unit {
  let ui_pos = ui.ui_model.position
  for entity in ui.entities {
    @position.positions.set(
      entity,
      @position.Position(
        @selene_math.Vec2D(ui_pos.x.to_double(), ui_pos.y.to_double()),
      ),
    )
  }
}

///|
fn push_repeated_frame_x(
  frames : Array[@sprite.Sprite],
  frame : @sprite.AnimationFrame,
  z : Int,
  start_x : Int,
  y : Int,
  count : Int,
) -> Unit {
  for i in 0..<count {
    frames.push(
      @sprite.Sprite::from_animation(
        @sprite.Animation::new([frame]),
        z,
        offset=@selene_math.Vec2D((start_x + i).to_double(), y.to_double()),
      ),
    )
  }
}

///|
fn push_repeated_frame_y(
  frames : Array[@sprite.Sprite],
  frame : @sprite.AnimationFrame,
  z : Int,
  x : Int,
  start_y : Int,
  count : Int,
) -> Unit {
  for i in 0..<count {
    frames.push(
      @sprite.Sprite::from_animation(
        @sprite.Animation::new([frame]),
        z,
        offset=@selene_math.Vec2D(x.to_double(), (start_y + i).to_double()),
      ),
    )
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
    @sprite.sprites.remove(entity) |> ignore
    @position.positions.remove(entity) |> ignore
    @selene_ui.uis.remove(entity) |> ignore
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
pub fn mini_map_ui_system(_delta : Double) -> Unit {
  let state = ensure_mini_map_ui_state()
  poll_or_start_ui_loading(state)
  guard state.ui is Some(ui) else { return }
  if pending_map.val is Some((map_id, map_name, street_name, mini_map_res)) {
    ui.set_map(map_id, map_name, street_name, mini_map_res)
    pending_map.val = None
  }
  sync_minimap_entity_positions(ui)
}
