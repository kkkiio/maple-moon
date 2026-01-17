///|
/// Resources needed for the MiniMap UI (display only, normal mode).
/// Contains parsed graphical assets for markers and the background canvas.
struct MiniMapUIResource {
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
pub fn MiniMapUIResource::load() -> MiniMapUIResource {
  let portal_marker = @sprite.Animation::single_frame(
    "/assets/portal/portal_marker.png",
    @selene_math.Vec2D(14, 14),
  )
  // Load UI window elements from UIWindow2.img
  // {
  // 	"meta": {
  // 		"image": "MinMap.png",
  // 		"size": {"w":128,"h":75},
  // 		"scale": "1"
  // 	},
  // 	"frames": {
  // 		"74898.png":
  // 		{
  // 			"frame": {"x":0,"y":0,"w":64,"h":27},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":64,"h":27},
  // 			"sourceSize": {"w":64,"h":27}
  // 		},
  // 		"74900.png":
  // 		{
  // 			"frame": {"x":0,"y":27,"w":64,"h":27},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":64,"h":27},
  // 			"sourceSize": {"w":64,"h":27}
  // 		},
  // 		"74903.png":
  // 		{
  // 			"frame": {"x":64,"y":0,"w":64,"h":27},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":64,"h":27},
  // 			"sourceSize": {"w":64,"h":27}
  // 		},
  // 		"74905.png":
  // 		{
  // 			"frame": {"x":64,"y":27,"w":64,"h":27},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":64,"h":27},
  // 			"sourceSize": {"w":64,"h":27}
  // 		},
  // 		"74899.png":
  // 		{
  // 			"frame": {"x":0,"y":54,"w":1,"h":21},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":1,"h":21},
  // 			"sourceSize": {"w":1,"h":21}
  // 		},
  // 		"74904.png":
  // 		{
  // 			"frame": {"x":1,"y":54,"w":1,"h":9},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":1,"h":9},
  // 			"sourceSize": {"w":1,"h":9}
  // 		},
  // 		"74901.png":
  // 		{
  // 			"frame": {"x":2,"y":54,"w":9,"h":1},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":9,"h":1},
  // 			"sourceSize": {"w":9,"h":1}
  // 		},
  // 		"74902.png":
  // 		{
  // 			"frame": {"x":11,"y":54,"w":9,"h":1},
  // 			"rotated": false,
  // 			"trimmed": false,
  // 			"spriteSourceSize": {"x":0,"y":0,"w":9,"h":1},
  // 			"sourceSize": {"w":9,"h":1}
  // 		}
  // 	}
  // }
  let minmap_node : Map[String, Json] = {
    "c": {
      "__h": 27,
      "__w": 64,
      "_inlink": "MiniMap/MinMap/se",
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74905",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":64,"y":27,"w":64,"h":27},
      "__off": [64, 27],
    },
    "e": {
      "__h": 1,
      "__w": 9,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74902",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":11,"y":54,"w":9,"h":1},
      "__off": [11, 54],
    },
    "n": {
      "__h": 21,
      "__w": 1,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74899",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":0,"y":54,"w":1,"h":21},
      "__off": [0, 54],
    },
    "ne": {
      "__h": 27,
      "__w": 64,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74900",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":0,"y":27,"w":64,"h":27},
      "__off": [0, 27],
    },
    "nw": {
      "__h": 27,
      "__w": 64,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74898",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":64,"y":0,"w":64,"h":27},
      "__off": [64, 0],
    },
    "s": {
      "__h": 9,
      "__w": 1,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74904",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":1,"y":54,"w":1,"h":9},
      "__off": [1, 54],
    },
    "se": {
      "__h": 27,
      "__w": 64,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74905",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":64,"y":27,"w":64,"h":27},
      "__off": [64, 27],
    },
    "sw": {
      "__h": 27,
      "__w": 64,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74903",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":64,"y":0,"w":64,"h":27},
      "__off": [64, 0],
    },
    "w": {
      "__h": 1,
      "__w": 9,
      "origin": [0, 0],
      // "__i": "spritesheets/UI/UIWindow2.img/MiniMap/MinMap#74901",
      "__i": "/assets/minimap/min_map_frame.png",
      // 			"frame": {"x":2,"y":54,"w":9,"h":1},
      "__off": [2, 54],
    },
  }

  // Load normal mode window frame elements
  // let minmap_middle_center = @graphics.Animation::from_resource(
  //   minmap_node["c"],
  // )
  try {
    let minmap_middle_left : @resource.NxTexture = @json.from_json(
      minmap_node["w"],
    )
    let minmap_middle_right : @resource.NxTexture = @json.from_json(
      minmap_node["e"],
    )
    let minmap_up_center : @resource.NxTexture = @json.from_json(
      minmap_node["n"],
    )
    let minmap_up_left : @resource.NxTexture = @json.from_json(
      minmap_node["nw"],
    )
    let minmap_up_right : @resource.NxTexture = @json.from_json(
      minmap_node["ne"],
    )
    let minmap_down_center : @resource.NxTexture = @json.from_json(
      minmap_node["s"],
    )
    let minmap_down_left : @resource.NxTexture = @json.from_json(
      minmap_node["sw"],
    )
    let minmap_down_right : @resource.NxTexture = @json.from_json(
      minmap_node["se"],
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
pub enum MiniMapType {
  // MIN
  NORMAL
  // MAX
}

///|
/// Represents the state and logic for the MiniMap UI widget.
struct MiniMapUI {
  resource : MiniMapUIResource
  type_ : MiniMapType
  mut current_map : (Int, MapInfo, MiniMapRuntimeResource?)?
  entities : Array[@entity.Entity]
  ui_model : @ui.UIModel
}

///|
fn MiniMapUI::new(
  resource : MiniMapUIResource,
  ui_model : @ui.UIModel,
) -> MiniMapUI {
  ui_model.position = @struct.Point::new(128, 20)
  ui_model.dimension = @struct.Point::new(0, 0)
  {
    resource,
    type_: MiniMapType::NORMAL, // NORMAL by default
    current_map: None,
    entities: [],
    ui_model,
  }
}

///|
/// 地图绘制信息
priv struct MapDrawData {
  scale : Float // 缩放比例
  center_x : Int // 中心X偏移
  center_y : Int // 中心Y偏移
  width : Int // 地图宽度
  height : Int // 地图高度
}

///|
/// 完整的迷你地图资源
struct MiniMapRuntimeResource {
  canvas : @resource.NxAnimation // 地图画布纹理
  draw_data : MapDrawData // 绘制数据
  portals : Array[NxPortal] // 传送门标记列表
}

///|
/// Loads minimap resources from a map node
fn MiniMapRuntimeResource::load(
  resource : MiniMapResource,
  portals : Array[NxPortal],
) -> MiniMapRuntimeResource {
  let mag = resource.mag
  let center_x = resource.center_x
  let center_y = resource.center_y
  let canvas = resource.canvas
  let dimensions = (canvas.frames[0].texture.w, canvas.frames[0].texture.h)

  // Create draw data
  let draw_data = {
    scale: 2.0.pow(mag.to_double()).to_float(),
    center_x,
    center_y,
    width: dimensions.0,
    height: dimensions.1,
  }
  { canvas, draw_data, portals }
}

///|
struct MiniMapResource {
  mag : Int
  center_x : Int
  center_y : Int
  canvas : @resource.NxAnimation
} derive (
  @json.FromJson(fields(center_x(rename="centerX"), center_y(rename="centerY"))),
)

///|
pub fn MiniMapUI::set_map(
  self : MiniMapUI,
  map_id : Int,
  map_info : MapInfo,
  mini_map_resources : MiniMapRuntimeResource?,
) -> Unit {
  self.current_map = Some((map_id, map_info, mini_map_resources))
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
        @struct.Point::new(
          it.canvas.frames[0].texture.w,
          it.canvas.frames[0].texture.h,
        )
      })
      // 48 (offset for text) + longer text's width + 10 (space for right side
      // border)
      let mark_text_width = 48 +
        @cmp.maximum(region_text.width(), town_text.width()) +
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
        frames.push({
          ..@graphics.nx_animation_to_selene_sprite(
            res.canvas,
            z=@graphics.MINI_MAP_ZINDEX_,
          ),
          offset: @selene_math.Vec2D(
            map_draw_origin_x_.to_double(),
            map_draw_origin_y_.to_double(),
          ),
        })
      }
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new(
            [self.resource.minmap_middle_left],
            // @struct.Point::new(0, m_stretch),
            transform=@selene_math.Transform::from_scale(
              0,
              m_stretch.to_double(),
            ),
          ),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(0, ML_MR_Y_.to_double()),
        ),
      )
      let ur_x_offset = CENTER_START_X_ + c_stretch
      let middle_right_x_ = ur_x_offset + 55
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new(
            [self.resource.minmap_middle_right],
            // @struct.Point::new(0, m_stretch),
            transform=@selene_math.Transform::from_scale(
              0,
              m_stretch.to_double(),
            ),
          ),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(
            middle_right_x_.to_double(),
            ML_MR_Y_.to_double(),
          ),
        ),
      )
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new(
            [self.resource.minmap_up_center],
            //   @struct.Point::new(c_stretch, 0),
            transform=@selene_math.Transform::from_scale(
              c_stretch.to_double(),
              0,
            ),
          ),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(
              //   @struct.Point::new(CENTER_START_X_, 0) + window_ul_pos_,
              CENTER_START_X_.to_double(),
              0,
            ) +
            window_ul_pos_,
        ),
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
      frames.push(
        @sprite.Sprite::from_animation(
          @sprite.Animation::new(
            [self.resource.minmap_down_center],
            // @struct.Point::new(c_stretch, 0),
            transform=@selene_math.Transform::from_scale(
              c_stretch.to_double(),
              0,
            ),
          ),
          @graphics.MINI_MAP_ZINDEX_,
          offset=@selene_math.Vec2D(
            CENTER_START_X_.to_double(),
            (down_y_offset + 18).to_double(),
          ),
        ),
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
        let entity = @entity.Entity::new()
        @sprite.sprites.set(entity, sprite)
        self.entities.push(entity)
      }
      let _normal_dimensions = Point::new(ur_x_offset + 64, down_y_offset + 27)
      if mini_map_resources is Some(res) {
        let portal_marker = self.resource.portal_marker
        let portals = res.portals
        let marker_sprite = portal_marker
        let mark_sprite_dim = marker_sprite.frames[0].size
        let marker_offset = mark_sprite_dim.scalar_div(2)
        let marker_pos_offset = @selene_math.Vec2D(0, 65)
        for portal in portals {
          match (portal.pt, map_id != portal.tm) {
            (PortalType::REGULAR, _)
            // skip portals that are only used for gameplay mechanics
            | (PortalType::INVISIBLE, true) => {
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
              let entity = @entity.Entity::new()
              let sprite = @sprite.Sprite::from_animation(
                portal_marker,
                @graphics.MINI_MAP_ZINDEX_,
                offset=marker_pos,
              )
              @sprite.sprites.set(entity, sprite)
              self.entities.push(entity)
            }
            _ => ()
          }
        }
        //         draw_movable_markers(position_, alpha);

        //         if (list_npc_enabled_) {
        //             draw_npclist(normal_dimensions_, alpha);
        //         }
      }
      for e in self.entities {
        @position.positions.set(
          e,
          @position.Position(
            @selene_math.Vec2D(
              self.ui_model.position.x.to_double(),
              self.ui_model.position.y.to_double(),
            ),
          ),
        ) // relative to parent
      }
    }
    ...
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
/// Renders the MiniMap based on current state.
pub impl @ui.Widget for MiniMapUI with render(self) -> @ui.RenderSpec {
  ...
}

///|
pub fn get_map_latest_loader() -> @resource.AsyncLoader {
  ...
  // @resource.AsyncLoader::new(
  //   "MapLatest",
  //   loader=@resource.AsyncResourceLoader::new_composite_async_resource_loader({
  //     "Obj/login.img/": @resource.DirResourceLoader::new(
  //       "https://maple-res.kkkiiox.work/MapLatest/Obj/login.img",
  //     ),
  //     "MapHelper.img/minimap/": @resource.DirResourceLoader::new(
  //       "https://maple-res.kkkiiox.work/MapLatest/MapHelper.img/minimap",
  //     ),
  //   }),
  // )
}

///|
pub async fn load_map_node(map_id : Int) -> @resource.NxNode {
  guard map_id >= 0
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  get_mapx_loader().load_res_async(path)
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
