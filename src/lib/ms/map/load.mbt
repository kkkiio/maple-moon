///|
pub(all) struct SceneMap {
  id : Int
  tiles_objs : MapTilesObjs
  backgrounds : Backgrounds
  physics : @physics.Physics
  map_info : MapInfo
  portals : MapPortals
  mini_map_resources : MiniMapRuntimeResource?
}

///|
fn get_mapx_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new("mapx")
}

///|
pub async fn load_map(
  map_id : Int,
  map_portals_animations : MapPortalAnimations
) -> SceneMap! {
  // TODO: CashShopPreview
  guard map_id >= 0
  let prefix = (map_id / 100000000).to_string()
  let strid = @string_format.extend_id(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  @log.info({ "path": path }, "loading map")
  let src = get_mapx_loader().load_res_async(path)
  guard not(src.is_null()) else {
    raise @resource.LoadError("map not found, id=\{map_id}")
  }
  let res : MapTilesObjsNxResource = @json.from_json!(src.value())
  let res = res.unwrap()
  let tiles_objs = MapTilesObjs::load(res.layers)
  let backgrounds = load_backgrounds(background_loader, res.back)
  let physics = @physics.Physics::from_resource!(src["foothold"])
  let map_info = MapInfo::from_resource(
    src,
    physics.get_fht().get_walls(),
    physics.get_fht().get_borders(),
  )
  let portals = MapPortals::new(res.portal, map_id, map_portals_animations)
  // Check if miniMap exists
  let mini_map_node = src["miniMap"]
  let mini_map_resources = if mini_map_node.is_null() {
    None
  } else {
    Some(
      MiniMapRuntimeResource::load(
        @json.from_json!(mini_map_node.value()),
        res.portal,
        src.name(),
        src.get_image_loader(),
      ),
    )
  }
  {
    id: map_id,
    tiles_objs,
    backgrounds,
    physics,
    map_info,
    portals,
    mini_map_resources,
  }
}
