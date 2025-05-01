///| Resources needed for the MiniMap UI (display only, normal mode).
/// Contains parsed graphical assets for markers and the background canvas.
struct MiniMapUIResource {
  /// Marker for portals.
  portal_marker : @graphics.Animation
  // Window frame elements for Normal mode
  minmap_middle_center : @graphics.Animation
  minmap_middle_left : @graphics.Animation
  minmap_middle_right : @graphics.Animation
  minmap_up_center : @graphics.Animation
  minmap_up_left : @graphics.Animation
  minmap_up_right : @graphics.Animation
  minmap_down_center : @graphics.Animation
  minmap_down_left : @graphics.Animation
  minmap_down_right : @graphics.Animation
}

///| Loads the necessary graphical resources for displaying the MiniMap UI.
pub fn MiniMapUIResource::load() -> @utils.Future[MiniMapUIResource] {
  let map_latest_loader = get_map_latest_loader()
  let portal_fut = map_latest_loader.load_res([
    "MapHelper.img", "minimap", "portal",
  ])
  // Load UI window elements from UIWindow2.img
  let ui_loader = @ui.ui_window_2_loader()
  let minmap_fut = ui_loader.load_res(["MiniMap", "MinMap"])
  @utils.Future::combine(portal_fut, minmap_fut).map(fn(results) {
    let (portal_node, minmap_node) = results
    let portal_marker = @graphics.Animation::from_resource(portal_node)

    // Load normal mode window frame elements
    let minmap_middle_center = @graphics.Animation::from_resource(
      minmap_node["c"],
    )
    let minmap_middle_left = @graphics.Animation::from_resource(
      minmap_node["w"],
    )
    let minmap_middle_right = @graphics.Animation::from_resource(
      minmap_node["e"],
    )
    let minmap_up_center = @graphics.Animation::from_resource(minmap_node["n"])
    let minmap_up_left = @graphics.Animation::from_resource(minmap_node["nw"])
    let minmap_up_right = @graphics.Animation::from_resource(minmap_node["ne"])
    let minmap_down_center = @graphics.Animation::from_resource(
      minmap_node["s"],
    )
    let minmap_down_left = @graphics.Animation::from_resource(minmap_node["sw"])
    let minmap_down_right = @graphics.Animation::from_resource(
      minmap_node["se"],
    )
    {
      portal_marker,
      minmap_middle_center,
      minmap_middle_left,
      minmap_middle_right,
      minmap_up_center,
      minmap_up_left,
      minmap_up_right,
      minmap_down_center,
      minmap_down_left,
      minmap_down_right,
    }
  })
}

///|
priv enum MiniMapType {
  MIN
  NORMAL
  MAX
}

///| Represents the state and logic for the MiniMap UI widget.
struct MiniMapUI {
  model : @ui.UIModel // Needed for positioning, etc.
  resource : MiniMapUIResource
  type_ : MiniMapType
  mut current_map : (Int, MapInfo, MiniMapResource?)?
  on_state_changed : () -> Unit
}

///|
fn MiniMapUI::new(
  resource : MiniMapUIResource,
  on_state_changed : () -> Unit
) -> MiniMapUI {
  {
    model: @ui.UIModel::new(
      @struct.Point::new(128, 20),
      @struct.Point::new(0, 0), // reset after loading map
    ),
    resource,
    type_: MiniMapType::NORMAL, // NORMAL by default
    current_map: None,
    on_state_changed,
  }
}

///| 地图绘制信息
priv struct MapDrawData {
  scale : Float // 缩放比例
  center_x : Int // 中心X偏移
  center_y : Int // 中心Y偏移
  width : Int // 地图宽度
  height : Int // 地图高度
}

///| 静态标记（传送门）
priv struct PortalMarker {
  name : String // portal name
  x : Int // x
  y : Int // y
  tm : Int // target map id
  pt : Int // portal type
} derive(Show)

///| 完整的迷你地图资源
struct MiniMapResource {
  canvas : @graphics.Animation // 地图画布纹理
  draw_data : MapDrawData // 绘制数据
  portals : Array[PortalMarker] // 传送门标记列表
}

///| Loads minimap resources from a map node
fn MiniMapResource::load(map_node : @resource.NxNode) -> MiniMapResource?! {
  // Check if miniMap exists
  let mini_map_node = map_node["miniMap"]
  if mini_map_node.is_null() {
    return None
  }

  // Get scale and center offset
  let mag = mini_map_node["mag"].get_int!()
  let center_x = mini_map_node["centerX"].get_int!()
  let center_y = mini_map_node["centerY"].get_int!()

  // Try loading canvas
  let canvas = @graphics.Animation::from_resource_ex!(mini_map_node["canvas"])
  let dimensions = canvas.get_dimensions()

  // Create draw data
  let draw_data = {
    scale: 2.0.pow(mag.to_double()).to_float(),
    center_x,
    center_y,
    width: dimensions.x,
    height: dimensions.y,
  }
  let portals : @resource.MapBasedArray[PortalMarker] = @json.from_json!(
    map_node["portal"].value(),
  )
  Some({ canvas, draw_data, portals: portals._ })
}

///|
pub fn MiniMapUI::set_map(
  self : MiniMapUI,
  map_id : Int,
  map_info : MapInfo,
  mini_map_resources : MiniMapResource?
) -> Unit {
  self.current_map = Some((map_id, map_info, mini_map_resources))
  (self.on_state_changed)()
}

///| Renders the MiniMap based on current state.
pub impl @ui.Widget for MiniMapUI with render(self) -> @ui.RenderSpec {
  guard self.current_map is Some((_, map_info, mini_map_resources)) else {
    return { render_elements: [] }
  }
  match self.type_ {
    MIN =>
      //       for sprite in self.min_sprites {
      //     sprite.draw(position_, alpha);
      // }
      return {
        render_elements: [
          @ui.RenderElement::Static(
            @ui.StaticUI::new_ex(
              @ui.TextUI(
                @graphics.Text::new(
                  @graphics.FontId::A12M,
                  @graphics.TextAlignment::LEFT,
                  @struct.ColorName::WHITE,
                  text=map_info.get_full_name(),
                ),
              ),
              args=@graphics.DrawArgument::new(pos=@struct.Point::new(7, -3)),
            ),
          ),
        ],
      }
    NORMAL => {
      let region_text = @graphics.Text::new(
        @graphics.FontId::A12B,
        @graphics.TextAlignment::LEFT,
        @struct.ColorName::WHITE,
        text=map_info.map_name,
      )
      let town_text = @graphics.Text::new(
        @graphics.FontId::A12B,
        @graphics.TextAlignment::LEFT,
        @struct.ColorName::WHITE,
        text=map_info.street_name,
      )
      let map_dimensions = mini_map_resources.map_or(Point::default(), fn(it) {
        it.canvas.get_dimensions()
      })
      // 48 (offset for text) + longer text's width + 10 (space for right side
      // border)
      let mark_text_width = 48 +
        @math.maximum(region_text.width(), town_text.width()) +
        10
      let window_width = @math.maximum(
        178,
        @math.maximum(mark_text_width, map_dimensions.x + 20),
      )
      let c_stretch = @math.maximum(0, window_width - 128)
      let map_draw_origin_x_ = @math.maximum(
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
      let render_elements = []
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_middle_center,
            @graphics.DrawArgument::from_pos_and_stretch(
              @struct.Point::new(7, 10),
              @struct.Point::new(c_stretch + 114, m_stretch + 27),
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      if mini_map_resources is Some(res) {
        render_elements.push(
          @ui.RenderElement::Static(
            @ui.SpriteUI(
              @graphics.Sprite::new(
                res.canvas,
                @graphics.DrawArgument::new(
                  pos=@struct.Point::new(map_draw_origin_x_, map_draw_origin_y_),
                ),
              ),
            ),
          ),
        )
      }
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_middle_left,
            @graphics.DrawArgument::from_pos_and_stretch(
              @struct.Point::new(0, ML_MR_Y_),
              @struct.Point::new(0, m_stretch),
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      let ur_x_offset = CENTER_START_X_ + c_stretch
      let middle_right_x_ = ur_x_offset + 55
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_middle_right,
            @graphics.DrawArgument::from_pos_and_stretch(
              @struct.Point::new(middle_right_x_, ML_MR_Y_),
              @struct.Point::new(0, m_stretch),
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_up_center,
            @graphics.DrawArgument::from_pos_and_stretch(
              @struct.Point::new(CENTER_START_X_, 0) + window_ul_pos_,
              @struct.Point::new(c_stretch, 0),
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_up_left,
            @graphics.DrawArgument::new(pos=window_ul_pos_),
          )
          |> @ui.SpriteUI,
        ),
      )
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_up_right,
            @graphics.DrawArgument::new(
              pos=@struct.Point::new(ur_x_offset, 0) + window_ul_pos_,
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_down_center,
            @graphics.DrawArgument::from_pos_and_stretch(
              @struct.Point::new(CENTER_START_X_, down_y_offset + 18),
              @struct.Point::new(c_stretch, 0),
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_down_left,
            @graphics.DrawArgument::new(
              pos=@struct.Point::new(0, down_y_offset),
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      render_elements.push(
        @ui.RenderElement::Static(
          @graphics.Sprite::new(
            self.resource.minmap_down_right,
            @graphics.DrawArgument::new(
              pos=@struct.Point::new(ur_x_offset, down_y_offset),
            ),
          )
          |> @ui.SpriteUI,
        ),
      )
      let normal_dimensions_ = @struct.Point::new(
        ur_x_offset + 64,
        down_y_offset + 27,
      )
      if mini_map_resources is Some(res) {
        let portal_marker = self.resource.portal_marker
        let portals = res.portals
        let marker_sprite = portal_marker
        let marker_offset = marker_sprite.get_dimensions() /
          @struct.Point::new(2, 0)
        let marker_pos_offset = @struct.Point::new(0, 65)
        for portal in portals {
          let portal_type = portal.pt
          if portal_type == 2 {
            let marker_pos = ((Point::new(portal.x, portal.y) +
            marker_pos_offset +
            Point::new(res.draw_data.center_x, res.draw_data.center_y))
            .to_float()
            .div_float(res.draw_data.scale) -
            marker_offset.to_float() +
            @struct.Point::new(map_draw_origin_x_, map_draw_origin_y_).to_float()).to_int()
            render_elements.push(
              @ui.RenderElement::Static(
                @ui.SpriteUI(
                  @graphics.Sprite::new(
                    portal_marker,
                    @graphics.DrawArgument::new(pos=marker_pos),
                  ),
                ),
              ),
            )
          }
        }
        //         draw_movable_markers(position_, alpha);

        //         if (list_npc_enabled_) {
        //             draw_npclist(normal_dimensions_, alpha);
        //         }
      }
      { render_elements, }
    }
    MAX => ...
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
pub impl @ui.Widget for MiniMapUI with remove_cursor(self) -> Unit {

}

///|
pub impl @ui.Widget for MiniMapUI with get_ui_model(self) -> @ui.UIModel {
  self.model
}

///|
pub impl @ui.Widget for MiniMapUI with send_key(self, keycode, pressed, escape) -> Unit {
  ignore(self)
  ignore(keycode)
  ignore(pressed)
  ignore(escape)
}

///|
let map_latest_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "MapLatest",
  loader=@resource.AsyncResourceLoader::new_composite_async_resource_loader(
    {
      "Obj/login.img/": @resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/MapLatest/Obj/login.img",
      ),
      "MapHelper.img/minimap/": @resource.DirResourceLoader::new(
        "https://maple-res.kkkiiox.work/MapLatest/MapHelper.img/minimap",
      ),
    },
    @resource.get_default_image_loader(),
  ),
)

///|
pub fn get_map_latest_loader() -> @resource.AsyncLoader {
  map_latest_loader
}

///|
pub fn load_map_node(map_id : Int) -> @utils.Future[@resource.NxNode] {
  guard map_id >= 0
  let prefix = (map_id / 100000000).to_string()
  let strid = @string_format.extend_id(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  get_mapx_loader().load_res(path)
}

///| Create a PortalMarker from JSON data
impl @json.FromJson for PortalMarker with from_json(json, path) -> PortalMarker! {
  match json {
    {
      "pn": String(name),
      "x": Number(x),
      "y": Number(y),
      "tm": Number(target_map),
      "pt": Number(pt),
      ..
    } =>
      {
        name,
        x: x.to_int(),
        y: y.to_int(),
        tm: target_map.to_int(),
        pt: pt.to_int(),
      }
    _ =>
      raise @json.JsonDecodeError(
        (path, "PortalMarker::from_json: expected object"),
      )
  }
}

///|
test "parse portal marker" {
  let json = @json.parse!(
    #| {"0":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":-289,"y":227},"1":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":-147,"y":235},"2":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":-68,"y":235},"3":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":2,"y":237},"4":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":84,"y":234},"5":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":2685,"y":57},"6":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":2752,"y":59},"7":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":2836,"y":58},"8":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":2900,"y":60},"9":{"pn":"sp","pt":0,"tm":999999999,"tn":"","x":3064,"y":48},"10":{"pn":"west00","pt":2,"tm":105050100,"tn":"east00","x":-222,"y":318},"11":{"pn":"east00","pt":2,"tm":105050300,"tn":"west00","x":3013,"y":138}}
    ,
  )
  let portal_markers : @resource.MapBasedArray[PortalMarker] = @json.from_json!(
    json,
  )
  inspect!(
    portal_markers,
    content=
      #|MapBasedArray([{name: "sp", x: -289, y: 227, tm: 999999999, pt: 0}, {name: "sp", x: -147, y: 235, tm: 999999999, pt: 0}, {name: "sp", x: -68, y: 235, tm: 999999999, pt: 0}, {name: "sp", x: 2, y: 237, tm: 999999999, pt: 0}, {name: "sp", x: 84, y: 234, tm: 999999999, pt: 0}, {name: "sp", x: 2685, y: 57, tm: 999999999, pt: 0}, {name: "sp", x: 2752, y: 59, tm: 999999999, pt: 0}, {name: "sp", x: 2836, y: 58, tm: 999999999, pt: 0}, {name: "sp", x: 2900, y: 60, tm: 999999999, pt: 0}, {name: "sp", x: 3064, y: 48, tm: 999999999, pt: 0}, {name: "west00", x: -222, y: 318, tm: 105050100, pt: 2}, {name: "east00", x: 3013, y: 138, tm: 105050300, pt: 2}])
    ,
  )
}

///|
const CENTER_START_X_ = 64

///|
const BTN_MIN_Y_ = 4

///|
const ML_MR_Y_ = 17

///|
const MAX_ADJ_ = 40

///|
const M_START_ = 36

///|
const LISTNPC_ITEM_HEIGHT_ = 17

///|
const LISTNPC_ITEM_WIDTH_ = 140

///|
const LISTNPC_TEXT_WIDTH_ = 114

///|
let window_ul_pos_ : @struct.Point[Int] = @struct.Point::new(0, 0)
