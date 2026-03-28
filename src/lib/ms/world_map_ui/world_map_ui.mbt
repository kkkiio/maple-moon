///|
using @struct {type Point}

///|
priv struct Hitbox {
  left : Int
  top : Int
  width : Int
  height : Int
}

///|
priv enum ButtonId {
  CLOSE
  SEARCH
  SEARCH_CLOSE
  ALL_SEARCH
} derive(Eq, Hash)

///|
priv struct ButtonStateResource {
  normal : @ms_animation.Animation
  mouse_over : @ms_animation.Animation
  pressed : @ms_animation.Animation
  disabled : @ms_animation.Animation
  normal_texture : @resource.NxTexture
}

///|
priv struct WorldMapUIResource {
  border_texture : @resource.NxTexture
  search_background_texture : @resource.NxTexture
  search_notice_texture : @resource.NxTexture
  title_texture : @resource.NxTexture
  close_hitbox : Hitbox
  button_resources : Map[ButtonId, ButtonStateResource]
}

///|
priv struct WorldMapMarkerResource {
  cur_pos : @ms_animation.Animation
  npc_pos : Array[@ms_animation.Animation]
  map_images : Array[@resource.NxTexture]
  map_image_sizes : Array[(Int, Int)]
}

///|
priv struct WorldMapTooltipResource {
  line : @resource.NxTexture
  mob : @resource.NxTexture
  npc : @resource.NxTexture
  party : @resource.NxTexture
}

///|
priv struct WorldMapLink {
  link_img_texture : @resource.NxTexture
  link_map : String
  // tooltip : String
}

///|
priv struct WorldMapSpot {
  title : String
  description : String
  bolded : Bool
  path_texture : @resource.NxTexture?
  spot_x : Int
  spot_y : Int
  type_ : Int
  map_ids : Array[Int]
}

///|
priv struct WorldMapPageResource {
  name : String
  base_img_texture : @resource.NxTexture
  parent_map : String
  map_links : Array[WorldMapLink]
  map_spots : Array[WorldMapSpot]
}

///|
priv struct NxWorldMapSearch {
  background : @resource.NxTexture
  notice : @resource.NxTexture
}

///|
impl @json.FromJson for NxWorldMapSearch with from_json(json, path) -> NxWorldMapSearch raise @json.JsonDecodeError {
  match json {
    { "backgrnd": background, "notice": notice, .. } =>
      {
        background: @json.from_json(background, path=path.add_key("backgrnd")),
        notice: @json.from_json(notice, path=path.add_key("notice")),
      }
    _ => raise @json.JsonDecodeError((path, "invalid world map search"))
  }
}

///|
priv struct NxWorldMapUI {
  border : @resource.NxAnimation
  bt_search : @ui.NxMapleButton
  bt_all : @ui.NxMapleButton
  bt_auto_fly : @ui.NxMapleButton
  bt_navi_register : @ui.NxMapleButton
  search : NxWorldMapSearch
  title : @resource.NxTexture
}

///|
impl @json.FromJson for NxWorldMapUI with from_json(json, path) -> NxWorldMapUI raise @json.JsonDecodeError {
  match json {
    {
      "Border": border,
      "BtSearch": bt_search,
      "BtAll": bt_all,
      "BtAutoFly_1": bt_auto_fly,
      "BtNaviRegister": bt_navi_register,
      "WorldMapSearch": search,
      "title": title,
      ..
    } =>
      {
        border: @json.from_json(border, path=path.add_key("Border")),
        bt_search: @json.from_json(bt_search, path=path.add_key("BtSearch")),
        bt_all: @json.from_json(bt_all, path=path.add_key("BtAll")),
        bt_auto_fly: @json.from_json(
          bt_auto_fly,
          path=path.add_key("BtAutoFly_1"),
        ),
        bt_navi_register: @json.from_json(
          bt_navi_register,
          path=path.add_key("BtNaviRegister"),
        ),
        search: @json.from_json(search, path=path.add_key("WorldMapSearch")),
        title: @json.from_json(title, path=path.add_key("title")),
      }
    _ => raise @json.JsonDecodeError((path, "invalid UIWindow2 WorldMap json"))
  }
}

///|
priv struct NxWorldMapMarker {
  cur_pos : @resource.NxAnimation
  npc_pos0 : @resource.NxAnimation
  npc_pos1 : @resource.NxAnimation
  npc_pos2 : @resource.NxAnimation
  npc_pos3 : @resource.NxAnimation
  map_image0 : @resource.NxTexture
  map_image1 : @resource.NxTexture
  map_image2 : @resource.NxTexture
  map_image3 : @resource.NxTexture
}

///|
impl @json.FromJson for NxWorldMapMarker with from_json(json, path) -> NxWorldMapMarker raise @json.JsonDecodeError {
  match json {
    {
      "curPos": cur_pos,
      "npcPos0": npc_pos0,
      "npcPos1": npc_pos1,
      "npcPos2": npc_pos2,
      "npcPos3": npc_pos3,
      "mapImage": {
        "0": map_image0,
        "1": map_image1,
        "2": map_image2,
        "3": map_image3,
        ..
      },
      ..
    } =>
      {
        cur_pos: @json.from_json(cur_pos, path=path.add_key("curPos")),
        npc_pos0: @json.from_json(npc_pos0, path=path.add_key("npcPos0")),
        npc_pos1: @json.from_json(npc_pos1, path=path.add_key("npcPos1")),
        npc_pos2: @json.from_json(npc_pos2, path=path.add_key("npcPos2")),
        npc_pos3: @json.from_json(npc_pos3, path=path.add_key("npcPos3")),
        map_image0: @json.from_json(
          map_image0,
          path=path.add_key("mapImage").add_key("0"),
        ),
        map_image1: @json.from_json(
          map_image1,
          path=path.add_key("mapImage").add_key("1"),
        ),
        map_image2: @json.from_json(
          map_image2,
          path=path.add_key("mapImage").add_key("2"),
        ),
        map_image3: @json.from_json(
          map_image3,
          path=path.add_key("mapImage").add_key("3"),
        ),
      }
    _ => raise @json.JsonDecodeError((path, "invalid world map marker json"))
  }
}

///|
priv struct NxWorldMapToolTip {
  line : @resource.NxTexture
  mob : @resource.NxTexture
  npc : @resource.NxTexture
  party : @resource.NxTexture
}

///|
impl @json.FromJson for NxWorldMapToolTip with from_json(json, path) -> NxWorldMapToolTip raise @json.JsonDecodeError {
  match json {
    { "Line": line, "Mob": mob, "Npc": npc, "Party": party, .. } =>
      {
        line: @json.from_json(line, path=path.add_key("Line")),
        mob: @json.from_json(mob, path=path.add_key("Mob")),
        npc: @json.from_json(npc, path=path.add_key("Npc")),
        party: @json.from_json(party, path=path.add_key("Party")),
      }
    { "WorldMap": world_map, .. } =>
      @json.from_json(world_map, path=path.add_key("WorldMap"))
    _ => raise @json.JsonDecodeError((path, "invalid UIWindow2 ToolTip json"))
  }
}

///|
priv struct NxWorldMapLinkInner {
  link_img : @resource.NxTexture
  link_map : String
}

///|
impl @json.FromJson for NxWorldMapLinkInner with from_json(json, path) -> NxWorldMapLinkInner raise @json.JsonDecodeError {
  match json {
    { "linkImg": link_img, "linkMap": String(link_map), .. } =>
      {
        link_img: @json.from_json(link_img, path=path.add_key("linkImg")),
        link_map,
      }
    _ => raise @json.JsonDecodeError((path, "invalid world map link inner"))
  }
}

///|
priv struct NxWorldMapLink {
  link : NxWorldMapLinkInner
  tooltip : String
}

///|
impl @json.FromJson for NxWorldMapLink with from_json(json, path) -> NxWorldMapLink raise @json.JsonDecodeError {
  match json {
    { "link": link, "toolTip": String(tooltip), .. } =>
      { link: @json.from_json(link, path=path.add_key("link")), tooltip }
    _ => raise @json.JsonDecodeError((path, "invalid world map link"))
  }
}

///|
priv struct NxWorldMapSpot {
  title : String?
  desc : String?
  path : @resource.NxTexture?
  spot_x : Int
  spot_y : Int
  type_ : Int
  map_ids : Array[Int]
}

///|
impl @json.FromJson for NxWorldMapSpot with from_json(json, path) -> NxWorldMapSpot raise @json.JsonDecodeError {
  match json {
    { "mapNo": map_no, "spot": [spot_x, spot_y], "type": type_, .. } => {
      let title = match json {
        { "title": String(title), .. } => Some(title)
        _ => None
      }
      let desc = match json {
        { "desc": String(desc), .. } => Some(desc)
        _ => None
      }
      let path_texture = match json {
        { "path": path_json, .. } =>
          Some(@json.from_json(path_json, path=path.add_key("path")))
        _ => None
      }
      {
        title,
        desc,
        path: path_texture,
        spot_x: parse_int_value(spot_x) catch {
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("spot").add_key("0"), "invalid spot x"),
            )
        },
        spot_y: parse_int_value(spot_y) catch {
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("spot").add_key("1"), "invalid spot y"),
            )
        },
        type_: parse_int_value(type_) catch {
          _ =>
            raise @json.JsonDecodeError((path.add_key("type"), "invalid type"))
        },
        map_ids: parse_map_ids(map_no) catch {
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("mapNo"), "invalid mapNo"),
            )
        },
      }
    }
    _ => raise @json.JsonDecodeError((path, "invalid world map spot"))
  }
}

///|
priv struct NxWorldMapInfo {
  parent_map : String
}

///|
impl @json.FromJson for NxWorldMapInfo with from_json(json, path) -> NxWorldMapInfo raise @json.JsonDecodeError {
  match json {
    { "parentMap": String(parent_map), .. } => { parent_map, }
    _ => raise @json.JsonDecodeError((path, "missing field parentMap"))
  }
}

///|
priv struct NxWorldMapPage {
  base_img : @resource.NxAnimation
  map_links : Array[NxWorldMapLink]
  map_spots : Array[NxWorldMapSpot]
  info : NxWorldMapInfo
}

///|
impl @json.FromJson for NxWorldMapPage with from_json(json, path) -> NxWorldMapPage raise @json.JsonDecodeError {
  match json {
    { "BaseImg": base_img, "MapList": map_list, "info": info, .. } => {
      let map_links = match json {
        { "MapLink": map_link, .. } =>
          @resource.parse_map_based_array(
            map_link,
            path=path.add_key("MapLink"),
          )
        _ => []
      }
      {
        base_img: @json.from_json(base_img, path=path.add_key("BaseImg")),
        map_links,
        map_spots: @resource.parse_map_based_array(
          map_list,
          path=path.add_key("MapList"),
        ),
        info: @json.from_json(info, path=path.add_key("info")),
      }
    }
    _ => raise @json.JsonDecodeError((path, "invalid WorldMap page json"))
  }
}

///|
priv struct UiResources {
  ui : WorldMapUIResource
  marker : WorldMapMarkerResource
  tooltip : WorldMapTooltipResource
}

///|
priv struct State {
  mut visible : Bool
  mut panel_x : Int
  mut panel_y : Int
  mut current_map_id : Int
  mut current_map_name : String
  mut current_street_name : String
  mut current_world_name : String
  mut current_user_root_world_name : String
  mut search_visible : Bool
  mut hovered_spot_index : Int?
  mut hovered_link_index : Int?
  mut pressed_button : ButtonId?
  mut ui_resources : UiResources?
  mut ui_loading : @utils.Future[Result[UiResources, Error]]?
  mut current_page : WorldMapPageResource?
  mut page_loading : @utils.Future[
    Result[(String, WorldMapPageResource), Error],
  ]?
  page_cache : Map[String, WorldMapPageResource]
  render_entities : Array[@entity.Entity]
  mut dirty : Bool
}

///|
let state_ref : Ref[State] = Ref::new({
  visible: false,
  panel_x: 84,
  panel_y: 24,
  current_map_id: 100000000,
  current_map_name: "",
  current_street_name: "",
  current_world_name: "",
  current_user_root_world_name: "",
  search_visible: false,
  hovered_spot_index: None,
  hovered_link_index: None,
  pressed_button: None,
  ui_resources: None,
  ui_loading: None,
  current_page: None,
  page_loading: None,
  page_cache: {},
  render_entities: [],
  dirty: false,
})

///|
let ui_json_for_test_ref : Ref[Json?] = Ref::new(None)

///|
let tooltip_json_for_test_ref : Ref[Json?] = Ref::new(None)

///|
let map_helper_json_for_test_ref : Ref[Json?] = Ref::new(None)

///|
let world_map_pages_for_test_ref : Ref[Map[String, Json]] = Ref::new({})

///|
let cleanup_registered_ref : Ref[Bool] = Ref::new(false)

///|
const PANEL_BORDER_Z : Int = @graphics.UI_ZINDEX

///|
const PAGE_Z : Int = PANEL_BORDER_Z + 1

///|
const OVERLAY_Z : Int = PANEL_BORDER_Z + 2

///|
const MARKER_Z : Int = PANEL_BORDER_Z + 3

///|
const CUR_POS_Z : Int = PANEL_BORDER_Z + 4

///|
const TOOLTIP_Z : Int = PANEL_BORDER_Z + 5

///|
const BASE_POSITION_Y_OFFSET : Int = 15

///|
const TOOLTIP_WIDTH : Int = 251

///|
const TOOLTIP_HEIGHT : Int = 52

///|
fn truncate_text(text : String, max_len : Int) -> String {
  if text.length() <= max_len {
    return text
  }
  text[:max_len].to_string() + "..."
}

///|
fn clear_entities(entities : Array[@entity.Entity]) -> Unit {
  for entity in entities {
    @sprite.sprites().remove(entity) |> ignore
    @transform2d.remove(entity) |> ignore
    entity.destroy()
  }
  entities.clear()
}

///|
fn clear_scene(reason_is_change_map : Bool) -> Unit {
  let state = state_ref.val
  clear_entities(state.render_entities)
  state.hovered_spot_index = None
  state.hovered_link_index = None
  state.pressed_button = None
  state.current_page = None
  state.page_loading = None
  state.page_cache.clear()
  state.visible = false
  state.search_visible = false
  if !reason_is_change_map {
    state.ui_resources = None
    state.ui_loading = None
  }
}

///|
pub fn clear_for_change_map() -> Unit {
  clear_scene(true)
}

///|
pub fn clear_for_leave_world() -> Unit {
  clear_scene(false)
}

///|
fn register_scene_cleanup_once() -> Unit {
  if cleanup_registered_ref.val {
    return
  }
  cleanup_registered_ref.val = true
}

///|
fn make_button_state_resource(src : @ui.NxMapleButton) -> ButtonStateResource {
  {
    normal: @ms_animation.from_nx_animation(src.normal),
    mouse_over: @ms_animation.from_nx_animation(src.mouse_over),
    pressed: @ms_animation.from_nx_animation(src.pressed),
    disabled: @ms_animation.from_nx_animation(src.disabled),
    normal_texture: src.normal.frames[0].texture,
  }
}

///|
fn parse_world_map_ui_resource(json : Json) -> WorldMapUIResource raise {
  let src : NxWorldMapUI = @json.from_json(json)
  let border_texture = src.border.frames[0].texture
  let search_background_texture = src.search.background
  let search_notice_texture = src.search.notice
  let title_texture = src.title
  let close_hitbox = {
    left: border_texture.w - 22,
    top: 4,
    width: 16,
    height: 16,
  }
  let button_resources : Map[ButtonId, ButtonStateResource] = {}
  button_resources[ButtonId::SEARCH] = make_button_state_resource(src.bt_search)
  button_resources[ButtonId::SEARCH_CLOSE] = make_button_state_resource(
    src.bt_search,
  )
  button_resources[ButtonId::ALL_SEARCH] = make_button_state_resource(
    src.bt_all,
  )
  button_resources[ButtonId::CLOSE] = {
    normal: button_resources[ButtonId::SEARCH].normal,
    mouse_over: button_resources[ButtonId::SEARCH].mouse_over,
    pressed: button_resources[ButtonId::SEARCH].pressed,
    disabled: button_resources[ButtonId::SEARCH].disabled,
    normal_texture: button_resources[ButtonId::SEARCH].normal_texture,
  }
  ignore(make_button_state_resource(src.bt_auto_fly))
  ignore(make_button_state_resource(src.bt_navi_register))
  {
    border_texture,
    search_background_texture,
    search_notice_texture,
    title_texture,
    close_hitbox,
    button_resources,
  }
}

///|
fn parse_world_map_marker_resource(json : Json) -> WorldMapMarkerResource raise {
  let src : NxWorldMapMarker = @json.from_json(json)
  let npc_pos = [
    @ms_animation.from_nx_animation(src.npc_pos0, loop_=true),
    @ms_animation.from_nx_animation(src.npc_pos1, loop_=true),
    @ms_animation.from_nx_animation(src.npc_pos2, loop_=true),
    @ms_animation.from_nx_animation(src.npc_pos3, loop_=true),
  ]
  let map_textures = [
    src.map_image0,
    src.map_image1,
    src.map_image2,
    src.map_image3,
  ]
  let map_images = []
  let map_image_sizes = []
  for texture in map_textures {
    map_images.push(texture)
    map_image_sizes.push((texture.w, texture.h))
  }
  {
    cur_pos: @ms_animation.from_nx_animation(src.cur_pos, loop_=true),
    npc_pos,
    map_images,
    map_image_sizes,
  }
}

///|
fn parse_world_map_tooltip_resource(
  json : Json,
) -> WorldMapTooltipResource raise {
  let src : NxWorldMapToolTip = @json.from_json(json)
  { line: src.line, mob: src.mob, npc: src.npc, party: src.party }
}

///|
fn parse_map_ids(json : Json) -> Array[Int] raise {
  match json {
    Object(obj) => {
      let ids = []
      for _, value in obj {
        match value {
          String(id) => ids.push(@strconv.parse_int(id))
          Number(id, ..) => ids.push(id.to_int())
          _ => fail("invalid mapNo entry")
        }
      }
      ids
    }
    _ => fail("missing mapNo")
  }
}

///|
fn parse_int_value(json : Json) -> Int raise {
  match json {
    Number(value, ..) => value.to_int()
    String(value) => @strconv.parse_int(value)
    _ => fail("invalid int json")
  }
}

///|
fn fallback_map_label(map_id : Int) -> (String, String) {
  ("\{map_id}", "")
}

///|
fn parse_world_map_page_resource(
  name : String,
  json : Json,
  marker : WorldMapMarkerResource,
) -> WorldMapPageResource raise {
  let src : NxWorldMapPage = @json.from_json(json)
  let base_img_texture = src.base_img.frames[0].texture
  let map_links = []
  for link in src.map_links {
    map_links.push({
      link_img_texture: link.link.link_img,
      link_map: link.link.link_map,
      // tooltip: link.tooltip,
    })
  }
  let map_spots = []
  for spot in src.map_spots {
    let type_ = spot.type_
    if type_ < 0 || type_ >= 4 {
      fail("invalid world map spot type")
    }
    let (title, description, bolded) = match (spot.title, spot.desc) {
      (Some(title), Some(description)) => (title, description, false)
      (Some(title), None) => (title, "", false)
      _ => {
        let (map_name, street_name) = fallback_map_label(spot.map_ids[0])
        ("\{street_name} : \{map_name}", "", true)
      }
    }
    let path_texture = spot.path
    ignore(marker.map_images[type_])
    map_spots.push({
      title,
      description,
      bolded,
      path_texture,
      spot_x: spot.spot_x,
      spot_y: spot.spot_y,
      type_,
      map_ids: spot.map_ids,
    })
  }
  {
    name,
    base_img_texture,
    parent_map: src.info.parent_map,
    map_links,
    map_spots,
  }
}

///|
async fn load_ui_resources(
  ui_json : Json?,
  tooltip_json : Json?,
  map_helper_json : Json?,
) -> UiResources {
  let ui_json = match ui_json {
    Some(json) => json
    None =>
      @resource.require_async_loader("ui_window_2").load_resource(["WorldMap"])
  }
  let tooltip_json = match tooltip_json {
    Some(json) => json
    None =>
      @resource.require_async_loader("ui_window_2").load_resource([
        "ToolTip", "WorldMap",
      ])
  }
  let map_helper_json = match map_helper_json {
    Some(json) => json
    None =>
      @resource.require_async_loader("map_latest").load_resource([
        "MapHelper.img", "worldMap",
      ])
  }
  let ui = parse_world_map_ui_resource(ui_json)
  let marker = parse_world_map_marker_resource(map_helper_json)
  let tooltip = parse_world_map_tooltip_resource(tooltip_json)
  { ui, marker, tooltip }
}

///|
async fn load_world_map_page(
  name : String,
  marker : WorldMapMarkerResource,
  injected_json : Json?,
) -> (String, WorldMapPageResource) {
  let json = match injected_json {
    Some(json) => json
    None =>
      @resource.require_async_loader("map_world_map").load_resource([
        "\{name}.img",
      ])
  }
  (name, parse_world_map_page_resource(name, json, marker))
}

///|
fn page_base_position(state : State, ui : WorldMapUIResource) -> Point[Int] {
  Point::new(
    state.panel_x + ui.border_texture.w / 2,
    state.panel_y + ui.border_texture.h / 2 + BASE_POSITION_Y_OFFSET,
  )
}

///|
fn make_hitbox(left : Int, top : Int, width : Int, height : Int) -> Hitbox {
  { left, top, width, height }
}

///|
fn point_in_hitbox(hitbox : Hitbox, pos : @selene_math.Vec2D) -> Bool {
  let @selene_math.Vec2D(x, y) = pos
  let x = x.to_int()
  let y = y.to_int()
  x >= hitbox.left &&
  x < hitbox.left + hitbox.width &&
  y >= hitbox.top &&
  y < hitbox.top + hitbox.height
}

///|
fn button_hitbox(
  state : State,
  texture : @resource.NxTexture,
  extra_x? : Int = 0,
) -> Hitbox {
  make_hitbox(
    state.panel_x + extra_x - texture.origin.x,
    state.panel_y - texture.origin.y,
    texture.w,
    texture.h,
  )
}

///|
fn search_offset(ui : WorldMapUIResource) -> Int {
  ui.border_texture.w
}

///|
fn current_root_world_name(map_id : Int) -> String {
  "WorldMap0\{map_id / 10000000}"
}

///|
fn open_world_name(state : State, name : String) -> Unit {
  if state.current_world_name == name && state.current_page is Some(_) {
    return
  }
  state.current_world_name = name
  state.current_page = None
  state.page_loading = None
  state.hovered_spot_index = None
  state.hovered_link_index = None
  state.dirty = true
}

///|
fn ensure_page_loading(state : State, resources : UiResources) -> Unit {
  guard state.current_page is None else { return }
  if state.page_cache.get(state.current_world_name) is Some(page) {
    state.current_page = Some(page)
    state.dirty = true
    return
  }
  if world_map_pages_for_test_ref.val.get(state.current_world_name)
    is Some(json) {
    let page = parse_world_map_page_resource(
      state.current_world_name,
      json,
      resources.marker,
    ) catch {
      _ => panic()
    }
    state.page_cache[state.current_world_name] = page
    state.current_page = Some(page)
    state.dirty = true
    return
  }
  guard state.page_loading is None else { return }
  let current_name = state.current_world_name
  let injected_json = world_map_pages_for_test_ref.val.get(current_name)
  state.page_loading = Some(
    @io_service.submit_background_task(async fn() {
      load_world_map_page(current_name, resources.marker, injected_json)
    }),
  )
}

///|
fn poll_ui_resources(state : State) -> Bool {
  guard state.ui_resources is None else { return false }
  if ui_json_for_test_ref.val is Some(ui_json) &&
    tooltip_json_for_test_ref.val is Some(tooltip_json) &&
    map_helper_json_for_test_ref.val is Some(map_helper_json) {
    let resources = {
      ui: parse_world_map_ui_resource(ui_json),
      marker: parse_world_map_marker_resource(map_helper_json),
      tooltip: parse_world_map_tooltip_resource(tooltip_json),
    } catch {
      _ => panic()
    }
    state.ui_resources = Some(resources)
    state.ui_loading = None
    return true
  }
  match state.ui_loading {
    Some(future) =>
      match future.poll() {
        Some(Ok(resources)) => {
          state.ui_loading = None
          state.ui_resources = Some(resources)
          true
        }
        Some(Err(err)) =>
          @log.fatal("failed to load world map ui resources", data={
            "error": err.to_string(),
          })
        None => false
      }
    None => {
      let ui_json = ui_json_for_test_ref.val
      let tooltip_json = tooltip_json_for_test_ref.val
      let map_helper_json = map_helper_json_for_test_ref.val
      state.ui_loading = Some(
        @io_service.submit_background_task(async fn() {
          load_ui_resources(ui_json, tooltip_json, map_helper_json)
        }),
      )
      false
    }
  }
}

///|
fn poll_page_loading(state : State) -> Bool {
  guard state.page_loading is Some(future) else { return false }
  match future.poll() {
    Some(Ok((name, page))) => {
      state.page_loading = None
      state.page_cache[name] = page
      if state.current_world_name == name {
        state.current_page = Some(page)
      }
      true
    }
    Some(Err(err)) =>
      @log.fatal("failed to load world map page", data={
        "error": err.to_string(),
        "page": state.current_world_name,
      })
    None => false
  }
}

///|
fn resolve_hover(
  state : State,
  resources : UiResources,
  page : WorldMapPageResource,
) -> Unit {
  state.hovered_spot_index = None
  state.hovered_link_index = None
  let pos = @inputs.mouse.pos
  let base_pos = page_base_position(state, resources.ui)
  for i in 0..<page.map_links.length() {
    let link = page.map_links[i]
    let hitbox = make_hitbox(
      base_pos.x - link.link_img_texture.origin.x,
      base_pos.y - link.link_img_texture.origin.y,
      link.link_img_texture.w,
      link.link_img_texture.h,
    )
    if point_in_hitbox(hitbox, pos) {
      state.hovered_link_index = Some(i)
      return
    }
  }
  for i in 0..<page.map_spots.length() {
    let spot = page.map_spots[i]
    let (marker_w, marker_h) = resources.marker.map_image_sizes[spot.type_]
    let hitbox = make_hitbox(
      base_pos.x + spot.spot_x - 10,
      base_pos.y + spot.spot_y - 10,
      marker_w,
      marker_h,
    )
    if point_in_hitbox(hitbox, pos) {
      state.hovered_spot_index = Some(i)
      return
    }
  }
}

///|
fn handle_click(
  state : State,
  resources : UiResources,
  page : WorldMapPageResource,
) -> Bool {
  let pos = @inputs.mouse.pos
  let search_button = button_hitbox(
    state,
    resources.ui.button_resources[ButtonId::SEARCH].normal_texture,
  )
  let all_search_button = button_hitbox(
    state,
    resources.ui.button_resources[ButtonId::ALL_SEARCH].normal_texture,
    extra_x=search_offset(resources.ui),
  )
  let close_hitbox = make_hitbox(
    state.panel_x + resources.ui.close_hitbox.left,
    state.panel_y + resources.ui.close_hitbox.top,
    resources.ui.close_hitbox.width,
    resources.ui.close_hitbox.height,
  )
  if point_in_hitbox(close_hitbox, pos) {
    set_world_map_visible(false)
    return true
  }
  if point_in_hitbox(search_button, pos) {
    state.search_visible = not(state.search_visible)
    state.dirty = true
    return true
  }
  if state.search_visible && point_in_hitbox(all_search_button, pos) {
    return true
  }
  match state.hovered_link_index {
    Some(index) => {
      open_world_name(state, page.map_links[index].link_map)
      return true
    }
    None => false
  }
}

///|
fn handle_escape(state : State) -> Unit {
  if state.search_visible {
    state.search_visible = false
    state.dirty = true
    return
  }
  match state.current_page {
    Some(page) =>
      if page.parent_map != "" {
        open_world_name(state, page.parent_map)
      } else {
        set_world_map_visible(false)
      }
    None => set_world_map_visible(false)
  }
}

///|
fn spawn_sprite(
  state : State,
  sprite : @sprite.Sprite,
  x : Int,
  y : Int,
) -> Unit {
  let entity = @entity.Entity::new()
  state.render_entities.push(entity)
  @sprite.sprites().set(entity, sprite)
  @transform2d.set_xy(entity, @selene_math.Vec2D(x.to_double(), y.to_double()))
}

///|
fn spawn_rect(
  state : State,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  color : String,
  z : Int,
) -> Unit {
  let entity = @entity.Entity::new()
  state.render_entities.push(entity)
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_color(
      @sprite.color_from_css(color),
      @selene_math.Vec2D(width.to_double(), height.to_double()),
    ),
  )
  @transform.transforms().set(
    entity,
    @transform.Transform::from_xyz(x.to_double(), y.to_double(), z.to_double()),
  )
}

///|
fn spawn_texture(
  state : State,
  texture : @resource.NxTexture,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  let animation = @ms_animation.Animation::single_frame_from_image(
    @asset.load_image(texture.i),
    @selene_math.Vec2D(texture.w.to_double(), texture.h.to_double()),
    offset=@selene_math.Vec2D(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    pivot=@selene_math.Vec2D(
      texture.origin.x.to_double(),
      texture.origin.y.to_double(),
    ),
  )
  spawn_sprite(state, @ms_animation.sprite_from_animation(animation, z), x, y)
}

///|
fn spawn_animation(
  state : State,
  animation : @ms_animation.Animation,
  x : Int,
  y : Int,
  z : Int,
) -> Unit {
  spawn_sprite(state, @ms_animation.sprite_from_animation(animation, z), x, y)
}

///|
fn spawn_text(
  state : State,
  text : String,
  x : Int,
  y : Int,
  z : Int,
  color? : String = "#f3f6fb",
  font? : String = "11px Menlo",
) -> Unit {
  let entity = @entity.Entity::new()
  state.render_entities.push(entity)
  @selene_ui.nodes().set(
    entity,
    @selene_ui.Node::absolute(
      @selene_math.Vec2D(x.to_double(), y.to_double()),
      size=@selene_math.Vec2D(320.0, 20.0),
    ),
  )
  @selene_ui.z_indexes().set(entity, @selene_ui.ZIndex::new(z))
  @selene_ui.texts().set(entity, @selene_ui.Text::new(text))
  @selene_ui.text_fonts().set(entity, @selene_ui.TextFont::from_css(font))
  @selene_ui.text_colors().set(entity, @selene_ui.TextColor::from_css(color))
  @selene_ui.text_layouts().set(
    entity,
    @selene_ui.TextLayout::new(
      align=@selene_math.Left,
      baseline=@selene_math.Top,
    ),
  )
}

///|
fn render_tooltip(
  state : State,
  resources : UiResources,
  page : WorldMapPageResource,
  spot_index : Int,
) -> Unit {
  let spot = page.map_spots[spot_index]
  let base_pos = page_base_position(state, resources.ui)
  let tooltip_x = base_pos.x + spot.spot_x + 24
  let tooltip_y = base_pos.y + spot.spot_y - 8
  spawn_rect(
    state,
    tooltip_x,
    tooltip_y,
    TOOLTIP_WIDTH,
    TOOLTIP_HEIGHT,
    "rgba(20, 28, 42, 0.9)",
    TOOLTIP_Z,
  )
  spawn_rect(
    state,
    tooltip_x,
    tooltip_y,
    TOOLTIP_WIDTH,
    1,
    "rgba(255, 255, 255, 0.25)",
    TOOLTIP_Z + 1,
  )
  spawn_texture(
    state,
    resources.tooltip.line,
    tooltip_x,
    tooltip_y + 22,
    TOOLTIP_Z + 1,
  )
  spawn_texture(
    state,
    resources.tooltip.mob,
    tooltip_x + 8,
    tooltip_y + 31,
    TOOLTIP_Z + 1,
  )
  spawn_texture(
    state,
    resources.tooltip.npc,
    tooltip_x + 24,
    tooltip_y + 31,
    TOOLTIP_Z + 1,
  )
  spawn_texture(
    state,
    resources.tooltip.party,
    tooltip_x + 40,
    tooltip_y + 31,
    TOOLTIP_Z + 1,
  )
  spawn_text(
    state,
    truncate_text(spot.title, 28),
    tooltip_x + 8,
    tooltip_y + 6,
    TOOLTIP_Z + 2,
    font="bold 11px Menlo",
  )
  let detail_text = if spot.description == "" {
    "Map ID: \{spot.map_ids[0]}"
  } else {
    truncate_text(spot.description, 34)
  }
  spawn_text(
    state,
    detail_text,
    tooltip_x + 8,
    tooltip_y + 24,
    TOOLTIP_Z + 2,
    color="#d7e1ee",
    font="10px Menlo",
  )
  spawn_text(
    state,
    "Map ID: \{spot.map_ids[0]}",
    tooltip_x + 56,
    tooltip_y + 31,
    TOOLTIP_Z + 2,
    color="#9fc0df",
    font="10px Menlo",
  )
}

///|
fn render_world_map(state : State) -> Unit {
  clear_entities(state.render_entities)
  guard state.ui_resources is Some(resources) else { return }
  guard state.current_page is Some(page) else { return }
  let base_pos = page_base_position(state, resources.ui)
  spawn_texture(
    state,
    resources.ui.border_texture,
    state.panel_x,
    state.panel_y,
    PANEL_BORDER_Z,
  )
  spawn_texture(
    state,
    resources.ui.title_texture,
    state.panel_x + 15,
    state.panel_y + 8,
    PAGE_Z,
  )
  let search_button_resource = resources.ui.button_resources[ButtonId::SEARCH]
  let search_button_sprite = match state.pressed_button {
    Some(ButtonId::SEARCH) => search_button_resource.pressed
    _ =>
      if state.search_visible {
        search_button_resource.mouse_over
      } else {
        search_button_resource.normal
      }
  }
  spawn_animation(
    state,
    search_button_sprite,
    state.panel_x,
    state.panel_y,
    PAGE_Z,
  )
  spawn_texture(state, page.base_img_texture, base_pos.x, base_pos.y, PAGE_Z)
  if state.search_visible {
    let offset_x = search_offset(resources.ui)
    spawn_texture(
      state,
      resources.ui.search_background_texture,
      state.panel_x + offset_x,
      state.panel_y,
      PAGE_Z,
    )
    spawn_texture(
      state,
      resources.ui.search_notice_texture,
      state.panel_x + offset_x,
      state.panel_y,
      PAGE_Z + 1,
    )
    let all_search = resources.ui.button_resources[ButtonId::ALL_SEARCH]
    spawn_animation(
      state,
      all_search.normal,
      state.panel_x + offset_x,
      state.panel_y,
      PAGE_Z + 1,
    )
  }
  match state.hovered_link_index {
    Some(index) => {
      let link = page.map_links[index]
      spawn_texture(
        state,
        link.link_img_texture,
        base_pos.x,
        base_pos.y,
        OVERLAY_Z,
      )
    }
    None => ()
  }
  match state.hovered_spot_index {
    Some(index) =>
      match page.map_spots[index].path_texture {
        Some(path_texture) => {
          spawn_texture(state, path_texture, base_pos.x, base_pos.y, OVERLAY_Z)
          render_tooltip(state, resources, page, index)
        }
        None => render_tooltip(state, resources, page, index)
      }
    None => ()
  }
  for spot in page.map_spots {
    spawn_texture(
      state,
      resources.marker.map_images[spot.type_],
      base_pos.x + spot.spot_x,
      base_pos.y + spot.spot_y,
      MARKER_Z,
    )
    if spot.map_ids.contains(state.current_map_id) {
      spawn_animation(
        state,
        resources.marker.npc_pos[spot.type_],
        base_pos.x + spot.spot_x,
        base_pos.y + spot.spot_y,
        CUR_POS_Z,
      )
      spawn_animation(
        state,
        resources.marker.cur_pos,
        base_pos.x + spot.spot_x,
        base_pos.y + spot.spot_y,
        CUR_POS_Z + 1,
      )
    }
  }
}

///|
fn ensure_root_page(state : State) -> Unit {
  if state.current_user_root_world_name == "" {
    let root = current_root_world_name(state.current_map_id)
    state.current_user_root_world_name = root
    state.current_world_name = root
  }
  if state.current_world_name == "" {
    state.current_world_name = state.current_user_root_world_name
  }
}

///|
/// Sets the current player map context used by the world map UI.
pub fn set_current_map(
  map_id : Int,
  map_name : String,
  street_name : String,
) -> Unit {
  register_scene_cleanup_once()
  let state = state_ref.val
  state.current_map_id = map_id
  state.current_map_name = map_name
  state.current_street_name = street_name
  let root = current_root_world_name(map_id)
  state.current_user_root_world_name = root
  state.current_world_name = root
  state.current_page = None
  state.page_loading = None
  state.hovered_spot_index = None
  state.hovered_link_index = None
  state.dirty = true
}

///|
/// Sets whether the world map panel is visible.
pub fn set_world_map_visible(visible : Bool) -> Unit {
  register_scene_cleanup_once()
  let state = state_ref.val
  if state.visible == visible {
    return
  }
  state.visible = visible
  state.hovered_spot_index = None
  state.hovered_link_index = None
  state.pressed_button = None
  if visible {
    let root = current_root_world_name(state.current_map_id)
    state.current_user_root_world_name = root
    open_world_name(state, root)
  } else {
    clear_entities(state.render_entities)
    state.search_visible = false
  }
  state.dirty = true
}

///|
/// Toggles world map visibility.
pub fn toggle_world_map() -> Unit {
  let state = state_ref.val
  set_world_map_visible(not(state.visible))
}

///|
/// Injects `UIWindow2.img/WorldMap.json` for tests.
pub fn set_world_map_ui_json_for_test(json : Json) -> Unit {
  ui_json_for_test_ref.val = Some(json)
  let state = state_ref.val
  state.ui_resources = None
  state.ui_loading = None
  state.dirty = true
}

///|
/// Injects `UIWindow2.img/ToolTip.json` for tests.
pub fn set_world_map_tooltip_json_for_test(json : Json) -> Unit {
  tooltip_json_for_test_ref.val = Some(json)
  let state = state_ref.val
  state.ui_resources = None
  state.ui_loading = None
  state.dirty = true
}

///|
/// Injects `MapHelper.img/worldMap` for tests.
pub fn set_map_helper_world_map_json_for_test(json : Json) -> Unit {
  map_helper_json_for_test_ref.val = Some(json)
  let state = state_ref.val
  state.ui_resources = None
  state.ui_loading = None
  state.dirty = true
}

///|
/// Injects a `Map/WorldMap/<name>.img.json` page for tests.
pub fn set_world_map_json_for_test(name : String, json : Json) -> Unit {
  world_map_pages_for_test_ref.val[name] = json
  let state = state_ref.val
  state.page_cache.remove(name) |> ignore
  state.page_loading = None
  if state.current_world_name == name {
    state.current_page = None
  }
  state.dirty = true
}

///|
/// Sets panel position for tests.
pub fn set_world_map_panel_position_for_test(x : Int, y : Int) -> Unit {
  let state = state_ref.val
  state.panel_x = x
  state.panel_y = y
  state.dirty = true
}

///|
/// Sets the hovered spot index for render snapshot tests.
pub fn set_hovered_spot_index_for_test(index : Int?) -> Unit {
  let state = state_ref.val
  state.hovered_spot_index = index
  state.hovered_link_index = None
  state.dirty = true
}

///|
/// Sets the hovered link index for render snapshot tests.
pub fn set_hovered_link_index_for_test(index : Int?) -> Unit {
  let state = state_ref.val
  state.hovered_link_index = index
  state.hovered_spot_index = None
  state.dirty = true
}

///|
/// Opens a page directly for tests.
pub fn open_world_map_page_for_test(name : String) -> Unit {
  let state = state_ref.val
  open_world_name(state, name)
}

///|
/// Exposes compact debug state for blackbox tests.
pub fn get_world_map_debug_state_for_test() -> Json {
  let state = state_ref.val
  {
    "visible": state.visible,
    "search_visible": state.search_visible,
    "current_world_name": state.current_world_name,
    "current_user_root_world_name": state.current_user_root_world_name,
    "hovered_spot_index": state.hovered_spot_index.to_json(),
    "hovered_link_index": state.hovered_link_index.to_json(),
    "has_page": state.current_page is Some(_),
    "page_parent_map": state.current_page.map_or("", fn(page) {
      page.parent_map
    }),
  }
}

///|
/// Sets search panel visibility for tests.
pub fn set_world_map_search_visible_for_test(visible : Bool) -> Unit {
  let state = state_ref.val
  state.search_visible = visible
  state.dirty = true
}

///|
/// Applies escape behavior for blackbox tests.
pub fn handle_world_map_escape_for_test() -> Unit {
  handle_escape(state_ref.val)
}

///|
/// Resets singleton state and injected resources for tests.
pub fn reset_world_map_ui_for_test() -> Unit {
  let state = state_ref.val
  clear_entities(state.render_entities)
  state.visible = false
  state.panel_x = 84
  state.panel_y = 24
  state.current_map_id = 100000000
  state.current_map_name = ""
  state.current_street_name = ""
  state.current_world_name = ""
  state.current_user_root_world_name = ""
  state.search_visible = false
  state.hovered_spot_index = None
  state.hovered_link_index = None
  state.pressed_button = None
  state.ui_resources = None
  state.ui_loading = None
  state.current_page = None
  state.page_loading = None
  state.page_cache.clear()
  state.dirty = false
  ui_json_for_test_ref.val = None
  tooltip_json_for_test_ref.val = None
  map_helper_json_for_test_ref.val = None
  world_map_pages_for_test_ref.val.clear()
}

///|
/// Sprite-based world map ui system.
pub fn world_map_ui_system(_world : @ecs.World) -> Unit {
  register_scene_cleanup_once()
  let state = state_ref.val
  let mut dirty = state.dirty
  if @inputs.is_just_pressed(@inputs.KeyW) {
    toggle_world_map()
    return
  }
  if not(state.visible) {
    if state.render_entities.length() > 0 {
      clear_entities(state.render_entities)
    }
    return
  }
  if poll_ui_resources(state) {
    dirty = true
  }
  guard state.ui_resources is Some(resources) else { return }
  ensure_root_page(state)
  ensure_page_loading(state, resources)
  if poll_page_loading(state) {
    dirty = true
  }
  guard state.current_page is Some(page) else { return }
  if @inputs.is_just_pressed(@inputs.Escape) {
    handle_escape(state)
    return
  }
  let prev_hovered_spot = state.hovered_spot_index
  let prev_hovered_link = state.hovered_link_index
  if tooltip_json_for_test_ref.val is None ||
    world_map_pages_for_test_ref.val.is_empty() {
    resolve_hover(state, resources, page)
  }
  if prev_hovered_spot != state.hovered_spot_index ||
    prev_hovered_link != state.hovered_link_index {
    dirty = true
  }
  if @inputs.is_mouse_just_released(@inputs.MouseButton::Left) {
    if handle_click(state, resources, page) {
      dirty = true
    }
  }
  if dirty {
    render_world_map(state)
    state.dirty = false
  }
}
